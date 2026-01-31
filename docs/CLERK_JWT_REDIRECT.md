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

## If you use a different Clerk publishable key

The bridge page uses this default publishable key (same as in `lib/main.dart`):

`pk_test_d29ya2luZy10dXJ0bGUtNzQuY2xlcmsuYWNjb3VudHMuZGV2JA`

If your app uses a **different** publishable key (e.g. production or another instance), edit `web/clerk-bridge.html` and set the `publishableKey` variable to your key so the bridge talks to the correct Clerk instance.
