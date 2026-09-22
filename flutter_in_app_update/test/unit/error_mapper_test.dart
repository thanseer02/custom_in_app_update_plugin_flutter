import 'package:flutter/services.dart';
import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    test('maps PlatformException UNAVAILABLE correctly', () {
      final platformException = PlatformException(
        code: 'UNAVAILABLE',
        message: 'Something is unavailable',
      );

      final result = ErrorMapper.mapPlatformException(platformException);

      expect(result.code, InAppUpdateErrorCode.updateUnavailable);
      expect(result.message, 'No update is currently available.');
      expect(result.originalError, platformException);
    });

    test('maps PlatformException CANCELED correctly', () {
      final platformException = PlatformException(
        code: 'CANCELED',
        message: 'User canceled',
      );

      final result = ErrorMapper.mapPlatformException(platformException);

      expect(result.code, InAppUpdateErrorCode.updateCanceled);
      expect(result.message, 'The update was canceled by the user.');
    });

    test('maps unknown PlatformException to unknownError', () {
      final platformException = PlatformException(
        code: 'WEIRD_CODE',
        message: 'Something weird happened',
      );

      final result = ErrorMapper.mapPlatformException(platformException);

      expect(result.code, InAppUpdateErrorCode.unknownError);
      expect(result.message, 'Something weird happened');
    });

    test('maps generic errors to unknownError', () {
      final genericError = StateError('Bad state');

      final result = ErrorMapper.mapGenericError(genericError);

      expect(result.code, InAppUpdateErrorCode.unknownError);
      expect(result.message, 'An unexpected error occurred during the update process.');
      expect(result.originalError, genericError);
    });

    test('does not wrap already mapped InAppUpdateException', () {
      const existingException = InAppUpdateException(
        InAppUpdateErrorCode.networkError,
        'Network failed',
      );

      final result = ErrorMapper.mapGenericError(existingException);

      expect(result, existingException);
      expect(result.code, InAppUpdateErrorCode.networkError);
    });
  });
}
