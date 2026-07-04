// Firebase-Projekt-Konfiguration für das Live-Voting-Feature (Mitspieler per Smartphone).
//
// So bekommst du diese Werte:
// 1. https://console.firebase.google.com -> neues Projekt anlegen
// 2. Im Projekt: Realtime Database aktivieren (nicht Firestore)
// 3. Authentication -> Sign-in method -> "Anonym" aktivieren
// 4. Projekteinstellungen -> "Web-App hinzufügen" -> die angezeigten Werte hier eintragen
//
// Diese Werte sind KEIN Geheimnis wie ein API-Key sonst oft ist - Firebase-Web-Configs
// dürfen öffentlich im Client-Code stehen. Der eigentliche Schutz läuft über die
// Security Rules der Realtime Database (siehe database.rules.json).
//
// Solange projectId/databaseURL leer sind, bleibt Live-Voting deaktiviert und die App
// funktioniert wie gewohnt ohne diese Funktion.
window.PUBQUIZ_FIREBASE_CONFIG = {
  apiKey: "AIzaSyAmsGSWgGgv4Gc1-tNhiGRV9dNLFLv6xa4",
  authDomain: "pubquiz-b19d4.firebaseapp.com",
  databaseURL: "https://pubquiz-b19d4-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "pubquiz-b19d4",
  storageBucket: "pubquiz-b19d4.firebasestorage.app",
  messagingSenderId: "248945233312",
  appId: "1:248945233312:web:71e57d5654e201a42a68c5",
  measurementId: "G-06744FQJJB"
};
