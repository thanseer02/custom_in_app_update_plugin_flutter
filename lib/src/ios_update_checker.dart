import 'dart:convert';
import 'package:http/http.dart' as http;
import 'update_info.dart';

/// iOS has no native in-app-update API, so this checks the current
/// installed version against what's published on the App Store via the
/// public iTunes Lookup API, and feeds the result into the same
/// [UpdateInfo] shape the Android flow uses.
class IosUpdateChecker {
  IosUpdateChecker._();
  static final IosUpdateChecker instance = IosUpdateChecker._();

  /// [bundleId] — your app's bundle identifier (e.g. com.company.app).
  /// [installedVersion] — pass this in from `package_info_plus`
  /// (PackageInfo.fromPlatform().version) so this package has no hard
  /// dependency on it.
  /// [country] — App Store storefront, defaults to 'us'.
  Future<UpdateInfo> checkForUpdate({
    required String bundleId,
    required String installedVersion,
    String country = 'us',
  }) async {
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$bundleId&country=$country',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return UpdateInfo(
          status: UpdateStatus.error,
          updateAvailable: false,
          installedVersion: installedVersion,
          errorMessage: 'App Store lookup failed (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return UpdateInfo(
          status: UpdateStatus.notAvailable,
          updateAvailable: false,
          installedVersion: installedVersion,
        );
      }

      final storeVersion = results.first['version'] as String? ?? '';
      final available = _isNewer(storeVersion, installedVersion);

      return UpdateInfo(
        status: available ? UpdateStatus.available : UpdateStatus.notAvailable,
        updateAvailable: available,
        availableVersion: storeVersion,
        installedVersion: installedVersion,
        // iOS has no immediate/flexible concept — these stay false, and
        // the consumer's custom UI will typically just deep-link out
        // to the App Store rather than calling performImmediateUpdate().
        immediateAllowed: false,
        flexibleAllowed: false,
      );
    } catch (e) {
      return UpdateInfo(
        status: UpdateStatus.error,
        updateAvailable: false,
        installedVersion: installedVersion,
        errorMessage: e.toString(),
      );
    }
  }

  /// Simple dotted-version comparison (e.g. "1.4.2" vs "1.10.0").
  bool _isNewer(String store, String installed) {
    final storeParts = store.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final installedParts =
        installed.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final len = storeParts.length > installedParts.length
        ? storeParts.length
        : installedParts.length;
    for (var i = 0; i < len; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final n = i < installedParts.length ? installedParts[i] : 0;
      if (s > n) return true;
      if (s < n) return false;
    }
    return false;
  }
}
