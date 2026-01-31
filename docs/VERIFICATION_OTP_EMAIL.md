# Why You're Not Receiving the OTP Email

The **Send OTP** API returns **200 OK** and stores the OTP in Firestore, but the email is only sent if an email provider is configured.

## Cause

- **`BREVO_API_KEY` is not set** (e.g. in Vercel Environment Variables).  
  Without it, the API **does not send any email**; it only saves the OTP in Firestore and returns 200. So you never receive the code.

## Fix: Configure Brevo (Send OTP Emails)

1. **Get a Brevo API key**
   - Sign up at [brevo.com](https://www.brevo.com/) (free tier is enough).
   - Go to **SMTP & API** → **API Keys** and create an API key.

2. **Add the key in Vercel**
   - Vercel Dashboard → your project → **Settings** → **Environment Variables**.
   - Add: **Name** `BREVO_API_KEY`, **Value** your Brevo API key.
   - Apply to **Production** (and Preview if you use it).
   - Redeploy the project so the new variable is used.

3. **Sender address**
   - The app sends from `noreply@unidate.app` by default.
   - In Brevo, **Settings** → **Senders & IP** → add and **verify** that sender (or your own domain).
   - If you use a different sender, set **`BREVO_SENDER_EMAIL`** (and optionally **`BREVO_SENDER_NAME`**) in Vercel so the API uses your verified address.

4. **Check spam**
   - After setting `BREVO_API_KEY` and redeploying, try **Send OTP** again.
   - If you still don’t see the email, check **Spam / Junk** and that the address you enter is correct (e.g. `yourid@lpu.in`).

## Testing Without Email (Dev Only)

If you don’t set `BREVO_API_KEY`, the OTP is still saved in Firestore:

- Collection: **`verification_otps`**
- Document ID: **your Firebase UID** (same as your Clerk user ID in this app)
- Fields: `otp`, `email`, `createdAt`, `expiresAt`

You can read the `otp` from that document in the Firebase Console (Firestore) and use it in the app to test verification. Do not rely on this in production; set up Brevo so users receive the email.
