import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Stub implementation of PathProviderPlatform for Flutter web.
/// path_provider has no web implementation; clerk_flutter (and others) call
/// getApplicationDocumentsDirectory, which throws MissingPluginException on web.
/// Registering this stub returns dummy paths so the app can load; storage
/// will use in-memory or browser APIs instead of the filesystem.
class PathProviderStubWeb extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/app_documents';

  @override
  Future<String?> getApplicationSupportPath() async => '/app_support';

  @override
  Future<String?> getApplicationCachePath() async => '/app_cache';

  @override
  Future<String?> getTemporaryPath() async => '/tmp';

  @override
  Future<String?> getDownloadsPath() async => null;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;
}

/// Call from main() before runApp() when kIsWeb to avoid MissingPluginException.
void registerPathProviderStubWeb() {
  if (kIsWeb) {
    PathProviderPlatform.instance = PathProviderStubWeb();
  }
}
