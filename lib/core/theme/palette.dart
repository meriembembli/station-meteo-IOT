import 'package:flutter/painting.dart';

/// Palette ATMOS « Ciel » : dégradé de ciel bleu en fond, modules en verre
/// teinté bleu nuit, texte blanc et pastels lumineux pour les mesures
/// (inspiration applis météo iOS / Android, avec l'identité ATMOS).
///
/// Rôle des jetons :
/// - `paper` : bleu nuit de base (texte sur fond clair, superpositions) ;
/// - `surface` / `surfaceHigh` / `paperDeep` : verre teinté translucide ;
/// - `sheet` : surface opaque (feuilles de détails, messages, barre) ;
/// - `ink` / `inkSoft` / `inkMuted` : texte blanc, plus ou moins appuyé ;
/// - `xxx` : teinte de la mesure ; `xxxSoft` : voile teinté ; `xxxDeep` : texte.
abstract final class Palette {
  // Base et verre
  static const paper = Color(0xFF0D2A55);
  static const paperDeep = Color(0x260A2348);
  static const surface = Color(0x330A2348);
  static const surfaceHigh = Color(0x520A2348);
  static const sheet = Color(0xFF15386B);
  static const navBar = Color(0xE6143768);
  static const line = Color(0x33FFFFFF);

  /// Ombres (bleu nuit profond).
  static const shadow = Color(0xFF061833);

  // Texte
  static const ink = Color(0xFFFFFFFF);
  static const inkSoft = Color(0xE0FFFFFF);
  static const inkMuted = Color(0xBDFFFFFF);

  // Accent interactif : blanc (boutons, interrupteurs, onglet actif)
  static const mint = Color(0xFFFFFFFF);
  static const mintSoft = Color(0x2EFFFFFF);
  static const mintDeep = Color(0xFFFFFFFF);

  /// Vert « en ligne ».
  static const online = Color(0xFF8CF5BE);

  // Bleu clair (historique)
  static const glacier = Color(0xFF8FC2FF);
  static const glacierSoft = Color(0x338FC2FF);
  static const glacierDeep = Color(0xFFBFDCFF);

  // Pêche (température, alertes)
  static const apricot = Color(0xFFFFB07A);
  static const apricotSoft = Color(0x38FFB07A);
  static const apricotDeep = Color(0xFFFFD2B3);

  // Aqua (humidité)
  static const sage = Color(0xFF6FE0D6);
  static const sageSoft = Color(0x336FE0D6);
  static const sageDeep = Color(0xFFA9F1EA);

  // Lavande (pression)
  static const lavender = Color(0xFFC3BBFF);
  static const lavenderSoft = Color(0x33C3BBFF);
  static const lavenderDeep = Color(0xFFDDD8FF);

  // Soleil (lumière)
  static const sun = Color(0xFFFFD970);
  static const sunSoft = Color(0x33FFD970);
  static const sunDeep = Color(0xFFFFEAAD);

  // Pluie
  static const rain = Color(0xFF9FD0FF);
  static const rainSoft = Color(0x339FD0FF);
  static const rainDeep = Color(0xFFCBE6FF);
}

extension ColorFade on Color {
  /// Applique une opacité (0–1) sans dépendre des API de couleur récentes.
  Color fade(double opacity) =>
      withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}
