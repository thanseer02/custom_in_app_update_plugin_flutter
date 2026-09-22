import 'dart:convert';
import 'dart:io';
import '../enums/update_availability.dart';
import '../enums/update_source.dart';
import '../models/update_info.dart';

/// Service responsible for performing iTunes App Store lookups on iOS.
class AppStoreLookupService {
  final HttpClient _httpClient;

  AppStoreLookupService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  /// Queries the iTunes Lookup API for the given [bundleId] and compares against [currentVersion].
  Future<UpdateInfo> lookup({
    required String bundleId,
    required String currentVersion,
    String? countryCode,
  }) async {
    if (bundleId.isEmpty) {
      return UpdateInfo(
        versionCode: 0,
        availability: UpdateAvailability.unknown,
        source: UpdateSource.appStore,
        currentVersion: currentVersion,
      );
    }

    try {
      final countryParam = countryCode != null && countryCode.isNotEmpty
          ? '&country=$countryCode'
          : '';
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$bundleId$countryParam',
      );

      final request = await _httpClient.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
      );
      final response = await request.close();

      if (response.statusCode != 200) {
        return UpdateInfo(
          versionCode: 0,
          availability: UpdateAvailability.unknown,
          source: UpdateSource.appStore,
          currentVersion: currentVersion,
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final resultCount = (data['resultCount'] as num?)?.toInt() ?? 0;
      final results = data['results'] as List<dynamic>?;

      if (resultCount == 0 || results == null || results.isEmpty) {
        return UpdateInfo(
          versionCode: 0,
          availability: UpdateAvailability.notAvailable,
          source: UpdateSource.appStore,
          currentVersion: currentVersion,
        );
      }

      final appData = results[0] as Map<String, dynamic>;
      final storeVersion = (appData['version'] as String?) ?? '';
      final releaseNotes = (appData['releaseNotes'] as String?) ?? '';
      final trackViewUrl = (appData['trackViewUrl'] as String?) ?? '';
      final trackId = (appData['trackId'] as num?)?.toInt() ?? 0;

      final isNewer = isVersionNewer(storeVersion, currentVersion);
      final availability =
          isNewer ? UpdateAvailability.available : UpdateAvailability.notAvailable;

      return UpdateInfo(
        versionCode: trackId,
        availableVersion: storeVersion,
        currentVersion: currentVersion,
        releaseNotes: releaseNotes,
        appStoreUrl: trackViewUrl,
        availability: availability,
        source: UpdateSource.appStore,
        immediateAllowed: false,
        flexibleAllowed: isNewer,
      );
    } catch (_) {
      return UpdateInfo(
        versionCode: 0,
        availability: UpdateAvailability.unknown,
        source: UpdateSource.appStore,
        currentVersion: currentVersion,
      );
    }
  }

  /// Returns true if [storeVersion] is strictly newer than [currentVersion].
  static bool isVersionNewer(String storeVersion, String currentVersion) {
    if (storeVersion.isEmpty || currentVersion.isEmpty) return false;

    // Clean version strings (strip leading 'v', build metadata, etc.)
    final cleanStore = storeVersion.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
    final cleanCurrent = currentVersion.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;

    final storeParts = cleanStore.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = storeParts.length > currentParts.length ? storeParts.length : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;

      if (s > c) return true;
      if (s < c) return false;
    }

    return false;
  }
}
