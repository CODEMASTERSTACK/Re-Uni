# Fix: Clerk redirect back to app still shows landing page

## Problem

After sign-up/OTP on Clerk, the user is redirected to `http://localhost:xxxxx/?_clerk_db_jwt=...` but the app shows the **landing page** instead of processing the token and showing Profile setup or App shell.

## Root causes addressed

1. **Timing** – Callback ran in `initState` before the first frame; the browser URL might not be fully committed. **Fix:** Run `_handleCallback()` in `WidgetsBinding.instance.addPostFrameCallback` so it runs after the first frame.

2. **URL source** – Token was read only from `Uri.base` or `window.location.search`; Flutter web may not always expose query params the same way. **Fix:** In `web_redirect_web.dart`, read the token from `window.location.href` and parse with `Uri.tryParse(href).queryParameters`, then fall back to manual `search`/`hash` parsing.

3. **Single chance** – If the first read missed the token, we went straight to landing with no retry. **Fix:** When we're about to show the landing page, re-check the URL (both `web_redirect.getClerkCallbackToken()` and `Uri.base.queryParameters['_clerk_db_jwt']`). If a token is present, show "Signing you in..." and run `_handleCallback()` again.

## Code changes

- **`lib/web_app_root.dart`**
  - `initState`: schedule `_handleCallback()` in `addPostFrameCallback` instead of calling it directly.
  - Before returning the landing `MaterialApp`: if `getClerkCallbackToken()` or `Uri.base.queryParameters['_clerk_db_jwt'|'_clerk_db_jwi']` has a value, schedule a retry and return the "Signing you in..." loading screen.

- **`lib/web_redirect_web.dart`**
  - `getClerkCallbackToken()`: first parse `window.location.href` with `Uri.tryParse` and read query params from that; then fall back to `window.location.search` / `hash` parsing.
  - Added `getCurrentBrowserUrl()` for consistency.

- **`lib/web_redirect_stub.dart`**
  - Added `getCurrentBrowserUrl()` stub.

## Flow after fix

1. User returns from Clerk to `http://localhost:xxxxx/?_clerk_db_jwt=...`.
2. First frame paints (loading spinner).
3. After first frame, `_handleCallback()` runs and reads token from href + query params.
4. If token found: call backend `get-custom-token`, sign in to Firebase, show WebAuthGate → Profile setup or App shell.
5. If token not found: set `_checkingCallback = false`, build again.
6. When building the landing route, re-check URL (redirect helper + `Uri.base`). If token present, show "Signing you in..." and run `_handleCallback()` again.
7. If still no token: show landing page.

## If it still fails

- Confirm the backend `/api/get-custom-token` is deployed and accepts the `_clerk_db_jwt` value (Clerk’s JWT). If the backend returns 401, you’ll see the red error screen, not the landing page.
- In Chrome DevTools → Network, check that the page load is for the URL that includes `?_clerk_db_jwt=...` (no redirect that strips the query).
- Add a temporary `print(getClerkCallbackToken());` and `print(Uri.base);` in the callback path to confirm which URL/token is seen at runtime.
