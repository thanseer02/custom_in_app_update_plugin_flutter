/// Utility class for robust semantic version comparison.
/// 
/// Comparison Rules:
/// 1. Null or empty strings are treated as an invalid version (0.0.0).
/// 2. Invalid or malformed versions are safely parsed as 0.0.0 without crashing.
/// 3. Core version parts (Major.Minor.Patch...) are compared numerically.
/// 4. Pre-release versions (e.g. -beta.1) are considered OLDER than normal versions.
///    - If both have pre-release identifiers, they are compared segment by segment.
///    - Numeric segments are compared numerically, alphabetical segments lexically.
///    - Numeric segments are considered LOWER than alphabetical segments.
/// 5. Build metadata (e.g. +12) is compared if all other parts are equal. 
///    - A version with build metadata is considered NEWER than one without.
///    - Numeric builds are compared numerically, others lexically.
class VersionComparator {
  
  /// Compares two version strings.
  /// 
  /// Returns:
  /// * `1` if [v1] > [v2]
  /// * `-1` if [v1] < [v2]
  /// * `0` if [v1] == [v2]
  static int compare(String? v1, String? v2) {
    final parsedV1 = _ParsedVersion.parse(v1);
    final parsedV2 = _ParsedVersion.parse(v2);
    return parsedV1.compareTo(parsedV2);
  }

  /// Checks if an update is available by comparing current and available versions.
  /// 
  /// Returns `true` if [availableVersion] > [currentVersion].
  static bool isUpdateAvailable(String? currentVersion, String? availableVersion) {
    return compare(availableVersion, currentVersion) > 0;
  }

  /// Checks if the current version meets the minimum version requirement.
  /// 
  /// Returns `true` if [currentVersion] >= [minimumVersion].
  static bool isMinimumVersionSatisfied(String? currentVersion, String? minimumVersion) {
    if (minimumVersion == null || minimumVersion.trim().isEmpty) return true;
    return compare(currentVersion, minimumVersion) >= 0;
  }
}

class _ParsedVersion implements Comparable<_ParsedVersion> {
  final List<int> parts;
  final List<String> preRelease;
  final String build;

  _ParsedVersion(this.parts, this.preRelease, this.build);

  static _ParsedVersion parse(String? versionString) {
    if (versionString == null || versionString.trim().isEmpty) {
      return _ParsedVersion([0, 0, 0], [], '');
    }

    String v = versionString.trim();
    String build = '';
    if (v.contains('+')) {
      final split = v.split('+');
      v = split[0];
      build = split.length > 1 ? split.sublist(1).join('+') : '';
    }

    List<String> preRelease = [];
    if (v.contains('-')) {
      int dashIndex = v.indexOf('-');
      preRelease = v.substring(dashIndex + 1).split('.');
      v = v.substring(0, dashIndex);
    }

    List<int> parts = [];
    try {
      if (v.isNotEmpty) {
        parts = v.split('.').map((e) => int.parse(e)).toList();
      } else {
        parts = [0, 0, 0];
      }
    } catch (_) {
      // Malformed version, fallback safely
      parts = [0, 0, 0];
      preRelease = [];
      build = '';
    }

    return _ParsedVersion(parts, preRelease, build);
  }

  @override
  int compareTo(_ParsedVersion other) {
    // 1. Compare major, minor, patch...
    int length = parts.length > other.parts.length ? parts.length : other.parts.length;
    for (int i = 0; i < length; i++) {
      int p1 = i < parts.length ? parts[i] : 0;
      int p2 = i < other.parts.length ? other.parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    // 2. Compare pre-release
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) return 1;
    if (preRelease.isNotEmpty && other.preRelease.isEmpty) return -1;
    
    if (preRelease.isNotEmpty && other.preRelease.isNotEmpty) {
      int prLen = preRelease.length > other.preRelease.length ? preRelease.length : other.preRelease.length;
      for (int i = 0; i < prLen; i++) {
        if (i >= preRelease.length) return -1;
        if (i >= other.preRelease.length) return 1;

        String pr1 = preRelease[i];
        String pr2 = other.preRelease[i];

        bool isNum1 = _isNumeric(pr1);
        bool isNum2 = _isNumeric(pr2);

        if (isNum1 && isNum2) {
          int n1 = int.parse(pr1);
          int n2 = int.parse(pr2);
          if (n1 > n2) return 1;
          if (n1 < n2) return -1;
        } else if (isNum1 && !isNum2) {
          return -1;
        } else if (!isNum1 && isNum2) {
          return 1;
        } else {
          int cmp = pr1.compareTo(pr2);
          if (cmp != 0) return cmp > 0 ? 1 : -1;
        }
      }
    }

    // 3. Compare build metadata
    if (build != other.build) {
      if (build.isEmpty) return -1;
      if (other.build.isEmpty) return 1;

      bool isNum1 = _isNumeric(build);
      bool isNum2 = _isNumeric(other.build);
      
      if (isNum1 && isNum2) {
        int b1 = int.parse(build);
        int b2 = int.parse(other.build);
        if (b1 > b2) return 1;
        if (b1 < b2) return -1;
      } else {
        int cmp = build.compareTo(other.build);
        if (cmp != 0) return cmp > 0 ? 1 : -1;
      }
    }

    return 0;
  }

  bool _isNumeric(String s) {
    if (s.isEmpty) return false;
    return int.tryParse(s) != null;
  }
}
