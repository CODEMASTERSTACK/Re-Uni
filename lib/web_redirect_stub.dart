// Stub for non-web platforms. Only used when kIsWeb is false; redirect is never called.

void redirectToClerkSignIn(String url) {
  throw UnsupportedError('redirectToClerkSignIn is only supported on web');
}

String getCurrentBrowserUrl() => '';

/// Returns token/code from URL callback, or null. Web only.
String? getClerkCallbackToken() => null;
