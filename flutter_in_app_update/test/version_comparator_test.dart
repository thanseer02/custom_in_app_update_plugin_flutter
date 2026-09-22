import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/services/version_comparator.dart';

void main() {
  group('VersionComparator Tests', () {
    test('compare - older/newer versions', () {
      expect(VersionComparator.compare('1.0.0', '1.0.1'), -1);
      expect(VersionComparator.compare('1.0.1', '1.0.0'), 1);
      expect(VersionComparator.compare('1.2.0', '2.0.0'), -1);
      expect(VersionComparator.compare('10.0.0', '9.9.9'), 1);
    });

    test('compare - same versions', () {
      expect(VersionComparator.compare('1.0.0', '1.0.0'), 0);
      expect(VersionComparator.compare('1.2', '1.2.0'), 0);
      expect(VersionComparator.compare('10.0', '10.0.0.0'), 0);
    });

    test('compare - different build numbers', () {
      expect(VersionComparator.compare('1.0.0+1', '1.0.0+2'), -1);
      expect(VersionComparator.compare('1.0.0+25', '1.0.0+2'), 1); // numeric comparison
      expect(VersionComparator.compare('1.0.0+abc', '1.0.0+xyz'), -1); // lexical comparison
      
      // no build is older than having build
      expect(VersionComparator.compare('1.0.0', '1.0.0+1'), -1);
      expect(VersionComparator.compare('1.0.0+1', '1.0.0'), 1);
    });

    test('compare - prerelease versions', () {
      // prerelease is older than stable
      expect(VersionComparator.compare('1.0.0-beta', '1.0.0'), -1);
      expect(VersionComparator.compare('1.0.0', '1.0.0-rc'), 1);
      
      // lexical prerelease comparison
      expect(VersionComparator.compare('1.0.0-alpha', '1.0.0-beta'), -1);
      
      // prerelease segments comparison
      expect(VersionComparator.compare('1.0.0-alpha', '1.0.0-alpha.1'), -1);
      expect(VersionComparator.compare('1.0.0-alpha.2', '1.0.0-alpha.1'), 1);
      
      // numeric vs non-numeric
      expect(VersionComparator.compare('1.0.0-rc.1', '1.0.0-rc.a'), -1);
    });

    test('compare - invalid, missing, and null versions safely handled', () {
      // handled as 0.0.0 safely
      expect(VersionComparator.compare('invalid', '1.0.0'), -1); 
      expect(VersionComparator.compare('1.0.0', 'invalid'), 1);
      expect(VersionComparator.compare('invalid', 'bad'), 0);

      // missing / empty
      expect(VersionComparator.compare('', '1.0.0'), -1);
      expect(VersionComparator.compare('  ', '0.0.0'), 0);

      // null
      expect(VersionComparator.compare(null, '1.0.0'), -1);
      expect(VersionComparator.compare('1.0.0', null), 1);
      expect(VersionComparator.compare(null, null), 0);
    });

    test('isUpdateAvailable', () {
      expect(VersionComparator.isUpdateAvailable('1.0.0', '1.0.1'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.1', '1.0.0'), isFalse);
      expect(VersionComparator.isUpdateAvailable('1.0.0', '1.0.0'), isFalse);
      expect(VersionComparator.isUpdateAvailable('1.0.0', '1.0.0+1'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.0-beta', '1.0.0'), isTrue);
      expect(VersionComparator.isUpdateAvailable('1.0.0', 'invalid'), isFalse);
      expect(VersionComparator.isUpdateAvailable('invalid', '1.0.0'), isTrue);
    });

    test('isMinimumVersionSatisfied', () {
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.1', '1.0.0'), isTrue);
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.0', '1.0.0'), isTrue);
      expect(VersionComparator.isMinimumVersionSatisfied('0.9.9', '1.0.0'), isFalse);
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.0-beta', '1.0.0'), isFalse);
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.0', '1.0.0-beta'), isTrue);
      
      // Null minimum version should be treated as satisfied
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.0', null), isTrue);
      expect(VersionComparator.isMinimumVersionSatisfied('1.0.0', ''), isTrue);
    });
  });
}
