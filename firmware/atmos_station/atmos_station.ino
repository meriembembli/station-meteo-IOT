/*
  ATMOS — Station météorologique intelligente et connectée
  Programme ESP32 (Arduino) — matériel actuel

  Capteurs branchés :
    - DHT11            : température °C et humidité relative % (GPIO4)
    - LDR + 10 kΩ      : lumière relative % (pont diviseur, entrée ADC GPIO34)
    - Écran LCD 16×2 I2C (module PCF8574, SDA GPIO21 / SCL GPIO22)

  Pas encore installés (code conservé en commentaire, voir « // [PLUIE] »,
  « // [SOL] » et « // [BME280] ») :
    - capteur de pluie, sonde d'humidité du sol, BME280 (pression).

  Fonctionnement :
    1. lecture des capteurs toutes les 5 s ;
    2. affichage local sur le LCD ;
    3. envoi du dernier relevé vers Firebase (stations/<id>/latest) ;
    4. un point d'historique (stations/<id>/history) toutes les 5 min.

  Bibliothèques (IDE Arduino > Gérer les bibliothèques) :
    - « DHT sensor library » (Adafruit)  + « Adafruit Unified Sensor »
    - « LiquidCrystal I2C » (Frank de Brabander)
    - « ArduinoJson » (version 7)
  Carte : « ESP32 Dev Module » (paquet esp32 by Espressif Systems).

  Avant de téléverser : copier secrets.example.h en secrets.h et le remplir.
  Pour tester SANS Wi-Fi ni Firebase : mettre CLOUD_ENABLED à false.
*/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <DHT.h>
#include <LiquidCrystal_I2C.h>
#include <ArduinoJson.h>
// [BME280] #include <Adafruit_Sensor.h>
// [BME280] #include <Adafruit_BME280.h>

#include "secrets.h"

// ---------------------------------------------------------------------------
// Broches (ESP32 DevKit V1)
// ---------------------------------------------------------------------------
constexpr int PIN_SDA = 21;   // I2C données (LCD)
constexpr int PIN_SCL = 22;   // I2C horloge (LCD)
constexpr int PIN_DHT = 12;   // données du DHT11 (GPIO12 : voir remarque dans docs/MONTAGE.md)
constexpr int PIN_LDR = 34;   // ADC1 : point milieu du pont diviseur LDR
// [PLUIE] constexpr int PIN_RAIN_AO = 35;  // ADC1 : sortie AO du capteur de pluie
// [SOL]   constexpr int PIN_SOIL_AO = 32;  // ADC1 : sortie AOUT de la sonde capacitive
// Les entrées ADC2 ne fonctionnent pas quand le Wi-Fi est actif :
// on reste sur ADC1 (GPIO32 à GPIO39).

// ---------------------------------------------------------------------------
// Réglages
// ---------------------------------------------------------------------------
constexpr bool CLOUD_ENABLED = true;                         // false = test local uniquement
constexpr bool USE_LDR = true;                               // false si la LDR n'est pas câblée
constexpr uint32_t SAMPLE_INTERVAL_MS = 5000;                // lecture + envoi (≥ 2 s pour le DHT11)
constexpr uint32_t HISTORY_INTERVAL_MS = 5UL * 60UL * 1000;  // point d'historique
constexpr const char* FIRMWARE_VERSION = "0.3.0";

// LDR : la valeur MONTE avec la lumière si la LDR est côté 3,3 V.
// Mettre true si vous l'avez câblée dans l'autre sens.
constexpr bool LDR_INVERTED = false;

// [PLUIE] La valeur analogique baisse quand la plaque est mouillée (à calibrer).
// [PLUIE] constexpr int RAIN_WET_BELOW = 2600;
// [PLUIE] constexpr int RAIN_DRY_ABOVE = 2900;

// [SOL] Valeurs brutes sonde dans l'air (sec) et dans l'eau (saturé), à calibrer.
// [SOL] constexpr int SOIL_DRY_RAW = 3200;
// [SOL] constexpr int SOIL_WET_RAW = 1400;

// ---------------------------------------------------------------------------
DHT dht(PIN_DHT, DHT11);
LiquidCrystal_I2C* lcd = nullptr;
// [BME280] Adafruit_BME280 bme;

struct Reading {
  float temperature = NAN;  // °C (DHT11)
  float humidity = NAN;     // % (DHT11)
  float light = NAN;        // % relatif (LDR)
  int lightRaw = 0;
  // [BME280] float pressure = NAN;  // hPa
  // [PLUIE]  bool rain = false;
  // [PLUIE]  int rainRaw = 4095;
  // [SOL]    float soil = NAN;      // % (après calibration)
};

Reading current;
String idToken;
uint32_t tokenValidUntil = 0;
uint32_t lastSample = 0;
uint32_t lastHistory = 0;
bool historyDue = true;   // premier point d'historique dès le démarrage
bool lastSendOk = false;
int dhtFailures = 0;

