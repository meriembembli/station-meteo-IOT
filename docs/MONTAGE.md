# Montage de la station ATMOS — matériel actuel

Matériel utilisé maintenant : **ESP32 + DHT11 + LDR + écran LCD 16×2 I2C**.
Le capteur de pluie, la sonde d'humidité du sol et le BME280 viendront plus tard
(leur code est déjà prêt, en commentaire — voir la section 7).

## 1. Matériel

| Composant | Qté | Rôle |
|---|---|---|
| ESP32 DevKit V1 (30 ou 38 broches) | 1 | microcontrôleur + Wi-Fi |
| DHT11 (module 3 broches, ou capteur nu 4 broches) | 1 | température + humidité |
| Résistance 10 kΩ (×2 si DHT11 nu) | 1–2 | pont diviseur LDR (+ rappel DHT11 nu) |
| Photorésistance LDR | 1 | lumière relative |
| Écran LCD 16×2 avec module I2C (PCF8574, 4 broches au dos) | 1 | affichage local |
| Breadboard + fils jumper | — | connexions |
| Câble USB **de données** | 1 | alimentation + programmation |

## 2. Câblage

| Module | Broche du module | → ESP32 |
|---|---|---|
| **DHT11** (module 3 broches) | `+` / VCC | **3V3** |
| | `out` / DATA / S | **GPIO12** (D12) |
| | `−` / GND | GND |
| **LCD I2C** (dos de l'écran) | GND | GND |
| | VCC | **3V3** (voir remarque) |
| | SDA | **GPIO21** (D21) |
| | SCL | **GPIO22** (D22) |
| **LDR** | patte 1 | 3V3 |
| | patte 2 | **GPIO34** (D34) **et** résistance 10 kΩ |
| **10 kΩ** | autre patte | GND |

```
            ESP32
   3V3 ─────┬──────────┬───────────┬───────────────┐
            │          │           │               │
         DHT11 +    LCD VCC      LDR               │
   GPIO12 ─ DHT11 out                └──┬── GPIO34 │
   GPIO21 ─ LCD SDA                     │          │
   GPIO22 ─ LCD SCL                   10 kΩ        │
   GND ─────┴── DHT11 −, LCD GND ───────┴── GND ───┘
```

### 2 bis. Deux points de vigilance sur ces broches

- **La LDR est sur GPIO34** (entrée ADC1) et non sur GPIO15 : les entrées ADC2,
  dont GPIO15, ne peuvent pas être lues quand le Wi-Fi est actif.
- **GPIO12 (DHT11) est lue au démarrage** pour choisir la tension de la mémoire flash.
  La résistance de rappel du module DHT11 la met à l'état haut, ce qui peut empêcher
  le démarrage sur certaines cartes. Si l'ESP32 redémarre en boucle : débrancher le fil
  DATA au démarrage, ou **déplacer le DHT11 sur GPIO4** et mettre `PIN_DHT = 4`.

**DHT11 nu (4 broches, sans petite carte)** : broche 1 = VCC, 2 = DATA, 3 = rien, 4 = GND,
et **une résistance 10 kΩ entre DATA et VCC** (les modules 3 broches l'ont déjà).

**Remarque LCD** : la plupart des LCD 16×2 sont prévus pour 5 V.
- Essayez d'abord en **3V3** et tournez le **potentiomètre bleu** au dos jusqu'à voir les caractères.
- Si l'écran reste trop pâle, alimentez-le sur **VIN (5 V)** : ça fonctionne en général,
  mais les lignes SDA/SCL sont alors tirées vers 5 V par le module ; la solution propre
  est un petit convertisseur de niveau 3,3 V ↔ 5 V sur SDA/SCL.
- Ne branchez **jamais** un autre capteur sur 5 V vers une entrée de l'ESP32.

## 3. Étapes de montage

1. ESP32 à cheval sur la rainure centrale de la breadboard.
2. Rails : **3V3 → rail +**, **GND → rail −**.
3. DHT11 : + → rail +, − → rail −, out → GPIO12.
4. LCD : GND → rail −, VCC → rail +, SDA → GPIO21, SCL → GPIO22.
5. LDR : une patte au rail +, l'autre sur une rangée libre ; dans cette rangée :
   la 10 kΩ vers le rail − et un fil vers GPIO34.
6. Vérifier avant de brancher l'USB : pas de court-circuit entre rail + et rail −.

## 4 bis. Version MicroPython (recommandée pour vous)

Fichiers dans `firmware/micropython/` : `main.py`, `lcd_i2c.py`, `config_example.py`.

1. Installer **Thonny** (<https://thonny.org>).
2. Brancher l'ESP32, puis dans Thonny : **Outils → Options → Interpréteur** →
   « MicroPython (ESP32) » → **Installer ou mettre à jour MicroPython** →
   choisir le port COM de l'ESP32 et la variante **Espressif ESP32 / WROOM** → Installer.
3. Ouvrir `config_example.py`, le **Enregistrer sous → Appareil MicroPython** sous le nom
   **`config.py`** (garder `CLOUD_ENABLED = False` pour le premier essai).
4. Enregistrer aussi sur l'appareil : **`lcd_i2c.py`** puis **`main.py`**.
5. Appuyer sur le bouton **EN/RST** de l'ESP32 (ou Ctrl+D dans la console Thonny) :
   `main.py` démarre automatiquement, les mesures s'affichent dans la console et sur le LCD.
6. Pour Firebase : remplir `config.py` (Wi-Fi 2,4 GHz, clé API, URL, compte de la station),
   mettre `CLOUD_ENABLED = True`, enregistrer, redémarrer.

Aucune bibliothèque à installer : `dht`, `network` et `urequests` sont inclus dans MicroPython.
Pour arrêter le programme et reprendre la main dans Thonny : bouton **Stop** (ou Ctrl+C).

## 4. Programmer l'ESP32 (version Arduino C++, alternative)

1. **IDE Arduino 2** → Préférences → URL de cartes :
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. Gestionnaire de cartes : installer **esp32** (Espressif Systems).
3. Gestionnaire de bibliothèques : installer
   - **DHT sensor library** (Adafruit) — accepter **Adafruit Unified Sensor** ;
   - **LiquidCrystal I2C** (Frank de Brabander) ;
   - **ArduinoJson** (7.x).
4. Ouvrir `firmware/atmos_station/atmos_station.ino`.
5. Copier `secrets.example.h` en **`secrets.h`** (même dossier).
6. Carte : **ESP32 Dev Module** ; Port : COMx de l'ESP32
   (pas de port ? installer le pilote **CP210x** ou **CH340**).

### Premier essai sans Internet (recommandé)

Dans le programme, mettre :

```cpp
constexpr bool CLOUD_ENABLED = false;
```

Téléverser, ouvrir le **Moniteur série à 115200 bauds**. On teste ainsi les capteurs
et l'écran seuls (le LCD affiche « local »). `secrets.h` doit exister même s'il n'est pas rempli.

### Ensuite avec Firebase

Remplir `secrets.h` (Wi-Fi **2,4 GHz**, clé API, URL de la base, compte de la station —
voir [FIREBASE.md](FIREBASE.md)), remettre `CLOUD_ENABLED = true`, téléverser.

Si le téléversement bloque sur « Connecting… » : maintenir le bouton **BOOT** de l'ESP32.

## 5. Ce que vous devez voir

Moniteur série :

```
ATMOS — démarrage
LCD : OK (adresse 0x27)
Wi-Fi : connexion à MonReseau... OK
Firebase Auth : connecté
T=24.0°C  H=55%  Lum=71% (brut 2908)
```

Écran LCD :

```
24.0°C   H 55%
Lum  71% en ligne
```

| Problème | Cause probable | Solution |
|---|---|---|
| `LCD : introuvable` | SDA/SCL inversés, pas d'alimentation | vérifier GPIO21 = SDA, GPIO22 = SCL |
| LCD allumé, pas de texte (ou des carrés) | contraste | tourner le potentiomètre au dos |
| `DHT11 : lecture impossible` | fil DATA, pas de résistance de rappel (capteur nu) | GPIO12, 10 kΩ DATA ↔ VCC |
| Température figée / NaN | DHT11 lu trop vite ou mal alimenté | garder 5 s entre lectures, vérifier 3V3 |
| `Lum` ne bouge pas en cachant la LDR | LDR pas sur GPIO34, résistance absente | refaire le pont diviseur |
| L'ESP32 redémarre en boucle / « flash read err » | GPIO12 tirée à l'état haut au démarrage par le DHT11 | déplacer le DHT11 sur GPIO4 (voir 2 bis) |
| `Lum` monte quand on cache la LDR | LDR et résistance inversées | `LDR_INVERTED = true` |
| Wi-Fi « échec » | réseau 5 GHz, mot de passe | réseau 2,4 GHz |
| Erreur 400 (Auth) | e-mail / mot de passe de la station | vérifier le compte dans Firebase |
| Erreur 401 (RTDB) | règles non publiées | publier `firebase/database.rules.json` |
| Erreur 404 | URL de la base incorrecte | copier l'URL de Realtime Database, sans « / » final |

## 6. Dans l'application

```bash
flutter run -d chrome --dart-define=ATMOS_BACKEND=firebase
```

L'application n'affiche que les mesures du matériel actuel : **température, humidité (DHT11)
et lumière (LDR)**. La pression et la pluie sont masquées ; dans Équipement, le BME280,
le capteur de pluie, l'humidité du sol et le niveau d'eau apparaissent comme
« Non installé ».

## 7. Ajouter les capteurs plus tard

Dans le programme, chaque capteur absent est marqué d'une étiquette en commentaire :
**`// [PLUIE]`**, **`// [SOL]`**, **`// [BME280]`**. Pour en activer un : retirer les `//`
de toutes ses lignes, installer la bibliothèque si besoin, téléverser.
Dans l'application : l'ajouter à la liste `activeMetrics` de
`lib/data/models/metric.dart` (pluie, pression).

| Capteur | Câblage prévu | Remarque |
|---|---|---|
| Capteur de pluie (module LM393) | VCC 3V3, GND, AO → **GPIO35** | calibrer plaque sèche / mouillée |
| Humidité du sol (sonde capacitive) | VCC 3V3, GND, AOUT → **GPIO32** | calibrer air / eau |
| BME280 (pression) | VIN 3V3, GND, SDA → GPIO21, SCL → GPIO22 (avec le LCD) | adresse 0x76 ou 0x77 |
| Niveau d'eau (HC-SR04) | 5 V, TRIG → GPIO25, ECHO → GPIO26 **via pont 5 V → 3,3 V** | niveau = hauteur réservoir − distance |

Toujours utiliser des entrées **ADC1 (GPIO32 à 39)** pour les capteurs analogiques :
les entrées ADC2 ne fonctionnent pas quand le Wi-Fi est actif.

## 8. Mise en boîtier (plus tard)

- DHT11 à l'ombre et ventilé, **loin de l'ESP32** (qui chauffe et fausse la température).
- LDR derrière une petite fenêtre transparente, orientée vers le ciel.
- LCD derrière une fenêtre du boîtier ; alimentation USB 5 V par un bloc secteur.
