# 🍺 Pub Quiz – Spielleiter-Pult

Eine vollständige Pub-Quiz-App für den Spielleiter: Teams verwalten, Runden steuern, Scoreboard, Timer und Fragenverwaltung.

## 📁 Dateistruktur

```
pub-quiz/
├── index.html      ← Haupt-App (umbenannt von Pub_Quiz_dc.html)
├── support.js      ← dc-Runtime (React-basiertes Template-System)
└── README.md       ← Diese Datei
```

---

## 🚀 GitHub Pages – Einrichtung (einmalig)

### 1. Repository erstellen

1. Gehe zu [github.com](https://github.com) → **New repository**
2. Name z. B. `pub-quiz`
3. Sichtbarkeit: **Public** (für kostenloses GitHub Pages) oder **Private** (mit GitHub Pro)
4. **Create repository**

### 2. Dateien hochladen

**Option A – Web-Upload (kein Git nötig):**
1. Im neuen Repo auf **"uploading an existing file"** klicken
2. `index.html` und `support.js` hineinziehen
3. **Commit changes**

**Option B – Git (empfohlen für spätere Updates):**
```bash
git clone https://github.com/DEIN-USERNAME/pub-quiz.git
cd pub-quiz
# index.html und support.js in diesen Ordner kopieren
git add .
git commit -m "Initial upload: Pub Quiz App"
git push
```

### 3. GitHub Pages aktivieren

1. Im Repository → **Settings** → linke Leiste: **Pages**
2. Source: **Deploy from a branch**
3. Branch: `main` / Ordner: `/ (root)`
4. **Save**

⏳ Nach ~1–2 Minuten ist die App erreichbar unter:
```
https://DEIN-USERNAME.github.io/pub-quiz/
```

---

## 🔄 Updates einspielen

Wenn du die App aktualisierst, einfach die geänderten Dateien im Repo ersetzen — GitHub Pages deployed automatisch.

**Per Git:**
```bash
git add index.html
git commit -m "Update: ..."
git push
```

**Per Web-Upload:**
Datei im Repo anklicken → Stift-Icon (Edit) → Datei ersetzen → Commit.

---

## 🛠️ Lokaler Test (optional)

Statt Doppelklick auf die HTML (funktioniert wegen CORS nicht zuverlässig) lieber einen Mini-Server starten:

```powershell
# PowerShell – Python muss installiert sein
cd C:\Pfad\zum\Ordner
python -m http.server 8080
# Dann: http://localhost:8080
```

---

## 🌐 Übersetzung

Fragen werden automatisch über die kostenlose [MyMemory API](https://mymemory.translated.net/) ins Deutsche übersetzt — kein eigener Server nötig, funktioniert sofort. Wer stattdessen einen eigenen LibreTranslate-Server nutzen möchte (z. B. für bessere Qualität oder höhere Limits), kann dessen URL optional im Header eintragen; siehe `LIBRETRANSLATE_SETUP.md`.

## 📝 Hinweise

- Die App läuft vollständig **client-seitig** – kein Backend, kein Server nötig.
- `support.js` ist die generierte dc-Runtime und sollte nicht manuell bearbeitet werden.
- Alle Änderungen an der App erfolgen in `index.html`.
