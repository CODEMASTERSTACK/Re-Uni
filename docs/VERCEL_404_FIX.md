# Fix 404 for /api/get-custom-token on Vercel

If **https://re-uni.vercel.app/api/get-custom-token** (and the OPTIONS preflight) returns **404 Not Found**, the serverless API is not being deployed or not reachable. Follow these steps.

---

## 1. Check Root Directory (most common cause)

Vercel builds and deploys from the **Root Directory** set in the project. If that is set to a **subfolder** (e.g. a folder that only has the Flutter app), the `api/` folder at the repo root is **not** included and all `/api/*` URLs return 404.

**Fix:**

1. Open your project on [Vercel Dashboard](https://vercel.com/dashboard) → select the **Re-Uni** project.
2. Go to **Settings** → **General**.
3. Find **Root Directory**.
4. Set it to **`.`** (repo root) or leave it **empty** so the root is the same as the repository root (where `api/` and `vercel.json` live).
5. Save and **redeploy** (Deployments → … on latest → Redeploy).

After redeploy, test:

- **https://re-uni.vercel.app/api**  
  Should return JSON: `{"message":"UniDate API","endpoints":[...]}`.  
  If this still returns 404, the API is still not deployed (see below).

- **https://re-uni.vercel.app/api/get-custom-token**  
  A GET may return 405 (Method Not Allowed); that’s fine. The important thing is **no 404**. Your app uses POST; the preflight OPTIONS should now get a 2xx and CORS headers.

---

## 2. Same repo: Flutter app + API

If this repo has both:

- A **Flutter web app** (built with `flutter build web`), and  
- An **API** in the `api/` folder,

you can deploy both from **one** Vercel project:

- **Root Directory:** `.` (repo root).
- **Build Command:** e.g. `flutter build web` (or whatever you use).
- **Output Directory:** e.g. `build/web` (where Flutter puts the built files).
- **Important:** The repo root must contain the `api/` folder and `vercel.json`. With Root Directory = `.`, Vercel will deploy both the static output and the serverless functions in `api/`.

If Root Directory is set to something like `web` or `frontend` (only the Flutter app), then `api/` is outside the build context and **all** `/api/*` routes will 404.

---

## 3. Optional: API-only project

If you prefer a **separate** Vercel project just for the API:

1. Create a new Vercel project connected to the **same** repo.
2. Set **Root Directory** to `.` (repo root).
3. Set **Build Command** to empty (or a no-op).
4. Set **Output Directory** to empty (or `.`).
5. Deploy. The API will be at `https://your-api-project.vercel.app/api/get-custom-token`.
6. In your Flutter app, set the backend base URL to that domain (e.g. `--dart-define=BACKEND_URL=https://your-api-project.vercel.app` for production builds).

Use this only if you intentionally want two deployments; for a single `re-uni.vercel.app` with both app and API, use one project with Root Directory = `.` as in step 1.

---

## 4. If /api works but /api/get-custom-token still 404s

If **https://re-uni.vercel.app/api** returns the JSON but **https://re-uni.vercel.app/api/get-custom-token** returns 404:

- **vercel.json** was updated to:
  - Remove the legacy **`builds`** config so Vercel auto-detects all `api/*.js` files as serverless functions.
  - Add **explicit rewrites** for each endpoint (`/api/get-custom-token`, etc.) so those paths are routed to the right function.
- **Redeploy** after pulling these changes. Then test `/api/get-custom-token` again (POST from your app or a 405 for GET in the browser is OK; 404 should be gone).
- In Vercel Dashboard → your project → **Deployments** → latest → **Functions**: confirm that `get-custom-token` (and other api files) appear. If only `index` appears, the build may be excluding other api files.

---

## 5. Summary

- **404 on /api/get-custom-token** → API not deployed, wrong root, or subpaths not routed.
- Set **Root Directory** to **`.`** (repo root) so `api/` and `vercel.json` are included.
- Use the latest **vercel.json** (no legacy `builds`, explicit rewrites for each api path).
- Redeploy and check **https://re-uni.vercel.app/api** first; then **/api/get-custom-token** (405 for GET is OK; 404 should be gone).
