# Configurer Firebase pour ATMOS

Durée : environ 20 minutes. Compte Google nécessaire. Le plan gratuit (Spark) suffit.

## 1. Créer le projet

1. Ouvrir <https://console.firebase.google.com> → **Ajouter un projet** → nom : `atmos` (Google Analytics : facultatif).

## 2. Activer la connexion par e-mail

1. **Build → Authentication → Commencer**.
2. Onglet **Sign-in method** → **E-mail/Mot de passe** → Activer → Enregistrer.
3. Onglet **Utilisateurs** → **Ajouter un utilisateur**, deux fois :
   - **le compte de l'application** (votre e-mail + un mot de passe) : pour se connecter sur le téléphone ;
   - **le compte de la station**, par exemple `station01@atmos.local` + un mot de passe long : il sera écrit dans `secrets.h` de l'ESP32.

## 3. Créer la base de données

1. **Build → Realtime Database → Créer une base de données**.
2. Emplacement : **Belgique (europe-west1)** (le plus proche).
3. Démarrer en **mode verrouillé**.
4. Onglet **Règles** : remplacer tout le contenu par celui de [`firebase/database.rules.json`](../firebase/database.rules.json) → **Publier**.
   - Lecture et écriture réservées aux comptes connectés.
   - Index sur `t` (historique) et `startedAt` (alertes), nécessaires aux requêtes de l'application.
5. Copier l'adresse affichée en haut de l'onglet **Données** (ex. `https://atmos-xxxx-default-rtdb.europe-west1.firebasedatabase.app`) → elle va dans `FIREBASE_DB_URL` de `secrets.h`.

## 4. Relier l'application Flutter

Dans un terminal, une seule fois :

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Puis dans le dossier `atmos` :

```bash
flutter create . --project-name atmos --platforms=android,ios,web
flutterfire configure --project=<id-de-votre-projet>
```

`flutterfire configure` remplace `lib/firebase_options.dart` par les vraies clés et ajoute `google-services.json` (Android).

## 5. Lancer l'application sur la vraie station

```bash
flutter run --dart-define=ATMOS_BACKEND=firebase
```

- Sans `--dart-define`, l'application reste en **mode démo** (données simulées).
- Autre identifiant de station : ajouter `--dart-define=ATMOS_STATION_ID=station02`.
- À la première connexion, l'application crée les règles d'alerte par défaut dans la base.

## 6. Clé d'API pour l'ESP32

**Paramètres du projet (roue dentée) → Général → Clé d'API Web** → à copier dans `FIREBASE_API_KEY` de `secrets.h`.

## Structure des données

```
stations/
  station01/
    latest/                 ← écrit par l'ESP32 toutes les 5 s
      t            1763800000000   (horodatage serveur, ms)
      temperature  24.6            (°C, DHT11)
      humidity     62              (%, DHT11)
      pressure     1013.2          (hPa, BME280 — pas encore installé)
      light        74              (% relatif, LDR)
      rain         false           (présence — capteur pas encore installé)
      lightRaw                     (valeur ADC brute de la LDR, pour calibrer)
    history/<id>/           ← un point toutes les 5 min (mêmes champs, sans brut)
    info/                   ← name (modifiable dans l'appli), rssi, firmware, transmitEverySec
    rules/<ruleId>/         ← seuils réglés dans l'appli
    events/<eventId>/       ← alertes déclenchées / résolues
```

État de la liaison calculé par l'application selon l'âge de `latest.t` :
**en ligne** ≤ 2 min · **données anciennes** ≤ 30 min · **hors ligne** au-delà.

## Bon à savoir

- Les alertes sont évaluées par l'application quand elle est ouverte. Pour des notifications téléphone en arrière-plan, il faudra plus tard une Cloud Function + Firebase Cloud Messaging (plan Blaze).
- 30 jours d'historique à 5 min ≈ 8 600 points par station : largement dans le quota gratuit.
- Pour aller plus loin en sécurité : n'autoriser l'écriture de `latest`/`history` qu'au compte de la station (`auth.uid === '<uid de la station>'`).
