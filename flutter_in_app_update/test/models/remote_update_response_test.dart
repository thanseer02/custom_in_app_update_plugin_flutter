import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';

void main() {
  group('RemoteUpdateResponse & PlatformUpdateData', () {
    test('fromJson and toJson parse valid payload correctly', () {
      final json = {
        'android': {
          'latestVersion': '2.5.0',
          'minimumVersion': '2.0.0',
          'url': 'https://example.com/android',
        },
        'ios': {
          'latestVersion': '2.4.0',
          'minimumVersion': '1.9.0',
          'url': 'https://example.com/ios',
        },
      };

      final response = RemoteUpdateResponse.fromJson(json);

      expect(response.android?.latestVersion, '2.5.0');
      expect(response.android?.minimumVersion, '2.0.0');
      expect(response.android?.url, 'https://example.com/android');

      expect(response.ios?.latestVersion, '2.4.0');
      expect(response.ios?.minimumVersion, '1.9.0');
      expect(response.ios?.url, 'https://example.com/ios');

      final serialized = response.toJson();
      expect(serialized, json);
    });

    test('handles missing platform data gracefully', () {
      final json = {
        'android': {
          'latestVersion': '2.5.0',
        },
      };

      final response = RemoteUpdateResponse.fromJson(json);

      expect(response.android?.latestVersion, '2.5.0');
      expect(response.android?.minimumVersion, isNull);
      expect(response.android?.url, isNull);
      expect(response.ios, isNull);
    });

    test('throws FormatException if latestVersion is missing in PlatformUpdateData', () {
      final json = {
        'android': {
          'minimumVersion': '2.0.0',
        },
      };

      expect(() => RemoteUpdateResponse.fromJson(json), throwsFormatException);
    });
  });
}