// ---------------------------------------------------------------------------
// Utilitaires
// ---------------------------------------------------------------------------
int readAnalogAverage(int pin) {
  const int samples = 16;
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delay(2);
  }
  return sum / samples;
}

bool i2cPresent(uint8_t address) {
  Wire.beginTransmission(address);
  return Wire.endTransmission() == 0;
}

void connectWiFi() {
  if (!CLOUD_ENABLED || WiFi.status() == WL_CONNECTED) return;
  Serial.printf("Wi-Fi : connexion à %s", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  const uint32_t start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(300);
    Serial.print('.');
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? " OK" : " échec (nouvel essai plus tard)");
}

// ---------------------------------------------------------------------------
// Firebase : authentification (REST) et écriture dans la base
// ---------------------------------------------------------------------------
bool signIn() {
  WiFiClientSecure client;
  client.setInsecure();  // simplification : pas de vérification du certificat
  HTTPClient http;
  const String url =
      String("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=") +
      FIREBASE_API_KEY;
  if (!http.begin(client, url)) return false;
  http.addHeader("Content-Type", "application/json");

  JsonDocument body;
  body["email"] = DEVICE_EMAIL;
  body["password"] = DEVICE_PASSWORD;
  body["returnSecureToken"] = true;
  String payload;
  serializeJson(body, payload);

  const int code = http.POST(payload);
  if (code != 200) {
    Serial.printf("Firebase Auth : erreur %d\n%s\n", code, http.getString().c_str());
    http.end();
    return false;
  }
  JsonDocument res;
  deserializeJson(res, http.getString());
  http.end();

  idToken = res["idToken"].as<String>();
  const long expiresIn = res["expiresIn"].as<String>().toInt();  // secondes (≈ 3600)
  tokenValidUntil = millis() + (uint32_t)max(60L, expiresIn - 300) * 1000UL;
  Serial.println("Firebase Auth : connecté");
  return idToken.length() > 0;
}

bool ensureToken() {
  if (idToken.length() > 0 && (int32_t)(tokenValidUntil - millis()) > 0) return true;
  return signIn();
}

// method : "PUT" (remplace), "PATCH" (met à jour), "POST" (ajoute une entrée)
bool rtdb(const char* method, const String& path, const String& json) {
  if (!CLOUD_ENABLED || WiFi.status() != WL_CONNECTED || !ensureToken()) return false;
  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  const String url = String(FIREBASE_DB_URL) + path + ".json?auth=" + idToken;
  if (!http.begin(client, url)) return false;
  http.addHeader("Content-Type", "application/json");
  const int code = http.sendRequest(method, json);
  if (code == 401) idToken = "";  // jeton expiré : nouvelle connexion au prochain envoi
  if (code != 200) {
    Serial.printf("RTDB %s %s : erreur %d %s\n", method, path.c_str(), code,
                  http.getString().c_str());
  }
  http.end();
  return code == 200;
}

// JSON d'un relevé ; « t » = horodatage du serveur Firebase.
// Seules les mesures réellement disponibles sont envoyées.
String readingJson(const Reading& r, bool withRaw) {
  JsonDocument doc;
  doc["t"][".sv"] = "timestamp";
  if (!isnan(r.temperature)) doc["temperature"] = roundf(r.temperature * 10) / 10;
  if (!isnan(r.humidity)) doc["humidity"] = roundf(r.humidity);
  if (!isnan(r.light)) doc["light"] = roundf(r.light);
  if (withRaw && USE_LDR) doc["lightRaw"] = r.lightRaw;
  // [BME280] if (!isnan(r.pressure)) doc["pressure"] = roundf(r.pressure * 10) / 10;
  // [PLUIE]  doc["rain"] = r.rain;
  // [PLUIE]  if (withRaw) doc["rainRaw"] = r.rainRaw;
  // [SOL]    if (!isnan(r.soil)) doc["soil"] = roundf(r.soil);
  String out;
  serializeJson(doc, out);
  return out;
}

// ---------------------------------------------------------------------------
// Capteurs
// ---------------------------------------------------------------------------
void readSensors() {
  // DHT11 : lecture lente, échecs ponctuels possibles → on garde la dernière
  // valeur valide pendant 3 échecs consécutifs.
  const float t = dht.readTemperature();
  const float h = dht.readHumidity();
  if (isnan(t) || isnan(h)) {
    dhtFailures++;
    Serial.println("DHT11 : lecture impossible (câblage, broche DATA, résistance de rappel ?)");
    if (dhtFailures >= 3) {
      current.temperature = NAN;
      current.humidity = NAN;
    }
  } else {
    dhtFailures = 0;
    current.temperature = t;
    current.humidity = h;
  }

  if (USE_LDR) {
    current.lightRaw = readAnalogAverage(PIN_LDR);
    float pct = current.lightRaw * 100.0F / 4095.0F;
    if (LDR_INVERTED) pct = 100.0F - pct;
    current.light = constrain(pct, 0.0F, 100.0F);
  }

  // [BME280] current.pressure = bme.readPressure() / 100.0F;

  // [PLUIE] current.rainRaw = readAnalogAverage(PIN_RAIN_AO);
  // [PLUIE] if (!current.rain && current.rainRaw < RAIN_WET_BELOW) current.rain = true;
  // [PLUIE] if (current.rain && current.rainRaw > RAIN_DRY_ABOVE) current.rain = false;

  // [SOL] const int soilRaw = readAnalogAverage(PIN_SOIL_AO);
  // [SOL] current.soil = constrain(map(soilRaw, SOIL_DRY_RAW, SOIL_WET_RAW, 0, 100), 0, 100);

  Serial.printf("T=%.1f°C  H=%.0f%%  Lum=%.0f%% (brut %d)\n", current.temperature,
                current.humidity, current.light, current.lightRaw);
}

