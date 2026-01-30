# UniDate API (Vercel – free tier)

Replaces Firebase Cloud Functions. Deploy to Vercel (free tier) and set environment variables in the Vercel dashboard.

## Endpoints

- **POST /api/get-custom-token** – Body: `{ "token": "<Clerk session token>" }` → returns `{ "token": "<Firebase custom token>" }`
- **POST /api/send-verification-otp** – Header: `Authorization: Bearer <Firebase ID token>`, Body: `{ "email": "user@lpu.in" }`
- **POST /api/verify-university-email** – Header: `Authorization: Bearer <Firebase ID token>`, Body: `{ "otp": "123456" }`

## Setup

1. Install dependencies from project root: `npm install`

2. **Environment variables** (Vercel Dashboard → Project → Settings → Environment Variables):

   | Variable | Description |
   |----------|-------------|
   | `CLERK_SECRET_KEY` | From Clerk Dashboard → API Keys |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | Full JSON of your Firebase service account key (Project Settings → Service accounts → Generate new private key). Paste as a single-line string. |
   | `BREVO_API_KEY` | (Optional) For sending OTP emails. Without it, OTP is only stored and can be read from logs for testing. |
   | `CLERK_AUTHORIZED_PARTIES` | (Optional) Comma-separated origins, e.g. `https://your-app.web.app,http://localhost:8080` |

3. Deploy: `vercel` (or connect the repo to Vercel for auto-deploy).

4. In the Flutter app, set the backend URL when building:
   - Local: default `http://localhost:3000` (run `vercel dev` in the project root).
   - Production: `flutter build web --dart-define=BACKEND_URL=https://your-project.vercel.app`
