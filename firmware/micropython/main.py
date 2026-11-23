# ATMOS — Station météorologique intelligente et connectée
# Programme MicroPython pour ESP32 — matériel actuel :
#   - DHT11 (température °C + humidité %)  → GPIO12
#   - LDR + résistance 10 kΩ (lumière %)   → GPIO34
#   - Écran LCD 16×2 I2C (PCF8574)         → SDA GPIO21, SCL GPIO22
#
# Capteurs pas encore installés : code conservé en commentaire,
# repérable par « # [PLUIE] », « # [SOL] » et « # [BME280] ».
#
# Fichiers à copier sur l'ESP32 : main.py, lcd_i2c.py, config.py
# (config.py = copie remplie de config_example.py).

import gc
import json
import time

import dht
import network
from machine import ADC, I2C, Pin

try:
    import urequests as requests
except ImportError:
    import requests

import config
from lcd_i2c import LcdI2C

# ---------------------------------------------------------------------------
# Broches
# ---------------------------------------------------------------------------
PIN_DHT = 12   # DHT11 DATA
PIN_LDR = 34   # point milieu du pont diviseur LDR / 10 kΩ (ADC1, compatible Wi-Fi)
PIN_SDA = 21   # LCD I2C SDA
PIN_SCL = 22   # LCD I2C SCL
# [PLUIE]  PIN_RAIN = 35   # sortie AO du capteur de pluie (entrée ADC1)
# [SOL]    PIN_SOIL = 32   # sortie AOUT de la sonde d'humidité du sol (ADC1)

# ATTENTION :
#  - Les entrées analogiques ADC2 (dont GPIO15) ne fonctionnent pas quand le
#    Wi-Fi est actif : la LDR est donc sur GPIO34 (ADC1). Autres choix
#    possibles : 35, 32, 33, 36, 39.
#  - GPIO12 est lue au démarrage : si l'ESP32 ne démarre plus (boucle de
#    redémarrage), débranchez le fil DATA du DHT11 au démarrage, ou déplacez
#    le DHT11 sur GPIO4 (PIN_DHT = 4).

# ---------------------------------------------------------------------------
# Réglages
# ---------------------------------------------------------------------------
CLOUD_ENABLED = getattr(config, "CLOUD_ENABLED", True)  # False = test local
USE_LDR = True
LDR_INVERTED = False            # True si la valeur monte quand on cache la LDR
SAMPLE_MS = 5000                # lecture + envoi (≥ 2 s pour le DHT11)
HISTORY_MS = 5 * 60 * 1000      # un point d'historique toutes les 5 min
FIRMWARE = "py-0.1.0"

# [PLUIE] RAIN_WET_BELOW = 2600  # valeur brute (0–4095) : en dessous = pluie
# [PLUIE] RAIN_DRY_ABOVE = 2900  # au-dessus = sec (hystérésis)
# [SOL]   SOIL_DRY_RAW = 3200    # sonde dans l'air
# [SOL]   SOIL_WET_RAW = 1400    # sonde dans l'eau

# ---------------------------------------------------------------------------
# Matériel
# ---------------------------------------------------------------------------
dht_sensor = dht.DHT11(Pin(PIN_DHT))

ldr = None
if USE_LDR:
    try:
        ldr = ADC(Pin(PIN_LDR))
        ldr.atten(ADC.ATTN_11DB)  # plage 0–3,3 V
    except Exception as e:
        print("LDR : broche ADC indisponible :", e)
        ldr = None

# [PLUIE] rain_adc = ADC(Pin(PIN_RAIN)); rain_adc.atten(ADC.ATTN_11DB)
# [SOL]   soil_adc = ADC(Pin(PIN_SOIL)); soil_adc.atten(ADC.ATTN_11DB)

i2c = I2C(0, sda=Pin(PIN_SDA), scl=Pin(PIN_SCL), freq=100000)
lcd = None
found = i2c.scan()
for address in (0x27, 0x3F):
    if address in found:
        lcd = LcdI2C(i2c, address, 16, 2)
        lcd.write_line(0, "ATMOS")
        lcd.write_line(1, "Demarrage...")
        print("LCD : OK (adresse 0x%02X)" % address)
        break
