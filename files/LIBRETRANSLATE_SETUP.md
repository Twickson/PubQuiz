# LibreTranslate auf Render.com deployen

So bekommt das Pub-Quiz deutsche Fragen — einmalig ~10 Minuten Aufwand, danach kostenlos.

---

## Schritt 1 — Render-Account anlegen

1. Gehe zu [render.com](https://render.com) → **Get Started for Free**
2. Mit GitHub anmelden (empfohlen — erleichtert spätere Updates)
3. **Kein Kreditkarteneintrag nötig** für den Free Tier

---

## Schritt 2 — Neuen Web Service erstellen

1. Im Dashboard: **New → Web Service**
2. Wähle **Deploy an existing image from a registry**
3. Image URL eintragen:
   ```
   libretranslate/libretranslate:latest
   ```
4. Klick auf **Connect**

---

## Schritt 3 — Service konfigurieren

| Feld | Wert |
|---|---|
| **Name** | `pub-quiz-translate` (oder beliebig) |
| **Region** | Frankfurt (EU) — für niedrige Latenz |
| **Instance Type** | **Free** |
| **Start Command** | leer lassen (kommt vom Docker-Image) |

### Umgebungsvariablen hinzufügen

Klick auf **Add Environment Variable** und trage ein:

| Key | Value |
|---|---|
| `LT_LOAD_ONLY` | `en,de` |
| `LT_DISABLE_WEB_UI` | `true` |
| `LT_UPDATE_MODELS` | `true` |

> `LT_LOAD_ONLY=en,de` ist wichtig — nur Englisch→Deutsch laden spart RAM und verhindert Out-of-Memory-Fehler auf dem Free Tier (512 MB).

---

## Schritt 4 — Deployen

1. Klick auf **Create Web Service**
2. Der erste Start dauert **3–5 Minuten** (Sprachmodelle werden heruntergeladen)
3. Warte bis im Log steht:
   ```
   Running on http://0.0.0.0:5000
   ```
4. Deine URL sieht so aus:
   ```
   https://pub-quiz-translate.onrender.com
   ```

---

## Schritt 5 — URL in der Quiz-App eintragen

Im Quiz-Header oben rechts das Feld **Übersetzungsserver** ausfüllen:
```
https://pub-quiz-translate.onrender.com
```
Die URL wird im Browser-LocalStorage gespeichert — einmalig eintragen, bleibt gespeichert.

---

## Schritt 6 — Cold Start verhindern (optional aber empfohlen)

Render schläft nach 15 Minuten Inaktivität ein. Mit UptimeRobot dauerhaft warmhalten:

1. Gehe zu [uptimerobot.com](https://uptimerobot.com) → kostenlos registrieren
2. **Add New Monitor**
3. Einstellungen:
   - Monitor Type: **HTTP(s)**
   - Friendly Name: `LibreTranslate Pub Quiz`
   - URL: `https://pub-quiz-translate.onrender.com/languages`
   - Monitoring Interval: **5 minutes**
4. **Create Monitor**

Fertig — der Service bleibt jetzt dauerhaft aktiv, kein Cold Start mehr.

---

## Testen

Im Browser aufrufen:
```
https://pub-quiz-translate.onrender.com/translate
```
Oder per curl:
```bash
curl -X POST https://pub-quiz-translate.onrender.com/translate \
  -H "Content-Type: application/json" \
  -d '{"q": "What is the capital of Germany?", "source": "en", "target": "de", "format": "text"}'
```
Erwartete Antwort:
```json
{"translatedText": "Was ist die Hauptstadt Deutschlands?"}
```

---

## Ablaufübersicht

```
Quiz-App (GitHub Pages)
    ↓ Englische Fragen laden
opentdb.com (kostenlos, kein Key)
    ↓ Fragen übersetzen
LibreTranslate (Render.com, kostenlos)
    ↓ Deutsche Fragen anzeigen
Spielleiter-Pult
```
