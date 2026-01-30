# UniDate – How to Run for Testing

The app is **ready to run** once the backend and Firebase are set up. Follow these steps.

---

## 1. Prerequisites

- **Flutter SDK** (3.10+)
- **Node.js** (18+) – for the Vercel API
- **Firebase CLI** – `npm install -g firebase-tools` then `firebase login`
- **Clerk** account – publishable key is already in the app; you need the secret key for the API
- **Firebase** project with Firestore created (you already did this)
- **Vercel** account (optional for local testing; use `vercel dev`)

---

## 2. One-time setup

### 2.1 Deploy Firestore rules and indexes

From the **project root**:

```bash
firebase deploy --only firestore
```

This deploys `firestore.rules` and `firestore.indexes.json` so the app can read/write Firestore correctly.

### 2.2 Backend API (choose one)

**Option A – Use deployed Vercel API (easiest)**  
- Deploy the API: from project root run `npm install` then `vercel`.  
- In Vercel Dashboard → your project → **Settings → Environment Variables**, add:
  - `CLERK_SECRET_KEY`
  - `FIREBASE_SERVICE_ACCOUNT_JSON` (full JSON, single line)
  - `BREVO_API_KEY` (optional; without it, OTP is only in Firestore/logs for testing)
  - R2 variables if you want profile image uploads: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_PUBLIC_URL`
- The Flutter app already uses `https://re-uni.vercel.app` as the default backend; if your Vercel URL is different, use the run command in step 3 with `BACKEND_URL` (see below).

**Option B – Run API locally**  
- From project root: `npm install` then `vercel dev`.  
- This serves the API at `http://localhost:3000`.  
- When running Flutter, point to it: use the run command with `--dart-define=BACKEND_URL=http://localhost:3000` (see step 3).

---

## 3. Run the Flutter app (web)

From the **project root**:

```bash
flutter pub get
flutter run -d chrome
```

Or to run with the **local** backend (if you use `vercel dev`):

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000
```

- **Chrome**: `flutter run -d chrome`  
- **Default browser**: `flutter run -d web-server` (then open the URL shown, e.g. `http://localhost:xxxxx`)

---

## 4. What to test

1. **Landing** → Create account / Log in (Clerk).
2. **After sign-in** → AuthGate gets a Firebase custom token from your API and redirects to Profile Setup (new user) or Profile Summary (returning).
3. **Profile setup** → Age, gender, location, interests, profile images (images need R2 env vars if you want uploads).
4. **Verification** → Add `@lpu.in` email, request OTP (Brevo or logs), enter OTP.
5. **Profile Summary** → View/edit profile, then open **Swipe**, **Matches**, **Chat** from the bottom nav.

---

## 5. Web: path_provider fix

On Flutter web, `clerk_flutter` uses `path_provider`'s `getApplicationDocumentsDirectory`, which has **no web implementation** and would cause a perpetual loading spinner and `MissingPluginException`. The app registers a **web stub** in `main()` (`path_provider_stub_web.dart`) so that calls return dummy paths and the app can load. No extra step needed when running in Chrome.

---

## 6. Quick checklist

| Item | Status |
|------|--------|
| Firestore created in Firebase Console | ✓ You did this |
| Firestore rules & indexes deployed | Run `firebase deploy --only firestore` |
| Backend env vars set (Vercel or `.env` for `vercel dev`) | Set CLERK_SECRET_KEY, FIREBASE_SERVICE_ACCOUNT_JSON |
| Flutter dependencies | `flutter pub get` |
| Run app | `flutter run -d chrome` (add BACKEND_URL if using local API) |

If the backend is deployed and Firestore rules are deployed, you’re **ready to run for testing** with the commands above.
