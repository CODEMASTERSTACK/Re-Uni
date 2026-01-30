# Clerk web redirect – post-login landing on app

## Flow

1. User clicks **Log in** (or **Create account**) on the Flutter web app.
2. App redirects to Clerk’s hosted sign-in/sign-up URL with `redirect_url` set to your app origin (e.g. `http://localhost:51806`).
3. User signs in on Clerk; Clerk redirects back to `redirect_url` with a token in the query string, e.g. `http://localhost:51806/?__clerk_db_jwt=...` (Clerk may use **two** underscores: `__clerk_db_jwt`).
4. The app reads the token **in `main()`** from `window.location` (via the web redirect helper) and passes it to `UniDateWebApp(initialClerkToken: token)`.
5. The app exchanges that token with your backend (`/api/get-custom-token`), gets a Firebase custom token, signs in to Firebase, then shows profile setup or the app shell.

## If you still land on the landing page

- **Token not read:** The token is read in `main()` as soon as the script runs. If you still see the landing page (and no red error screen), the URL might not contain `_clerk_db_jwt` when the app loads, or the redirect might be happening in a different window/iframe. Check the address bar after Clerk redirects: it should look like `http://localhost:PORT/?_clerk_db_jwt=...`.
- **Backend returns 401:** If the backend rejects the token, you’ll see a **red error screen** with something like “Invalid Clerk token”. Then:
  - Set **`CLERK_AUTHORIZED_PARTIES`** in your backend (Vercel env or `.env`) to include your Flutter web origin, e.g.  
    `http://localhost:51806,http://localhost:3000`  
    (use the exact origin and port your app runs on).
  - Redeploy the backend and try again.

## Backend env (Vercel / local)

For `/api/get-custom-token` to accept the Clerk JWT after redirect:

- **`CLERK_SECRET_KEY`** – from Clerk Dashboard.
- **`FIREBASE_SERVICE_ACCOUNT_JSON`** – Firebase service account JSON string.
- **`CLERK_AUTHORIZED_PARTIES`** (optional) – Comma-separated list of allowed origins, e.g.  
  `http://localhost:51806,http://localhost:3000,https://your-app.vercel.app`  
  Include every origin where your Flutter web app runs (including the port for localhost).

---

## OTP / email verification only on sign-up (not on login)

If Clerk asks for an **OTP (email verification code)** when you **log in** (not just when you create an account), that’s controlled in the **Clerk Dashboard**, not in this app.

**What to do:**

1. Open the **Clerk Dashboard** → your application.
2. Go to **User & authentication** (or **Email, Phone, Username** / **Authentication**).
3. Find the **Email** (or **Email address**) section and its **Verification** settings.
4. Look for options like:
   - **“Require verification at sign-up”** – keep this **on** so new users verify when creating an account.
   - **“Require verification at sign-in”** (or “Verify on every sign-in”) – set this to **off** so existing users are not asked for OTP when logging in.

Clerk lets you configure verification separately for **sign-up** vs **sign-in**. Set it so that:

- **Sign-up:** Email/OTP verification **on** (for new accounts).
- **Sign-in:** Email/OTP verification **off** (returning users just enter password, no OTP).

Exact labels may vary by Clerk version; if you don’t see “sign-in” vs “sign-up”, look for “Verification” or “Email verification” and any option that applies to existing users / sign-in and disable it for sign-in only.
