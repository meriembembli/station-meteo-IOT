// Copiez ce fichier en « secrets.h » (même dossier) et remplissez-le.
// « secrets.h » ne doit jamais être partagé ni publié.

#pragma once

// --- Wi-Fi (réseau 2,4 GHz : l'ESP32 ne capte pas le 5 GHz) ---
#define WIFI_SSID     "NomDuReseau"
#define WIFI_PASSWORD "MotDePasseWiFi"

// --- Firebase ---
// Console Firebase > Paramètres du projet > Général > « Clé d'API Web ».
#define FIREBASE_API_KEY "AIza..."

// Console Firebase > Realtime Database : l'adresse affichée en haut,
// SANS « / » final. Exemple :
// "https://atmos-xxxx-default-rtdb.europe-west1.firebasedatabase.app"
#define FIREBASE_DB_URL "https://VOTRE-PROJET-default-rtdb.europe-west1.firebasedatabase.app"

// Compte de la station (créé dans Authentication > Utilisateurs).
#define DEVICE_EMAIL    "station01@atmos.local"
#define DEVICE_PASSWORD "UnMotDePasseLong"

// Identifiant de la station dans la base (même valeur que dans l'application).
#define STATION_ID "station01"
