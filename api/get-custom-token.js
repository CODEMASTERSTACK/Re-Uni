const { verifyToken } = require('@clerk/backend');
const admin = require('firebase-admin');

function ensureFirebase() {
  if (admin.apps.length > 0) return;
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json || String(json).trim() === '') {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set');
  }
  let parsed;
  try {
    parsed = JSON.parse(json);
  } catch (e) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is invalid JSON: ' + (e && e.message));
  }
  if (!parsed || parsed.type !== 'service_account') {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON must be a service_account JSON object');
  }
  admin.initializeApp({ credential: admin.credential.cert(parsed) });
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    const clerkToken = body.token;
    if (!clerkToken || typeof clerkToken !== 'string') {
      return res.status(400).json({ error: 'Missing token' });
    }

    const secretKey = process.env.CLERK_SECRET_KEY;
    if (!secretKey) {
      return res.status(500).json({ error: 'CLERK_SECRET_KEY not configured' });
    }

    ensureFirebase();
    // Clerk JWT azp (authorized party) must include your app origin. Flutter web uses random ports (e.g. 58633).
    const defaultParties = [
      'http://localhost:3000', 'http://localhost:8080', 'http://localhost:5173',
      'http://localhost:51806', 'http://localhost:55926', 'http://localhost:57188',
      'http://localhost:52297', 'http://localhost:58633', 'https://localhost',
      'https://working-turtle-74.accounts.dev', 'https://working-turtle-74.clerk.accounts.dev',
      'https://re-uni.vercel.app',
    ];
    const authorizedParties = process.env.CLERK_AUTHORIZED_PARTIES
      ? process.env.CLERK_AUTHORIZED_PARTIES.split(',').map((s) => s.trim()).filter(Boolean)
      : defaultParties;
    const result = await verifyToken(clerkToken, {
      secretKey,
      authorizedParties,
    });
    const payload = result.data ?? result;
    const clerkUserId = payload?.sub;
    if (!clerkUserId) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    const customToken = await admin.auth().createCustomToken(clerkUserId);
    return res.status(200).json({ token: customToken });
  } catch (e) {
    const msg = e && e.message ? String(e.message) : '';
    if (msg.includes('FIREBASE_SERVICE_ACCOUNT_JSON') || msg.includes('invalid JSON')) {
      return res.status(500).json({ error: 'Backend config error', detail: msg });
    }
    return res.status(401).json({ error: 'Invalid Clerk token', detail: msg });
  }
};