// ---------------------------------------------------------------------------
// Affichage LCD 16×2 (suivi local)
//   ligne 1 : 24.6°C   H 62%
//   ligne 2 : Lum 74%  en ligne
// ---------------------------------------------------------------------------
void drawLcd() {
  if (lcd == nullptr) return;
  char line[17];

  if (isnan(current.temperature)) {
    snprintf(line, sizeof(line), "--.-%cC   H --%%  ", (char)223);
  } else {
    snprintf(line, sizeof(line), "%4.1f%cC   H %2.0f%% ", current.temperature, (char)223,
             current.humidity);
  }
  lcd->setCursor(0, 0);
  lcd->print(line);

  const char* status;
  if (!CLOUD_ENABLED) {
    status = "local";
  } else if (WiFi.status() != WL_CONNECTED) {
    status = "WiFi --";
  } else {
    status = lastSendOk ? "en ligne" : "WiFi ok";
  }
  if (USE_LDR && !isnan(current.light)) {
    snprintf(line, sizeof(line), "Lum %3.0f%% %-7s", current.light, status);
  } else {
    snprintf(line, sizeof(line), "%-16s", status);
  }
  lcd->setCursor(0, 1);
  lcd->print(line);
}

// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println("\nATMOS — démarrage");

  analogReadResolution(12);
  if (USE_LDR) analogSetPinAttenuation(PIN_LDR, ADC_11db);  // plage 0–3,3 V
  // [PLUIE] analogSetPinAttenuation(PIN_RAIN_AO, ADC_11db);
  // [SOL]   analogSetPinAttenuation(PIN_SOIL_AO, ADC_11db);

  dht.begin();

  // LCD : adresse détectée automatiquement (0x27 ou 0x3F selon le module).
  Wire.begin(PIN_SDA, PIN_SCL);
  uint8_t lcdAddress = 0;
  if (i2cPresent(0x27)) lcdAddress = 0x27;
  else if (i2cPresent(0x3F)) lcdAddress = 0x3F;
  if (lcdAddress != 0) {
    lcd = new LiquidCrystal_I2C(lcdAddress, 16, 2);
    lcd->init();
    lcd->backlight();
    lcd->setCursor(0, 0);
    lcd->print("ATMOS");
    lcd->setCursor(0, 1);
    lcd->print("Demarrage...");
    Serial.printf("LCD : OK (adresse 0x%02X)\n", lcdAddress);
  } else {
    Serial.println("LCD : introuvable (vérifier SDA/SCL, alimentation)");
  }

  // [BME280] if (!bme.begin(0x76, &Wire) && !bme.begin(0x77, &Wire)) Serial.println("BME280 absent");

  connectWiFi();
  if (CLOUD_ENABLED && WiFi.status() == WL_CONNECTED) {
    signIn();
    JsonDocument info;
    info["transmitEverySec"] = SAMPLE_INTERVAL_MS / 1000;
    info["firmware"] = FIRMWARE_VERSION;
    info["rssi"] = WiFi.RSSI();
    info["sensors"] = "DHT11, LDR";
    String json;
    serializeJson(info, json);
    rtdb("PATCH", String("/stations/") + STATION_ID + "/info", json);
  }

  delay(1500);  // le DHT11 a besoin d'un court délai après la mise sous tension
  if (lcd != nullptr) lcd->clear();
}

void loop() {
  const uint32_t now = millis();
  if (lastSample != 0 && now - lastSample < SAMPLE_INTERVAL_MS) return;
  lastSample = now;

  connectWiFi();
  readSensors();

  if (CLOUD_ENABLED) {
    const String base = String("/stations/") + STATION_ID;
    lastSendOk = rtdb("PUT", base + "/latest", readingJson(current, true));

    if (historyDue || now - lastHistory >= HISTORY_INTERVAL_MS) {
      if (rtdb("POST", base + "/history", readingJson(current, false))) {
        lastHistory = now;
        historyDue = false;
      }
      rtdb("PATCH", base + "/info", String("{\"rssi\":") + WiFi.RSSI() + "}");
    }
  }

  drawLcd();
}
