// Web implementation: same-window redirect and URL callback parsing.
import 'dart:html' as html;

void redirectToClerkSignIn(String url) {
  html.window.location.href = url;
}

/// Parses query string (e.g. "?a=1&b=2" or "a=1&b=2") into a map. Uses browser's location.search so we see the real URL.
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

/// Full current URL from the browser (so we can parse it and get query params).
String getCurrentBrowserUrl() {
  return html.window.location.href;
}

/// Reads Clerk callback from current URL using the browser's location so we definitely see query params.
/// Clerk may pass _clerk_db_jwt, __clerk_ticket, token, or code.
String? getClerkCallbackToken() {
  // Prefer parsing the full href so we're 100% using what the browser has.
  final href = html.window.location.href;
  if (href.isEmpty) return null;
  final uri = Uri.tryParse(href);
  if (uri != null && uri.queryParameters.isNotEmpty) {
    final t = uri.queryParameters['_clerk_db_jwt'] ?? uri.queryParameters['_clerk_db_jwi'] ??
        uri.queryParameters['__clerk_ticket'] ?? uri.queryParameters['token'] ?? uri.queryParameters['code'];
    if (t != null && t.isNotEmpty) return t;
  }
  // Fallback: search and hash
  final search = html.window.location.search;
  final hash = html.window.location.hash;
  final q = _parseQuery(search ?? '');
  final fromQuery = q['_clerk_db_jwt'] ?? q['_clerk_db_jwi'] ?? q['__clerk_ticket'] ?? q['token'] ?? q['code'];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
  if (hash.isNotEmpty) return hash.startsWith('#') ? hash.substring(1) : hash;
  return null;
}
