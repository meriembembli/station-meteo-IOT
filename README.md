# ATMOS — Station météorologique intelligente et connectée

Application Flutter du projet. Matériel actuel : ESP32 · DHT11 · LDR · écran LCD
16×2 I2C (BME280, capteur de pluie et humidité du sol prévus plus tard).
Deux modes : démo (données simulées, sans compte) ou station réelle via Firebase.

## Lancer le projet

Prérequis : Flutter 3.22 ou plus récent (`flutter --version`).

Le dépôt contient le code Dart (`lib/`, `test/`, `pubspec.yaml`) mais pas les
dossiers natifs. Générez-les une fois, puis lancez :

```bash
cd atmos
flutter create . --project-name atmos --platforms=android,ios
flutter pub get
flutter run
```

`flutter create .` n'écrase pas les fichiers existants : il ajoute seulement
`android/`, `ios/` et les fichiers de configuration manquants.

Vérifications :

```bash
flutter analyze
flutter test
```

## Ce qui est implémenté

| Destination | Contenu |
|---|---|
| **Station** | Îlot isométrique animé avec boîtier + écran OLED, abri ventilé du BME280, LDR sous dôme, plaque de pluie et végétation. Cinq points interactifs ancrés sur les capteurs, un seul indicateur principal (valeur, unité, description, courbe 24 h), synthèse, sélection horizontale des mesures, accès à l'historique et aux alertes. |
| **Historique** | Choix de la mesure, périodes 24 h / 7 j / 30 j, courbe lissée avec axes et unités, inspection tactile (toucher / glisser), minimum, moyenne et maximum. Pour la pluie : part du temps, épisodes, dernière détection. |
| **Alertes** | Alertes en cours (abricot) et résolues (neutres), acquittement, règles activables, éditeur de seuil (au-dessus / en dessous, curseur), évaluation locale à chaque relevé. |
| **Équipement** | Illustration de la station, état de connexion, synchronisation simulée, renommage local, composants installés, extensions « Humidité du sol » et « Niveau d'eau » non installées, batterie/panneau solaire présentés comme évolutions futures. |

La scène réagit aux données : **pluie** → gouttes, sol mouillé, flaques ;
**lumière faible** → ambiance assombrie et lueur de l'OLED ; **humidité élevée**
→ brume localisée. Glisser horizontalement incline légèrement la scène.

> La scène est une **illustration vectorielle en profondeur** (CustomPainter :
> projection isométrique, couches, dégradés mats, ombres floues, parallaxe),
> pas un véritable modèle 3D. Aucun fichier externe n'est nécessaire.

### Mode démo

La puce « Mode démo » (en haut à droite de la Station) permet de prévisualiser :
conditions normales, pluie détectée, lumière faible, humidité élevée, données
anciennes, station déconnectée (dernières mesures conservées avec horodatage),
historique vide, et de rejouer l'état de chargement.

Valeurs par défaut : 24,6 °C · 62 % · 1013 hPa · lumière relative 74 % · pas de pluie.

### Exactitude des mesures

- Température (°C) et humidité relative (%) : DHT11 ; pression (hPa) : BME280, prévu plus tard.
- Lumière : **valeur relative en %** (LDR), jamais affichée en lux.
- Pluie : **présence détectée ou non**, aucune valeur en mm/h.
- Pas de vent, d'UV, de qualité de l'air ni de prévisions.

### Accessibilité

Réduction des animations respectée (toutes les animations s'arrêtent), zones
tactiles ≥ 44–48 px, libellés sémantiques sur la scène et les graphiques,
texte agrandi pris en charge (mises en page flexibles, `FittedBox` sur les
grands chiffres), zones de sécurité, toutes les valeurs accessibles sans la scène.

## Structure

```
lib/
  main.dart, app.dart              point d'entrée, thème, localisation fr
  core/                            palette, typographie, formats français, animations
  data/
    models/                        mesures, relevé, historique, alertes, matériel
    repositories/
      station_repository.dart      CONTRAT à implémenter pour Firebase
      demo_station_repository.dart implémentation simulée + scénarios
      demo_history_generator.dart  séries cohérentes (cycle jour/nuit)
  state/                           AtmosController (ChangeNotifier) + AtmosScope
  shared/                          composants réutilisables, feuilles de détails
  features/
    shell/                         navigation flottante, 4 destinations
    station/  scene/               scène isométrique, points interactifs
    history/  alerts/  equipment/
test/widget_test.dart
```

Aucune dépendance externe : uniquement le SDK Flutter (`flutter_localizations` inclus).

## Station réelle : Firebase + ESP32

| Étape | Guide |
|---|---|
| 1. Créer le projet Firebase, les comptes et la base | [docs/FIREBASE.md](docs/FIREBASE.md) |
| 2. Câbler et programmer la station ESP32 | [docs/MONTAGE.md](docs/MONTAGE.md) |
| 3. Lancer l’application sur la vraie station | `flutter run --dart-define=ATMOS_BACKEND=firebase` |

- Application : `lib/data/repositories/firebase_station_repository.dart` (relevé en direct, historique, règles, alertes, nom de la station) et connexion par e-mail (`lib/features/auth/`).
- Station : `firmware/atmos_station/atmos_station.ino` (DHT11, LDR, LCD I2C, envoi vers Firebase ; pluie, sol et BME280 en commentaire).
- Règles de sécurité de la base : `firebase/database.rules.json`.
- Sans `--dart-define`, l’application reste en mode démo.
