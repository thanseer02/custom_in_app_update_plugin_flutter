import 'package:flutter_test/flutter_test.dart';
import 'package:my_in_app_update/my_in_app_update.dart';

void main() {
  group('DownloadProgress tests', () {
    test('computes progress ratio and percentage accurately', () {
      const progress = DownloadProgress(
        bytesDownloaded: 250,
        totalBytesToDownload: 1000,
        installStatus: 2,
      );

      expect(progress.progress, 0.25);
      expect(progress.percentage, 25.0);
      expect(progress.isDownloading, isTrue);
      expect(progress.isDownloaded, isFalse);
    });

    test('handles zero total bytes gracefully', () {
      const progress = DownloadProgress(
        bytesDownloaded: 0,
        totalBytesToDownload: 0,
      );

      expect(progress.progress, 0.0);
      expect(progress.percentage, 0.0);
    });

    test('correctly identifies downloaded state', () {
      const progress = DownloadProgress(
        bytesDownloaded: 1000,
        totalBytesToDownload: 1000,
        installStatus: 3,
      );

      expect(progress.isDownloaded, isTrue);
      expect(progress.progress, 1.0);
      expect(progress.percentage, 100.0);
    });

    test('deserialization from map', () {
      final map = {
        'bytesDownloaded': 512,
        'totalBytesToDownload': 1024,
        'installStatus': 2,
        'installErrorCode': 0,
      };

      final progress = DownloadProgress.fromMap(map);
      expect(progress.bytesDownloaded, 512);
      expect(progress.totalBytesToDownload, 1024);
      expect(progress.progress, 0.5);
      expect(progress.percentage, 50.0);
    });
  });
}
