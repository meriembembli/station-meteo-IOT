import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/widgets/atmos_button.dart';
import '../../../shared/widgets/atmos_sheet.dart';

/// Renvoie le nouveau nom, ou `null` si l'utilisateur annule.
Future<String?> showRenameSheet(BuildContext context, String current) =>
    showAtmosSheet<String>(context,
        builder: (_) => RenameSheet(current: current));

class RenameSheet extends StatefulWidget {
  const RenameSheet({super.key, required this.current});

  final String current;

  @override
  State<RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<RenameSheet> {
  static const _maxLength = 32;
  late final TextEditingController _text =
      TextEditingController(text: widget.current);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Le nom ne peut pas être vide.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: 1.4),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text('Renommer la station',
              style: AtmosText.title.copyWith(fontSize: 23)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Le nom est enregistré localement sur ce téléphone.',
          style: AtmosText.body,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _text,
          autofocus: true,
          maxLength: _maxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: Palette.ink),
          decoration: InputDecoration(
            labelText: 'Nom de la station',
            errorText: _error,
            filled: true,
            fillColor: Palette.paperDeep,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: border(Palette.line),
            enabledBorder: border(Palette.line),
            focusedBorder: border(Palette.mintDeep),
            errorBorder: border(Palette.apricotDeep),
            focusedErrorBorder: border(Palette.apricotDeep),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AtmosButton(
                label: 'Annuler',
                style: AtmosButtonStyle.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtmosButton(
                  label: 'Enregistrer', icon: Icons.check, onPressed: _submit),
            ),
          ],
        ),
      ],
    );
  }
}
