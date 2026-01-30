# UniDate API (Vercel – free tier)

Replaces Firebase Cloud Functions. Deploy to Vercel (free tier) and set environment variables in the Vercel dashboard.

## Endpoints

- **POST /api/get-custom-token** – Body: `{ "token": "<Clerk session token>" }` → returns `{ "token": "<Firebase custom token>" }`
- **POST /api/send-verification-otp** – Header: `Authorization: Bearer <Firebase ID token>`, Body: `{ "email": "user@lpu.in" }`
- **POST /api/verify-university-email** – Header: `Authorization: Bearer <Firebase ID token>`, Body: `{ "otp": "123456" }`
- **POST /api/get-upload-url** – Header: `Authorization: Bearer <Firebase ID token>`, Body: `{ "path": "users/<userId>/profile/0.webp" }` → returns `{ "uploadUrl", "publicUrl" }` for R2 upload

## Setup

1. Install dependencies from project root: `npm install`

2. **Environment variables** (Vercel Dashboard → Project → Settings → Environment Variables):

   | Variable | Description |
   |----------|-------------|
   | `CLERK_SECRET_KEY` | From Clerk Dashboard → API Keys |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | Full JSON of your Firebase service account key (Project Settings → Service accounts → Generate new private key). Paste as a single-line string. |
   | `BREVO_API_KEY` | (Optional) For sending OTP emails. Without it, OTP is only stored and can be read from logs for testing. |
   | `CLERK_AUTHORIZED_PARTIES` | (Optional) Comma-separated origins, e.g. `https://your-app.web.app,http://localhost:8080` |
   | **R2 (profile images)** | |
   | `R2_ACCOUNT_ID` | Cloudflare account ID (Dashboard → R2 → right sidebar) |
   | `R2_ACCESS_KEY_ID` | R2 API token Access Key ID (R2 → Manage R2 API Tokens) |
   | `R2_SECRET_ACCESS_KEY` | R2 API token Secret Access Key |
   | `R2_BUCKET_NAME` | Your R2 bucket name |
   | `R2_PUBLIC_URL` | Base URL for public read (e.g. `https://pub-xxx.r2.dev` or custom domain). No trailing slash. |

3. **R2 bucket**: Create a bucket in Cloudflare R2, enable public access (or use a custom domain), and set `R2_PUBLIC_URL` to that base URL so profile images are viewable.

4. Deploy: `vercel` (or connect the repo to Vercel for auto-deploy).

5. In the Flutter app, set the backend URL when building:
   - Local: default `http://localhost:3000` (run `vercel dev` in the project root).
   - Production: `flutter build web --dart-define=BACKEND_URL=https://your-project.vercel.app`
