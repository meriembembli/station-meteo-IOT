import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/atmos_background.dart';
import '../../shared/widgets/atmos_button.dart';
import '../../shared/widgets/clay_icon.dart';

/// Connexion par e-mail et mot de passe (Firebase Authentication).
/// Les comptes sont créés dans la console Firebase (voir docs/FIREBASE.md).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.checking = false});

  /// Vérification de la session en cours (au démarrage).
  final bool checking;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() =>
          _error = 'Saisissez votre adresse e-mail et votre mot de passe.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _message(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Connexion impossible. Vérifiez votre réseau.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Saisissez d’abord votre adresse e-mail.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _error = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail de réinitialisation envoyé.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _message(e.code));
    }
  }

  String _message(String code) => switch (code) {
        'invalid-email' => 'Adresse e-mail invalide.',
        'user-disabled' => 'Ce compte est désactivé.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Adresse e-mail ou mot de passe incorrect.',
        'too-many-requests' =>
          'Trop de tentatives. Réessayez dans quelques minutes.',
        'network-request-failed' => 'Pas de connexion réseau.',
        _ => 'Connexion impossible ($code).',
      };

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: 1.2),
        );
    InputDecoration field(String label, {Widget? suffix}) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Palette.paperDeep,
          suffixIcon: suffix,
          border: border(Palette.line),
          enabledBorder: border(Palette.line),
          focusedBorder: border(Palette.mint),
        );

    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosBackground(mood: SkyMood.day)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ClayIcon(ClayGlyph.station, size: 72),
                      const SizedBox(height: 18),
                      const Text('ATMOS', style: AtmosText.overline),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: const Text('Connexion à votre station',
                            style: AtmosText.title),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Utilisez le compte créé pour votre projet dans Firebase.',
                        style: AtmosText.body,
                      ),
                      const SizedBox(height: 24),
                      if (widget.checking)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child:
                                CircularProgressIndicator(color: Palette.mint),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Palette.surface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Palette.line),
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: Palette.ink),
                                  decoration: field('Adresse e-mail'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _password,
                                  obscureText: _hidden,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  style: const TextStyle(color: Palette.ink),
                                  decoration: field(
                                    'Mot de passe',
                                    suffix: IconButton(
                                      tooltip: _hidden ? 'Afficher' : 'Masquer',
                                      onPressed: () =>
                                          setState(() => _hidden = !_hidden),
                                      icon: Icon(
                                        _hidden
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Palette.inkMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      style: AtmosText.label
                                          .copyWith(color: Palette.apricotDeep),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                AtmosButton(
                                  label: 'Se connecter',
                                  icon: Icons.login,
                                  busy: _busy,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _busy ? null : _resetPassword,
                                  style: TextButton.styleFrom(
                                      foregroundColor: Palette.inkSoft),
                                  child: const Text('Mot de passe oublié ?'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
