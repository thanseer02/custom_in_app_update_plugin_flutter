import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';

void main() {
  group('InAppUpdateConfig', () {
    test('creates default store configuration properly', () {
      const config = InAppUpdateConfig();

      expect(config.source, UpdateSource.store);
      expect(config.endpoint, isNull);
      expect(config.maxRetries, 3);
      expect(config.retryDelay, const Duration(seconds: 2));
      expect(config.forceUpdate, false);
      expect(config.checkOnStartup, true);
      expect(config.timeout, const Duration(seconds: 15));
    });

    test('creates valid remote configuration when endpoint is provided', () {
      const config = InAppUpdateConfig(
        source: UpdateSource.remote,
        endpoint: 'https://example.com/app-version',
        timeout: Duration(seconds: 5),
        maxRetries: 2,
      );

      expect(config.source, UpdateSource.remote);
      expect(config.endpoint, 'https://example.com/app-version');
      expect(config.timeout, const Duration(seconds: 5));
      expect(config.maxRetries, 2);
    });

    test('asserts when UpdateSource.remote is set without endpoint', () {
      expect(
        () => InAppUpdateConfig(source: UpdateSource.remote),
        throwsAssertionError,
      );
    });

    test('asserts when UpdateSource.remote is set with empty endpoint', () {
      expect(
        () => InAppUpdateConfig(source: UpdateSource.remote, endpoint: ''),
        throwsAssertionError,
      );
    });
  });
}
