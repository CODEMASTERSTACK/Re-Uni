# Web auth (get-custom-token) – Vercel diagnostic checklist

Use this when env vars are set in Vercel but you still get **401 "Invalid Clerk token"** or **Failed to fetch /api/get-custom-token**.

---

## 1. Confirm which error you see

| What you see | Meaning |
|--------------|--------|
| **Failed to fetch** (no status code) | Request never reached the API: **CORS** (preflight missing headers), wrong URL, or network. If the **preflight OPTIONS** returns **404**, the API isn’t deployed—see [VERCEL_404_FIX.md](VERCEL_404_FIX.md) (usually **Root Directory** in Vercel must be repo root so `api/` is included). |
| **401 + "Invalid Clerk token"** | Request reached the API; Clerk JWT verification failed (see below). |
| **401 + `detail`** | Same as above; the `detail` field may hint at cause (e.g. `azp` mismatch). |
| **500 + "Backend config error"** | Firebase env problem: `FIREBASE_SERVICE_ACCOUNT_JSON` missing or invalid JSON. |
| **500 + "CLERK_SECRET_KEY not configured"** | `CLERK_SECRET_KEY` not set for the environment you’re hitting (e.g. Preview). |

---

## 2. CORS (Failed to fetch from localhost)

When the Flutter app runs on **http://localhost:54623** (or any port) and calls **https://re-uni.vercel.app/api/get-custom-token**, the browser sends an **OPTIONS** preflight first. If that response doesn’t include CORS headers, you get “No Access-Control-Allow-Origin header” and “Failed to fetch”.

**Fix:** `vercel.json` must define CORS headers for `/api/(.*)` so Vercel’s edge adds them to **all** API responses (including OPTIONS) before the serverless function runs. The project already has this; after changing it, **redeploy** so the new headers take effect.

---

## 3. Vercel env vars (must match exactly)

| Variable | Required | Scope | What to set |
|----------|----------|--------|-------------|
| `CLERK_SECRET_KEY` | Yes | **Production** (and Preview if you test preview URLs) | From Clerk Dashboard → API Keys. Use `sk_test_...` for development. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Yes | **Production** (and Preview if needed) | **Full** Firebase service account JSON as a **single-line** string (no newlines). From Firebase Console → Project Settings → Service accounts → Generate new private key. |
| `CLERK_AUTHORIZED_PARTIES` | Optional | Same as above | Comma-separated origins. If **not** set, the API uses a default list that includes `https://re-uni.vercel.app` and the Clerk portal. Set this **only** if you use a different app URL (e.g. custom domain). |

**Important:**  
- Name is **`FIREBASE_SERVICE_ACCOUNT_JSON`** (not `FIREBASE_SERVICE_ACCOUNT_KEY`).  
- Value must be **one line**. If you paste multi-line JSON, minify it (remove newlines) or the backend may fail with a config error.

---

## 4. Why 401 "Invalid Clerk token" still happens

Clerk’s `verifyToken` can fail for:

1. **Wrong `CLERK_SECRET_KEY`**  
   Must match the Clerk instance that issued the JWT (e.g. `sk_test_...` for dev).

2. **`azp` (authorized party) not allowed**  
   The JWT’s `azp` claim must be in `authorizedParties`.  
   - If you **don’t** set `CLERK_AUTHORIZED_PARTIES` in Vercel, the API now includes `https://re-uni.vercel.app` in the default list.  
   - If your Flutter app is served from a **different** URL (e.g. custom domain or another Vercel URL), add that URL to **`CLERK_AUTHORIZED_PARTIES`** in Vercel, e.g.  
     `https://your-app.vercel.app,https://working-turtle-74.accounts.dev`

3. **Expired or malformed token**  
   User took too long after sign-in, or the token in the redirect URL was corrupted/truncated.

4. **Token not sent correctly**  
   Flutter must send the **same** string that Clerk put in the redirect URL (e.g. `__clerk_db_jwt`). No extra encoding or trimming.

---

## 5. Redeploy after changing env vars

After adding or changing **any** env var in Vercel:

1. Save the variable and ensure it’s assigned to **Production** (and Preview if you use it).
2. **Redeploy** the project (e.g. trigger a new deployment from the Vercel dashboard or push a commit).  
   Env vars are baked in at **build/deploy** time; a restart may not be enough.

---

## 6. Quick test: local API vs Vercel

To see if the fault is Vercel vs your app:

1. **Local API**  
   - In project root: create `.env` with `CLERK_SECRET_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON` (and optionally `CLERK_AUTHORIZED_PARTIES`).  
   - Run: `npm run dev` (local API).  
   - Run Flutter: `flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000`.  
   - Sign in and see if get-custom-token succeeds.

2. If it **works locally** but **fails on Vercel**:  
   - Env vars on Vercel are wrong, missing, or not applied (e.g. wrong environment or no redeploy).  
   - Or your **production** app URL is not in `authorizedParties` (set `CLERK_AUTHORIZED_PARTIES` and redeploy).

3. If it **fails both** locally and on Vercel:  
   - Check `CLERK_SECRET_KEY` and token source (Clerk Dashboard, same key; token from redirect URL).  
   - Check `FIREBASE_SERVICE_ACCOUNT_JSON` is valid single-line JSON (you should get 500 "Backend config error" if it’s invalid).

---

## 7. Summary

- **CORS:** `vercel.json` includes CORS headers for `/api/(.*)` so OPTIONS preflight from localhost (or any origin) gets `Access-Control-Allow-Origin` and the real request can proceed.  
- Env names: **`CLERK_SECRET_KEY`**, **`FIREBASE_SERVICE_ACCOUNT_JSON`**.  
- `FIREBASE_SERVICE_ACCOUNT_JSON` = full service account JSON, **single line**.  
- Production origin **`https://re-uni.vercel.app`** is in the default authorized parties; add **`CLERK_AUTHORIZED_PARTIES`** only if you use another app URL.  
- **Redeploy** after any env or `vercel.json` change on Vercel.  
- Use the **exact error** (401 vs 500 vs Failed to fetch) and the **detail** field (if present) to narrow down the fault.
