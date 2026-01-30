# Plan: Fix Flutter Web Loading Screen (Clerk / path_provider / Platform)

## Problem

On Flutter web, the app stays on a loading screen and the console shows:

- `MissingPluginException` for `getApplicationDocumentsDirectory` (path_provider has no web impl)
- `Unsupported operation: Platform._pathSeparator` (dart:io is not supported on web)

**Root cause:** `clerk_flutter` uses a file-based persistor that calls `path_provider` and then uses `Directory` / `Platform.pathSeparator`. Even with `persistor: Persistor.none` in `ClerkAuthConfig`, the SDK still uses the file persistor internally in some code paths (e.g. default creation before config is applied, or `fileCache`), so the crash persists.

## Solution: Web-only auth (no ClerkAuth on web)

**Do not build `ClerkAuth` (or any clerk_flutter widget that touches the persistor) on web.** Use a separate web-only flow:

1. **Web-only root**  
   When `kIsWeb`, run `UniDateWebApp` instead of `MainApp`. `UniDateWebApp` never builds `ClerkAuth`.

2. **Web flow**  
   - Show the same landing UI (reuse `LandingPage` or a web copy).  
   - "Sign in" / "Create account" → redirect to Clerk’s hosted sign-in URL (same window).  
   - After sign-in, Clerk redirects back to our app. We read the callback from the URL (e.g. token/code in query or hash).  
   - Exchange that token/code for a Firebase custom token (existing backend), sign in to Firebase, then run the same post-auth flow (profile check → ProfileSetup or AppShell) via a **WebAuthGate** that only needs `uid` (no ClerkAuthState).

3. **WebAuthGate**  
   Same logic as `AuthGate`: take Firebase `uid`, load profile, `setSuspendedIfPastDeadline`, then show `ProfileSetupScreen` or `AppShell`. No Clerk session token needed; we already signed in with Firebase.

4. **Redirect helper**  
   Use conditional imports: on web, `dart:html` to set `window.location.href` for redirect and to read `Uri.base` for callback params. On non-web, stub that is never called when `kIsWeb` is false.

5. **Clerk sign-in URL**  
   Configurable (`kClerkWebSignInUrl`). **Use Account Portal domain:** in development it is `https://<slug>.accounts.dev/sign-in` (note: **accounts.dev**, not clerk.accounts.dev). Get the exact URL from Clerk Dashboard → **Account Portal** → Domains (or the URL shown on the sign-in/sign-up page). Override with `--dart-define=CLERK_WEB_SIGN_IN_URL=https://your-slug.accounts.dev/sign-in`.

## Files to add/change

- **`lib/web_app_root.dart`** – Web-only root: check `Uri.base` for callback; show landing (with redirect CTAs) or `WebAuthGate(uid)` after Firebase sign-in.
- **`lib/web_auth_gate.dart`** – Same as AuthGate but takes `userId: String`; no ClerkAuthState; uses placeholders for email/fullName if needed.
- **`lib/web_redirect_stub.dart`** – Stub for non-web: `redirectToClerk` no-op or throw; `getClerkCallbackToken` returns null.
- **`lib/web_redirect_web.dart`** – Web: `dart:html` to redirect and read callback from URL.
- **`lib/main.dart`** – If `kIsWeb` then `runApp(UniDateWebApp())`, else `runApp(MainApp())`. No ClerkAuth on web.

## Result

- Web: No ClerkAuth, no path_provider, no Platform → no crash; loading screen goes away.  
- Mobile/desktop: Unchanged; still use `MainApp` with ClerkAuth.

## Optional later

- If Clerk does not pass a token/code in the redirect URL, document the required Clerk config (e.g. redirect URL with token) or add a small backend endpoint to exchange a one-time code for a session token.
