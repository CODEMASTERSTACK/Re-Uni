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
  const email = body.email;
  if (!email || typeof email !== 'string' || !email.endsWith('@lpu.in')) {
    return res.status(400).json({ error: 'Valid @lpu.in email required' });
  }

  const otp = String(Math.floor(100000 + Math.random() * 900000));
  const db = admin.firestore();
  await db.collection('verification_otps').doc(uid).set({
    email,
    otp,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
  });

  const apiKey = process.env.BREVO_API_KEY;
  if (apiKey) {
    const resp = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: { 'accept': 'application/json', 'content-type': 'application/json', 'api-key': apiKey },
      body: JSON.stringify({
        sender: { name: 'UniDate', email: 'noreply@unidate.app' },
        to: [{ email }],
        subject: 'UniDate – Your verification code',
        htmlContent: `<p>Your code is: <strong>${otp}</strong>. It expires in 10 minutes.</p>`,
      }),
    });
    if (!resp.ok) return res.status(500).json({ error: 'Failed to send email' });
  }

  return res.status(200).json({ ok: true });
};
