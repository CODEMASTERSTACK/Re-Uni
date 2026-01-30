const admin = require('firebase-admin');

function ensureFirebase() {
  if (admin.apps.length > 0) return;
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (json) {
    admin.initializeApp({ credential: admin.credential.cert(JSON.parse(json)) });
  } else {
    admin.initializeApp();
  }
}

async function verifyFirebaseToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const idToken = authHeader.slice(7);
  ensureFirebase();
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded.uid;
  } catch (_) {
    return null;
  }
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(204).end();

  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const uid = await verifyFirebaseToken(req.headers.authorization);
  if (!uid) return res.status(401).json({ error: 'Unauthorized' });

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
  const otp = body.otp;
  if (!otp || typeof otp !== 'string') {
    return res.status(400).json({ error: 'Missing OTP' });
  }

  const db = admin.firestore();
  const ref = db.collection('verification_otps').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return res.status(404).json({ error: 'No OTP sent' });

  const d = snap.data();
  if (d.otp !== otp) return res.status(400).json({ error: 'Invalid OTP' });

  const expiresAt = d.expiresAt?.toDate?.() || new Date(0);
  if (new Date() > expiresAt) {
    await ref.delete();
    return res.status(400).json({ error: 'OTP expired' });
  }

  await ref.delete();
  await db.collection('users').doc(uid).update({
    isStudentVerified: true,
    universityEmail: d.email,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.status(200).json({ ok: true });
};
