const { verifyToken } = require('@clerk/backend');
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

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();

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

  try {
    ensureFirebase();
    const result = await verifyToken(clerkToken, {
      secretKey,
      authorizedParties: process.env.CLERK_AUTHORIZED_PARTIES
        ? process.env.CLERK_AUTHORIZED_PARTIES.split(',')
        : ['http://localhost:3000', 'http://localhost:8080', 'https://localhost'],
    });
    const payload = result.data ?? result;
    const clerkUserId = payload?.sub;
    if (!clerkUserId) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    const customToken = await admin.auth().createCustomToken(clerkUserId);
    return res.status(200).json({ token: customToken });
  } catch (e) {
    return res.status(401).json({ error: 'Invalid Clerk token' });
  }
};
