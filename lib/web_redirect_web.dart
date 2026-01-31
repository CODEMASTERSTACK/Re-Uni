// Web implementation: same-window redirect and URL callback parsing.
import 'dart:html' as html;

void redirectToClerkSignIn(String url) {
  html.window.location.href = url;
}

/// Redirects to clerk-signout.html so Clerk session is cleared; that page signs out and redirects back to app.
void redirectToClerkSignOut() {
  html.window.location.href = '/clerk-signout.html';
}

/// Parses query string (e.g. "?a=1&b=2" or "a=1&b=2") into a map.
Map<String, String> _parseQuery(String search) {
  final q = <String, String>{};
  if (search.isEmpty) return q;
  final withoutLead = search.startsWith('?') ? search.substring(1) : search;
  final pairs = withoutLead.split('&');
  for (final p in pairs) {
    final idx = p.indexOf('=');
    if (idx <= 0) continue;
    final key = Uri.decodeComponent(p.substring(0, idx).trim());
    final value = Uri.decodeComponent(p.substring(idx + 1).trim());
    if (key.isNotEmpty) q[key] = value;
  }
  return q;
}

/// Token and user info parsed from URL – seeded as soon as library loads so we don't lose them after redirect.
String? _cachedToken = _seedTokenFromBrowser();
String? _cachedName;
String? _cachedEmail;

String? _seedTokenFromBrowser() {
  try {
    final href = html.window.location.href;
    if (href.isEmpty) return null;
    final uri = Uri.tryParse(href);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      _cachedName = uri.queryParameters['__clerk_name'] ?? uri.queryParameters['_clerk_name'];
      if (_cachedName != null && _cachedName!.isEmpty) _cachedName = null;
      _cachedEmail = uri.queryParameters['__clerk_email'] ?? uri.queryParameters['_clerk_email'];
      if (_cachedEmail != null && _cachedEmail!.isEmpty) _cachedEmail = null;
    }
    final t = uri?.queryParameters['__clerk_db_jwt'] ?? uri?.queryParameters['_clerk_db_jwt'] ?? uri?.queryParameters['_clerk_db_jwi'] ??
        uri?.queryParameters['__clerk_ticket'] ?? uri?.queryParameters['token'] ?? uri?.queryParameters['code'];
    return (t != null && t.isNotEmpty) ? t : null;
  } catch (_) {
    return null;
  }
}

String? _tokenFromUri(Uri? uri) {
  if (uri == null || uri.queryParameters.isEmpty) return null;
  final t = uri.queryParameters['__clerk_db_jwt'] ?? uri.queryParameters['_clerk_db_jwt'] ?? uri.queryParameters['_clerk_db_jwi'] ??
      uri.queryParameters['__clerk_ticket'] ?? uri.queryParameters['token'] ?? uri.queryParameters['code'];
  return (t != null && t.isNotEmpty) ? t : null;
}

/// Full current URL from the browser.
String getCurrentBrowserUrl() {
  return html.window.location.href;
}

/// Name and email from Clerk callback URL (set by clerk-bridge after sign-in).
String? getClerkCallbackName() {
  if (_cachedName != null && _cachedName!.isNotEmpty) return _cachedName;
  try {
    final uri = Uri.tryParse(html.window.location.href);
    final n = uri?.queryParameters['__clerk_name'] ?? uri?.queryParameters['_clerk_name'];
    if (n != null && n.isNotEmpty) { _cachedName = n; return n; }
  } catch (_) {}
  return null;
}

String? getClerkCallbackEmail() {
  if (_cachedEmail != null && _cachedEmail!.isNotEmpty) return _cachedEmail;
  try {
    final uri = Uri.tryParse(html.window.location.href);
    final e = uri?.queryParameters['__clerk_email'] ?? uri?.queryParameters['_clerk_email'];
    if (e != null && e.isNotEmpty) { _cachedEmail = e; return e; }
  } catch (_) {}
  return null;
}

/// Removes Clerk callback params from the URL so a refresh doesn't retry an expired token.
void clearClerkCallbackFromUrl() {
  try {
    _cachedToken = null;
    final u = Uri.parse(html.window.location.href);
    if (u.queryParameters.isEmpty) return;
    final clean = u.replace(path: u.path.isEmpty ? '/' : u.path, queryParameters: {}, fragment: '');
    html.window.history.replaceState(null, '', clean.toString());
  } catch (_) {}
}

/// Reads Clerk callback from current URL. Caches token on first successful read so redirect params aren't lost.
/// Clerk may pass __clerk_db_jwt (two underscores), _clerk_db_jwt, __clerk_ticket, token, or code.
String? getClerkCallbackToken() {
  try {
    // Return cached token if we already parsed it (URL may be normalized later and lose query params).
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    final href = html.window.location.href;
    if (href.isEmpty) return null;
    final uri = Uri.tryParse(href);
    final fromUri = _tokenFromUri(uri);
    if (fromUri != null) {
      _cachedToken = fromUri;
      return fromUri;
    }
    final search = html.window.location.search;
    final hash = html.window.location.hash;
    final q = _parseQuery(search ?? '');
    final fromQuery = q['__clerk_db_jwt'] ?? q['_clerk_db_jwt'] ?? q['_clerk_db_jwi'] ?? q['__clerk_ticket'] ?? q['token'] ?? q['code'];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      _cachedToken = fromQuery;
      return fromQuery;
    }
    if (hash.isNotEmpty) {
      final h = hash.startsWith('#') ? hash.substring(1) : hash;
      if (h.isNotEmpty) {
        _cachedToken = h;
        return h;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
