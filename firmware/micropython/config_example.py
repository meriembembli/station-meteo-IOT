# Copiez ce fichier en « config.py » sur l'ESP32 et remplissez-le.
# config.py contient des mots de passe : ne le partagez pas (il est ignoré par git).

# False = test local uniquement (capteurs + écran, sans Wi-Fi ni Firebase).
CLOUD_ENABLED = False

# Wi-Fi 2,4 GHz (l'ESP32 ne capte pas le 5 GHz)
WIFI_SSID = "NomDuReseau"
WIFI_PASSWORD = "MotDePasseWiFi"

# Firebase : apiKey du bloc « web » de lib/firebase_options.dart
FIREBASE_API_KEY = "AIza..."

# Realtime Database : adresse affichée en haut de l'onglet Données, sans « / » final
FIREBASE_DB_URL = "https://stationmeteo-846a7-default-rtdb.europe-west1.firebasedatabase.app"

# Compte de la station (Authentication > Utilisateurs)
DEVICE_EMAIL = "station01@atmos.local"
DEVICE_PASSWORD = "MotDePasseDeLaStation"

# Identifiant de la station (le même que dans l'application)
STATION_ID = "station01"
