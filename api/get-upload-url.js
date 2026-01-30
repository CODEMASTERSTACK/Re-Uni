const admin = require('firebase-admin');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

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

  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
  const bucket = process.env.R2_BUCKET_NAME;
  const publicBaseUrl = process.env.R2_PUBLIC_URL;

  if (!accountId || !accessKeyId || !secretAccessKey || !bucket || !publicBaseUrl) {
    return res.status(503).json({
      error: 'R2 not configured',
      hint: 'Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_PUBLIC_URL in Vercel',
    });
  }

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
  let path = (body.path || '').trim();
  if (!path) return res.status(400).json({ error: 'Missing path' });

  // Path must be users/{uid}/... (no leading slash)
  path = path.replace(/^\/+/, '');
  const prefix = `users/${uid}/`;
  if (!path.startsWith(prefix)) {
    return res.status(403).json({ error: 'Path must start with users/<your-id>/' });
  }

  // Optional: limit to profile images only and index 0-4
  const profileMatch = path.match(/^users\/[^/]+\/profile\/(\d+)\.webp$/);
  if (profileMatch) {
    const index = parseInt(profileMatch[1], 10);
    if (index < 0 || index > 4) return res.status(400).json({ error: 'Profile index must be 0-4' });
  }

  try {
    const endpoint = `https://${accountId}.r2.cloudflarestorage.com`;
    const s3 = new S3Client({
      region: 'auto',
      endpoint,
      credentials: { accessKeyId, secretAccessKey },
      forcePathStyle: true,
    });

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: path,
      ContentType: 'image/webp',
    });
    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

    const publicUrl = publicBaseUrl.endsWith('/') ? publicBaseUrl + path : publicBaseUrl + '/' + path;
    return res.status(200).json({ uploadUrl, publicUrl });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to generate upload URL', detail: e.message });
  }
};
