import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';

void main() {
  group('UpdateDecisionEngine', () {
    test('No update available when versions are same', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '1.0.0',
        config: const InAppUpdateConfig(),
      );

      expect(decision.isUpdateAvailable, false);
      expect(decision.isMandatory, false);
      expect(decision.policy, UpdatePolicy.none);
    });

    test('Missing store and latest version means no update', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: null,
        config: const InAppUpdateConfig(),
      );

      expect(decision.isUpdateAvailable, false);
      expect(decision.policy, UpdatePolicy.none);
    });

    test('Config latestVersion overrides storeVersion', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '1.0.1', // Available but overridden
        config: const InAppUpdateConfig(
          latestVersion: '2.0.0', // overrides storeVersion
        ),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.availableVersion, '2.0.0');
    });

    test('Optional update when no minimum/recommended set', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '1.1.0',
        config: const InAppUpdateConfig(),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.isMandatory, false);
      expect(decision.shouldPromptUser, false);
      expect(decision.policy, UpdatePolicy.optional);
    });

    test('Recommended update when below recommended version', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '1.2.0',
        config: const InAppUpdateConfig(
          recommendedVersion: '1.1.0',
        ),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.isMandatory, false);
      expect(decision.shouldPromptUser, true);
      expect(decision.policy, UpdatePolicy.recommended);
    });

    test('Optional update when above recommended version but update available', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.2.0',
        storeVersion: '1.3.0',
        config: const InAppUpdateConfig(
          recommendedVersion: '1.1.0',
        ),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.isMandatory, false);
      expect(decision.shouldPromptUser, false);
      expect(decision.policy, UpdatePolicy.optional);
    });

    test('Mandatory update when below minimum version', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '2.0.0',
        config: const InAppUpdateConfig(
          minimumVersion: '1.5.0',
          recommendedVersion: '1.8.0', // Minimum takes precedence
        ),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.isMandatory, true);
      expect(decision.shouldPromptUser, true);
      expect(decision.policy, UpdatePolicy.mandatory);
    });

    test('Mandatory update when forceUpdate is true', () {
      final decision = UpdateDecisionEngine.evaluate(
        currentVersion: '1.0.0',
        storeVersion: '1.0.1',
        config: const InAppUpdateConfig(
          forceUpdate: true,
        ),
      );

      expect(decision.isUpdateAvailable, true);
      expect(decision.isMandatory, true);
      expect(decision.shouldPromptUser, true);
      expect(decision.policy, UpdatePolicy.mandatory);
    });
  });
}
