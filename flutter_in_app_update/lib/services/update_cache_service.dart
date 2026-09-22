import 'dart:convert';
import 'dart:io';

import '../models/remote_update_response.dart';

/// Service to handle caching of remote update configurations.
class UpdateCacheService {
  final String _cacheFileName = 'flutter_in_app_update_cache.json';

  /// Saves the successful response to the cache.
  Future<void> saveCache(RemoteUpdateResponse response) async {
    try {
      final cacheFile = await _getCacheFile();
      final jsonString = jsonEncode(response.toJson());
      await cacheFile.writeAsString(jsonString);
    } catch (e) {
      // Ignore cache write errors as they shouldn't break the main flow.
    }
  }

  /// Retrieves the cached response if available.
  Future<RemoteUpdateResponse?> getCache() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        final jsonString = await cacheFile.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return RemoteUpdateResponse.fromJson(jsonMap);
      }
    } catch (e) {
      // Ignore cache read errors.
    }
    return null;
  }

  /// Clears the cached configuration.
  Future<void> clearCache() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (e) {
      // Ignore cache clear errors.
    }
  }

  Future<File> _getCacheFile() async {
    final tempDir = Directory.systemTemp;
    return File('${tempDir.path}${Platform.pathSeparator}$_cacheFileName');
  }
}
