# UniDate Cloud Functions

- **getCustomToken**: Exchanges Clerk session token for Firebase custom token. Requires `CLERK_SECRET_KEY`.
- **sendVerificationOtp**: Sends OTP to @lpu.in email via Brevo. Requires `BREVO_API_KEY`.
- **verifyUniversityEmail**: Verifies OTP and sets `isStudentVerified` on the user profile.

## Setup

1. Install dependencies: `npm install`

2. **Set environment variables** (required for production):
   - **Firebase Console**: Project → Functions → Environment variables. Add:
     - `CLERK_SECRET_KEY` (from Clerk Dashboard → API Keys)
     - `BREVO_API_KEY` (from Brevo for OTP emails)
   - Or for local emulator: copy `.env.example` to `.env` and add the same keys.

3. Deploy: `firebase deploy --only functions`
