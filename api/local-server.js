/**
 * Local API server for development. Run: npm run dev (or node api/local-server.js)
 * Loads .env from project root. Flutter web: flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000
 */
const path = require('path');
const fs = require('fs');

// Load .env from project root (parent of api/)
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  require('dotenv').config({ path: envPath });
}

const express = require('express');
const getCustomToken = require('./get-custom-token');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// CORS for all routes (browser will send preflight OPTIONS from Flutter web on another port)
app.use((_req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
});

app.get('/api', (_req, res) => {
  res.json({
    message: 'UniDate API (local)',
    endpoints: [
      'POST /api/get-custom-token',
      'POST /api/send-verification-otp',
      'POST /api/verify-university-email',
      'POST /api/get-upload-url',
    ],
  });
});

app.all('/api/get-custom-token', getCustomToken);

app.listen(PORT, () => {
  console.log(`UniDate API (local) at http://localhost:${PORT}`);
  console.log('Flutter: flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:' + PORT);
});