if lcd is None:
    print("LCD : introuvable. Adresses I2C vues :", [hex(a) for a in found])

wlan = network.WLAN(network.STA_IF)

# ---------------------------------------------------------------------------
# État
# ---------------------------------------------------------------------------
state = {
    "temperature": None,
    "humidity": None,
    "light": None,
    "light_raw": None,
    # [PLUIE] "rain": False, "rain_raw": None,
    # [SOL]   "soil": None,
}
dht_failures = 0
id_token = None
token_valid_until = 0
last_send_ok = False


# ---------------------------------------------------------------------------
# Wi-Fi
# ---------------------------------------------------------------------------
def connect_wifi():
    if not CLOUD_ENABLED or wlan.isconnected():
        return
    print("Wi-Fi : connexion à", config.WIFI_SSID, end="")
    wlan.active(True)
    try:
        wlan.connect(config.WIFI_SSID, config.WIFI_PASSWORD)
    except OSError:
        pass
    start = time.ticks_ms()
    while not wlan.isconnected() and time.ticks_diff(time.ticks_ms(), start) < 15000:
        time.sleep_ms(300)
        print(".", end="")
    print(" OK" if wlan.isconnected() else " échec (nouvel essai plus tard)")


# ---------------------------------------------------------------------------
# Firebase (API REST)
# ---------------------------------------------------------------------------
def sign_in():
    global id_token, token_valid_until
    url = ("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="
           + config.FIREBASE_API_KEY)
    body = {"email": config.DEVICE_EMAIL, "password": config.DEVICE_PASSWORD,
            "returnSecureToken": True}
    try:
        r = requests.post(url, data=json.dumps(body),
                          headers={"Content-Type": "application/json"})
        code = r.status_code
        data = r.json() if code == 200 else r.text
        r.close()
    except Exception as e:
        print("Firebase Auth : erreur réseau", e)
        return False
    finally:
        gc.collect()
    if code != 200:
        print("Firebase Auth : erreur", code, data)
        return False
    id_token = data["idToken"]
    expires = int(data.get("expiresIn", "3600"))
    token_valid_until = time.ticks_add(time.ticks_ms(), max(60, expires - 300) * 1000)
    print("Firebase Auth : connecté")
    return True


def ensure_token():
    if id_token and time.ticks_diff(token_valid_until, time.ticks_ms()) > 0:
        return True
    return sign_in()


def rtdb(method, path, payload):
    """method : 'PUT' (remplace), 'PATCH' (met à jour), 'POST' (ajoute)."""
    global id_token
    if not CLOUD_ENABLED or not wlan.isconnected() or not ensure_token():
        return False
    url = config.FIREBASE_DB_URL + path + ".json?auth=" + id_token
    try:
        r = requests.request(method, url, data=json.dumps(payload),
                             headers={"Content-Type": "application/json"})
        code = r.status_code
        if code != 200:
            print("RTDB", method, path, ": erreur", code, r.text)
        r.close()
    except Exception as e:
        print("RTDB", method, path, ": erreur réseau", e)
        code = -1
    finally:
        gc.collect()
    if code == 401:
        id_token = None  # jeton expiré : nouvelle connexion au prochain envoi
    return code == 200


def reading_payload(with_raw):
    """Seules les mesures disponibles sont envoyées ; « t » = heure serveur."""
    doc = {"t": {".sv": "timestamp"}}
    if state["temperature"] is not None:
        doc["temperature"] = round(state["temperature"], 1)
    if state["humidity"] is not None:
        doc["humidity"] = round(state["humidity"])
    if state["light"] is not None:
        doc["light"] = round(state["light"])
        if with_raw:
            doc["lightRaw"] = state["light_raw"]
    # [PLUIE] doc["rain"] = state["rain"]
    # [PLUIE] if with_raw: doc["rainRaw"] = state["rain_raw"]
    # [SOL]   if state["soil"] is not None: doc["soil"] = round(state["soil"])
    return doc


# ---------------------------------------------------------------------------
# Capteurs
# ---------------------------------------------------------------------------
def read_adc_average(adc, samples=16):
    total = 0
    for _ in range(samples):
        total += adc.read_u16() >> 4  # 0–4095
        time.sleep_ms(2)
    return total // samples


