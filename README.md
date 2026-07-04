# 🍺 Pub Quiz – Spielleiter-Pult

Eine vollständige Pub-Quiz-App für den Spielleiter: Teams verwalten, Runden steuern, Scoreboard, Timer und Fragenverwaltung.

## 📁 Dateistruktur

```
pub-quiz/
├── index.html                        ← Haupt-App / Spielleiter-Pult (umbenannt von Pub_Quiz_dc.html)
├── play.html                         ← Mitspieler-Seite fürs Smartphone (Live-Voting)
├── support.js                        ← dc-Runtime (React-basiertes Template-System)
├── firebase-config.js                ← Deine Firebase-Projekt-Zugangsdaten (siehe unten)
├── firebase-live.js                  ← Live-Voting-Logik (Session, Auth, Votes) — von index.html & play.html genutzt
├── database.rules.json               ← Security Rules für die Firebase Realtime Database
├── data/questions.json               ← Fragen-Datenbank (EN+DE), wächst mit der Zeit
├── scripts/build-question-db.ps1     ← Lädt neue Fragen & übersetzt sie via Claude
└── README.md                         ← Diese Datei
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
2. Alle Dateien aus der Dateistruktur oben hineinziehen
3. **Commit changes**

**Option B – Git (empfohlen für spätere Updates):**
```bash
git clone https://github.com/DEIN-USERNAME/pub-quiz.git
cd pub-quiz
# Alle Projektdateien in diesen Ordner kopieren
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

## 🌐 Fragen-Datenbank & Übersetzung

Die App lädt Fragen **nicht mehr live** aus dem Internet, sondern aus der lokalen, vorab übersetzten Datenbank `data/questions.json`. Das ergibt deutlich bessere Übersetzungsqualität als eine Live-Maschinenübersetzung und lässt dich genau steuern, wie viele Fragen (= wie viele Tokens) pro Durchlauf übersetzt werden.

### Neue Fragen hinzufügen

Das Skript `scripts/build-question-db.ps1` lädt neue Fragen von [Open Trivia DB](https://opentdb.com) (aus allen Kategorien gemischt), übersetzt sie mit **Claude Haiku 4.5** ins Deutsche und hängt sie an `data/questions.json` an. Bereits vorhandene Fragen werden nie erneut übersetzt — die Datenbank wächst nur.

```powershell
# Einmalig: eigenen Anthropic API-Key setzen (nur für die aktuelle PowerShell-Sitzung)
$env:ANTHROPIC_API_KEY = "sk-ant-..."

# 20 neue Fragen laden und übersetzen (Standard: 20)
.\scripts\build-question-db.ps1 -Amount 20

# Danach committen & pushen, damit die Website die neuen Fragen bekommt:
git add data/questions.json
git commit -m "Neue Fragen hinzugefügt"
git push
```

`-Amount` steuert direkt, wie viele neue Fragen (und damit wie viele Claude-Tokens) pro Lauf verbraucht werden — bei ~30 Wörtern pro Frage kostet ein Durchlauf mit 20 Fragen nur einen Bruchteil eines Cents.

Falls die App bei "Fragen laden" meldet, dass nicht genug Fragen für die gewählte Kategorie/Schwierigkeit vorhanden sind: Skript mit höherem `-Amount` erneut ausführen oder andere Filter wählen.

## 📱 Live-Voting per Smartphone (optional)

Zuschauer können mit ihrem eigenen Handy per Session-Code beitreten und live pro Frage abstimmen — ganz ohne Account. Die Ergebnisse erscheinen in Echtzeit im Spielleiter-Pult. Das Feature ist **optional**: Ohne Einrichtung läuft die App wie gewohnt, nur der "Live-Voting starten"-Button meldet dann, dass es nicht konfiguriert ist.

### Einmaliges Setup

1. Gehe zu [console.firebase.google.com](https://console.firebase.google.com) → **Neues Projekt erstellen** (kostenlos, kein Kreditkarteneintrag nötig)
2. Im Projekt: **Build → Realtime Database** → **Datenbank erstellen** (Standort egal, z. B. Europe)
3. Im Reiter **Regeln** der Realtime Database: Inhalt von `database.rules.json` einfügen und **Veröffentlichen**
4. **Build → Authentication** → **Los geht's** → Anbieter **Anonym** aktivieren
5. Projekteinstellungen (Zahnrad oben links) → ganz unten **"</> Web-App hinzufügen"** → Name vergeben → die angezeigten Config-Werte kopieren
6. Diese Werte in `firebase-config.js` eintragen (die Datei liegt im Repo-Root)
7. Committen & pushen — fertig

**Wichtig:** Die Werte in `firebase-config.js` sind kein Geheimnis wie ein API-Key sonst — Firebase-Web-Configs dürfen öffentlich im Client-Code stehen. Der eigentliche Zugriffsschutz läuft über die Security Rules (`database.rules.json`), nicht über Geheimhaltung dieser Datei.

### Benutzung

- Im Spielleiter-Pult (Spielansicht) auf **"Live-Voting starten"** klicken → ein 4-stelliger Code erscheint
- Mitspieler öffnen `play.html` (z. B. `https://DEIN-USERNAME.github.io/pub-quiz/play.html`) auf ihrem Handy, geben den Code ein und treten bei
- Jede Frage, die der Spielleiter zeigt, erscheint automatisch auf allen Handys; Stimmen werden live im Pult als Balken neben den Antworten angezeigt
- Bricht die Verbindung ab (Handy sperrt, Netz weg), reicht es, `play.html` erneut zu öffnen — der Code wird automatisch vorausgefüllt und das Gerät meldet sich beim selben Session-Eintrag an, ganz ohne erneutes Eintippen des Namens
- **"Beenden"** im Pult schließt die Session; auf den Handys erscheint dann ein Hinweis, dass die Session vorbei ist

### Kosten & Grenzen

Der Firebase-Free-Tier (Spark-Plan) deckt das für ein Pub-Quiz mit ein paar Dutzend Handys pro Abend bequem ab — dauerhaft kostenlos. Alte Sessions werden nicht automatisch gelöscht (die Datenmenge ist aber winzig, das fällt praktisch nicht ins Gewicht).

## 📝 Hinweise

- Die App läuft vollständig **client-seitig** – kein eigener Server nötig (Live-Voting nutzt Firebase als Backend-as-a-Service).
- `support.js` ist die generierte dc-Runtime und sollte nicht manuell bearbeitet werden.
- Alle Änderungen an der App erfolgen in `index.html`.
