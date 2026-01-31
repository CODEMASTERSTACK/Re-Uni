# Clerk JWT after redirect ("Invalid JWT form")

## What was wrong

The backend `/api/get-custom-token` expects a **JWT** (three base64 parts separated by dots).  
Clerk’s redirect from the Account Portal was putting a **session reference** (e.g. `dvb_...`) in the URL, not the full JWT. Sending that to the API caused:

`401 {"error":"Invalid Clerk token","detail":"Invalid JWT form. A JWT consists of three parts separated by dots."}`

## Fix: clerk-bridge.html

We added a **bridge page** so the real JWT is obtained and then passed to the app:

1. **Redirect to the bridge**  
   When the user clicks “Sign in”, the app redirects to Clerk with  
   `redirect_url = <app-origin>/clerk-bridge.html`  
   so Clerk sends the user **back to the bridge**, not straight to the app root.

2. **Bridge runs Clerk.js**  
   `web/clerk-bridge.html` loads Clerk’s JS, calls `load()`, then uses the current session (synced from the URL) and calls `session.getToken()` to get the **session JWT**.

3. **Bridge redirects to the app with the JWT**  
   It then redirects to the app root with  
   `?__clerk_db_jwt=<jwt>`  
   so the Flutter app receives a proper JWT and can call `/api/get-custom-token` successfully.

So the flow is:

- App → Clerk sign-in → Clerk redirects to **clerk-bridge.html** (with URL session state)  
- Bridge loads Clerk.js, gets JWT via `getToken()`, redirects to **app root** with `__clerk_db_jwt=<jwt>`  
- App reads `__clerk_db_jwt`, calls backend, gets Firebase custom token, signs in.

## "Missing publishableKey" on the bridge

If the bridge shows "Clerk failed to load" or the console says **Missing publishableKey**, the Clerk script is not getting the key. Causes and fixes:

1. **Use Clerk’s CDN and `data-clerk-publishable-key`**  
   The bridge must load Clerk from **your Frontend API URL** (e.g. `https://<slug>.clerk.accounts.dev/npm/@clerk/clerk-js@5/dist/clerk.browser.js`) with the attribute **`data-clerk-publishable-key="pk_..."`** on the script tag. Loading from unpkg or passing the key only in `new Clerk(...)` can trigger "Missing publishableKey" in some builds.

2. **Correct Frontend API URL**  
   The script `src` must use your instance’s domain. For `working-turtle-74` it is `https://working-turtle-74.clerk.accounts.dev/...`. If your Clerk slug is different, get the Frontend API URL from Clerk Dashboard → API Keys and update the script `src` in `web/clerk-bridge.html`.

3. **Key in two places**  
   The same publishable key must be in:
   - `data-clerk-publishable-key="pk_..."`
   - The `publishableKey` variable used in the fallback `new Clerk(publishableKey)` (constructor expects the **string** key as first argument in the UMD build).

4. **Different publishable key**  
   If your app uses a different key (e.g. production), edit `web/clerk-bridge.html`: set both the `data-clerk-publishable-key` attribute and the `publishableKey` variable to that key, and use the matching Frontend API URL in the script `src`.
