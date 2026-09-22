import 'package:flutter/foundation.dart';

/// Represents the download progress of a flexible in-app update.
@immutable
class DownloadProgress {
  /// Bytes downloaded so far.
  final int bytesDownloaded;

  /// Total bytes to download.
  final int totalBytesToDownload;

  /// Install status code from the native platform (e.g. 2: DOWNLOADING, 3: DOWNLOADED).
  final int installStatus;

  /// Optional error code if the download failed.
  final int installErrorCode;

  const DownloadProgress({
    required this.bytesDownloaded,
    required this.totalBytesToDownload,
    this.installStatus = 0,
    this.installErrorCode = 0,
  });

  /// Download progress ratio as a value from 0.0 to 1.0.
  double get progress {
    if (totalBytesToDownload <= 0) return 0.0;
    return (bytesDownloaded / totalBytesToDownload).clamp(0.0, 1.0);
  }

  /// Download progress percentage from 0.0% to 100.0%.
  double get percentage => progress * 100;

  /// Whether the download is actively in progress.
  bool get isDownloading => installStatus == 2;

  /// Whether the download has completed and is ready for installation.
  bool get isDownloaded =>
      installStatus == 3 ||
      (totalBytesToDownload > 0 && bytesDownloaded >= totalBytesToDownload);

  /// Creates a [DownloadProgress] instance from native channel arguments.
  factory DownloadProgress.fromMap(Map<dynamic, dynamic> map) {
    return DownloadProgress(
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytesToDownload:
          (map['totalBytesToDownload'] as num?)?.toInt() ?? 0,
      installStatus: (map['installStatus'] as num?)?.toInt() ?? 0,
      installErrorCode: (map['installErrorCode'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'DownloadProgress($bytesDownloaded / $totalBytesToDownload bytes, ${percentage.toStringAsFixed(1)}%, status: $installStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadProgress &&
        other.bytesDownloaded == bytesDownloaded &&
        other.totalBytesToDownload == totalBytesToDownload &&
        other.installStatus == installStatus &&
        other.installErrorCode == installErrorCode;
  }

  @override
  int get hashCode => Object.hash(
        bytesDownloaded,
        totalBytesToDownload,
        installStatus,
        installErrorCode,
      );
}
