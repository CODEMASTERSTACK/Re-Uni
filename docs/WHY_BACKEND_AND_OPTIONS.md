# Why you need a backend (and how to simplify)

## Why a “server” (Vercel or similar) is required

The **get-custom-token** step cannot run in the browser. It must run on a **backend** because:

1. **Clerk secret key** – Verifying the Clerk JWT needs your **CLERK_SECRET_KEY**. That must never be in the client (Flutter web) or anyone could steal it and impersonate your backend.
2. **Firebase service account** – Creating a Firebase custom token needs your **Firebase service account private key**. That also must never be in the client.

So: **verify Clerk JWT on the server → create Firebase custom token on the server → return it to the client**. That’s why you have an API (Vercel serverless or similar).

You can’t “skip” having a server for this step without putting secrets in the client (insecure).

---

## Why the issues you hit aren’t “because of Vercel”

The problems (404, CORS, Root Directory) are **configuration** issues:

- **404** – Vercel wasn’t deploying your `api/` folder (e.g. wrong Root Directory). Fix: set Root Directory to repo root.
- **CORS** – Preflight (OPTIONS) didn’t get the right headers. Fix: `vercel.json` headers for `/api/(.*)`.

Same logic on **any** backend (Firebase, AWS, your own server) would need correct deployment and CORS. So it’s not that “Vercel forces you into issues” – it’s that any HTTP API used from a web app needs correct setup.

---

## How to simplify or “automate” things

### Option A: Move the token exchange to Firebase Cloud Functions (recommended if you want fewer moving parts)

Put the **same logic** (verify Clerk JWT → create Firebase custom token) in a **Firebase HTTP Cloud Function** instead of Vercel.

**Benefits:**

- One platform: Firebase for Auth, Firestore, **and** this API. No separate Vercel project, no Root Directory, no second domain.
- CORS is configured in one place (the Cloud Function), and you’re already in the Firebase ecosystem.
- Env vars (Clerk secret, etc.) live in Firebase config; no Vercel env setup for this endpoint.
- Flutter calls a URL like `https://us-central1-YOUR_PROJECT.cloudfunctions.net/getCustomToken` instead of `re-uni.vercel.app`.

**Trade-off:** You add a small Cloud Functions codebase (Node) and deploy with Firebase (e.g. `firebase deploy --only functions`). No ongoing “Vercel server” to think about for this flow.

If you want to go this route, the next step is to add a `functions/` project with a single HTTP function that does the same thing as `api/get-custom-token.js` and point your Flutter app at that URL.

---

### Option B: Keep Vercel but make deployment consistent

Stay on Vercel, but remove repeated mistakes:

1. **Checklist** – One-time: set Root Directory to `.`, add CORS headers in `vercel.json`, set env vars. Document in the repo (you already have `VERCEL_404_FIX.md` and the checklist).
2. **Single deploy command** – Use `vercel --prod` (or your CI) from the **repo root** so the same context is always deployed.
3. **Optional: deploy script** – e.g. `npm run deploy:api` that runs `vercel --prod` from the repo root and then (optionally) hits `https://re-uni.vercel.app/api` to check it’s not 404.

That doesn’t remove the need for a server, but it makes “creating/deploying the server” repeatable and less error‑prone.

---

### Option C: Use only Firebase Auth (no Clerk)

If you didn’t need Clerk, you could use **only** Firebase Auth (e.g. email link, Google sign-in). Then there’s no “exchange Clerk JWT for custom token” step and no backend for that. You’d lose Clerk’s features (hosted UI, user management, etc.). This is only relevant if you’re willing to drop Clerk.

---

## Summary

| Question | Answer |
|----------|--------|
| Why use a server (Vercel)? | To securely verify the Clerk JWT and create a Firebase custom token using **secret** keys that must not be in the client. |
| Can we skip the server? | No, not for this flow, without putting secrets in the client. |
| Can we avoid 404/CORS issues? | Yes: fix config (Root Directory, CORS) on Vercel, **or** move this one API to Firebase Cloud Functions and use one platform. |
| Automate? | You can’t automate away the need for a backend. You can automate **deployment** (scripts, CI) and simplify by moving the endpoint to Firebase so there’s one less platform to configure. |

If you want to move **get-custom-token** to Firebase Cloud Functions, say so and we can add a `functions/` implementation and update the Flutter app to call it.
