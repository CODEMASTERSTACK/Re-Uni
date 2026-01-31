// Stub for non-web platforms. Only used when kIsWeb is false; redirect is never called.

void redirectToClerkSignIn(String url) {
  throw UnsupportedError('redirectToClerkSignIn is only supported on web');
}

/// No-op on non-web; on web, redirects to clerk-signout.html to clear Clerk session.
void redirectToClerkSignOut() {}

String getCurrentBrowserUrl() => '';

/// Removes Clerk callback params from URL. No-op on non-web.
void clearClerkCallbackFromUrl() {}

/// Returns token/code from URL callback, or null. Web only.
String? getClerkCallbackToken() => null;

/// Name/email from Clerk callback URL. Web only.
String? getClerkCallbackName() => null;
String? getClerkCallbackEmail() => null;
