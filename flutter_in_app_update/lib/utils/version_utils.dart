/// Utility class for comparing application versions and build numbers.
class VersionUtils {
  /// Compares two semantic version strings (e.g. "1.2.3").
  ///
  /// Returns:
  /// * `1` if [v1] is greater than [v2]
  /// * `-1` if [v1] is less than [v2]
  /// * `0` if [v1] equals [v2]
  /// 
  /// Throws a [FormatException] if the versions are invalid.
  static int compareVersions(String v1, String v2) {
    List<int> v1Parts = _parseVersion(v1);
    List<int> v2Parts = _parseVersion(v2);

    int length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < length; i++) {
      int p1 = i < v1Parts.length ? v1Parts.length > i ? v1Parts[i] : 0 : 0;
      int p2 = i < v2Parts.length ? v2Parts.length > i ? v2Parts[i] : 0 : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }

  /// Compares two build numbers.
  /// 
  /// Returns `1` if [b1] > [b2], `-1` if [b1] < [b2], and `0` if they are equal.
  static int compareBuildNumbers(int b1, int b2) {
    if (b1 > b2) return 1;
    if (b1 < b2) return -1;
    return 0;
  }

  static List<int> _parseVersion(String version) {
    if (version.trim().isEmpty) {
      throw const FormatException('Version string cannot be empty.');
    }
    try {
      return version.split('.').map((e) {
        // Strip out pre-release tags for simple numeric comparison
        String numericPart = e.split('-').first;
        return int.parse(numericPart);
      }).toList();
    } catch (e) {
      throw FormatException('Invalid version format: $version');
    }
  }
}