def read_sensors():
    global dht_failures
    # DHT11 : échecs ponctuels possibles → dernière valeur gardée 3 fois.
    try:
        dht_sensor.measure()
        state["temperature"] = float(dht_sensor.temperature())
        state["humidity"] = float(dht_sensor.humidity())
        dht_failures = 0
    except OSError:
        dht_failures += 1
        print("DHT11 : lecture impossible (fil DATA, résistance de rappel ?)")
        if dht_failures >= 3:
            state["temperature"] = None
            state["humidity"] = None

    if ldr is not None:
        try:
            raw = read_adc_average(ldr)
            pct = raw * 100 / 4095
            if LDR_INVERTED:
                pct = 100 - pct
            state["light_raw"] = raw
            state["light"] = max(0, min(100, pct))
        except Exception:
            # Cas typique : LDR sur une entrée ADC2 pendant que le Wi-Fi est actif.
            state["light"] = None
            state["light_raw"] = None

    # [PLUIE] raw = read_adc_average(rain_adc)
    # [PLUIE] state["rain_raw"] = raw
    # [PLUIE] if not state["rain"] and raw < RAIN_WET_BELOW: state["rain"] = True
    # [PLUIE] if state["rain"] and raw > RAIN_DRY_ABOVE: state["rain"] = False

    # [SOL] raw = read_adc_average(soil_adc)
    # [SOL] pct = (SOIL_DRY_RAW - raw) * 100 / (SOIL_DRY_RAW - SOIL_WET_RAW)
    # [SOL] state["soil"] = max(0, min(100, pct))

    def fmt(v, pattern):
        return "--" if v is None else pattern % v

    print("T=%s°C  H=%s%%  Lum=%s%% (brut %s)" % (
        fmt(state["temperature"], "%.1f"), fmt(state["humidity"], "%.0f"),
        fmt(state["light"], "%.0f"), state["light_raw"]))


# ---------------------------------------------------------------------------
# Affichage LCD 16×2
#   ligne 1 : 24.0°C   H 55%
#   ligne 2 : Lum  71% en ligne
# ---------------------------------------------------------------------------
def draw_lcd():
    if lcd is None:
        return
    t, h = state["temperature"], state["humidity"]
    if t is None:
        line1 = "--.-°C   H --%"
    else:
        line1 = "%4.1f°C   H %2.0f%%" % (t, h)

    if not CLOUD_ENABLED:
        status = "local"
    elif not wlan.isconnected():
        status = "WiFi --"
    else:
        status = "en ligne" if last_send_ok else "WiFi ok"

    if state["light"] is not None:
        line2 = "Lum %3.0f%% %s" % (state["light"], status)
    else:
        line2 = status

    lcd.write_line(0, line1)
    lcd.write_line(1, line2)


# ---------------------------------------------------------------------------
# Programme principal
# ---------------------------------------------------------------------------
def main():
    global last_send_ok
    print("\nATMOS — démarrage (MicroPython)")
    connect_wifi()
    base = "/stations/" + config.STATION_ID
    if CLOUD_ENABLED and wlan.isconnected() and sign_in():
        rtdb("PATCH", base + "/info", {
            "transmitEverySec": SAMPLE_MS // 1000,
            "firmware": FIRMWARE,
            "rssi": wlan.status("rssi"),
            "sensors": "DHT11, LDR",
        })

    time.sleep_ms(1500)  # délai de mise en route du DHT11
    if lcd is not None:
        lcd.clear()

    last_history = None
    while True:
        started = time.ticks_ms()
        connect_wifi()
        read_sensors()

        if CLOUD_ENABLED:
            last_send_ok = rtdb("PUT", base + "/latest", reading_payload(True))
            if last_history is None or time.ticks_diff(started, last_history) >= HISTORY_MS:
                if rtdb("POST", base + "/history", reading_payload(False)):
                    last_history = started
                try:
                    rtdb("PATCH", base + "/info", {"rssi": wlan.status("rssi")})
                except Exception:
                    pass

        draw_lcd()

        elapsed = time.ticks_diff(time.ticks_ms(), started)
        time.sleep_ms(max(100, SAMPLE_MS - elapsed))


main()
