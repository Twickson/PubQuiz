// Live-Voting: gemeinsame Firebase-Anbindung für Spielleiter (index.html) und
// Team-Beitritts-Seite (play.html). Wird als <script type="module"> eingebunden,
// stellt ihre Funktionen aber bewusst auf `window` bereit, damit der
// dc-Runtime-Anwendungscode (kein ES-Modul) sie einfach aufrufen kann.
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-app.js";
import { getAuth, signInAnonymously, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-auth.js";
import { getDatabase, ref, set, update, get, onValue } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-database.js";

const cfg = window.PUBQUIZ_FIREBASE_CONFIG || {};
const isConfigured = !!(cfg.databaseURL && cfg.projectId);
window.fbIsConfigured = () => isConfigured;

let app, auth, db, authReadyPromise;

function init() {
  if (!isConfigured || app) return;
  app = initializeApp(cfg);
  auth = getAuth(app);
  db = getDatabase(app);
}

function ensureAuth() {
  if (!isConfigured) return Promise.reject(new Error('Live-Voting ist nicht konfiguriert (firebase-config.js ausfüllen).'));
  init();
  if (authReadyPromise) return authReadyPromise;
  authReadyPromise = new Promise((resolve, reject) => {
    const unsub = onAuthStateChanged(auth, (user) => {
      if (user) { unsub(); resolve(user); }
    }, reject);
    signInAnonymously(auth).catch(reject);
  });
  return authReadyPromise;
}
window.fbEnsureAuth = ensureAuth;

window.fbGetMyUid = async function () {
  const user = await ensureAuth();
  return user.uid;
};

function makeSessionCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // ohne O/0, I/1 (Verwechslungsgefahr)
  let code = '';
  for (let i = 0; i < 4; i++) code += alphabet[Math.floor(Math.random() * alphabet.length)];
  return code;
}

window.fbCreateSession = async function () {
  const user = await ensureAuth();
  for (let attempt = 0; attempt < 8; attempt++) {
    const code = makeSessionCode();
    const snap = await get(ref(db, `sessions/${code}`));
    if (snap.exists()) continue;
    // update() statt set(): wertet Schreibrechte pro Feld aus (passend zu den
    // Security Rules, die pro Kind-Pfad greifen). Ein set() auf diesem Pfad
    // bräuchte eine .write-Regel direkt auf sessions/$sessionCode selbst.
    await update(ref(db, `sessions/${code}`), {
      hostUid: user.uid,
      status: 'waiting',
      createdAt: Date.now(),
    });
    return code;
  }
  throw new Error('Konnte keinen freien Session-Code finden — bitte erneut versuchen.');
};

window.fbEndSession = async function (code) {
  await ensureAuth();
  await update(ref(db, `sessions/${code}`), { status: 'ended' });
};

window.fbSyncQuestion = async function (code, question) {
  await ensureAuth();
  await update(ref(db, `sessions/${code}`), {
    status: question.revealed ? 'revealed' : 'question_open',
    currentQuestion: question,
  });
};

window.fbListenTeams = function (code, cb) {
  init();
  if (!isConfigured) return () => {};
  return onValue(ref(db, `sessions/${code}/teams`), (snap) => cb(snap.val() || {}));
};

window.fbListenSession = function (code, cb) {
  init();
  if (!isConfigured) return () => {};
  return onValue(ref(db, `sessions/${code}`), (snap) => cb(snap.val()));
};

window.fbJoinSession = async function (code, teamName) {
  const user = await ensureAuth();
  const snap = await get(ref(db, `sessions/${code}`));
  if (!snap.exists() || snap.val().status === 'ended') {
    throw new Error('Session nicht gefunden oder bereits beendet.');
  }

  // Doppelte Teamnamen automatisch durchnummerieren, damit im Pult keine zwei
  // gleich benannten Teams auftauchen. Der eigene, bereits bestehende Eintrag
  // (Reconnect) zählt dabei nicht als Kollision, sonst würde sich ein Team bei
  // jedem erneuten Beitreten selbst immer weiter hochzählen.
  const teams = (snap.val() && snap.val().teams) || {};
  const baseName = (teamName || 'Team').trim() || 'Team';
  const isTaken = (n) => Object.keys(teams).some(uid =>
    uid !== user.uid && teams[uid] && (teams[uid].name || '').trim().toLowerCase() === n.toLowerCase()
  );
  let finalName = baseName;
  let suffix = 2;
  while (isTaken(finalName)) {
    finalName = `${baseName} (${suffix})`;
    suffix++;
  }

  await set(ref(db, `sessions/${code}/teams/${user.uid}`), {
    name: finalName,
    joinedAt: Date.now(),
  });
  return { uid: user.uid, name: finalName };
};

window.fbSubmitVote = async function (code, questionId, optionIndex) {
  const user = await ensureAuth();
  await set(ref(db, `sessions/${code}/teams/${user.uid}/votes/${questionId}`), optionIndex);
};
