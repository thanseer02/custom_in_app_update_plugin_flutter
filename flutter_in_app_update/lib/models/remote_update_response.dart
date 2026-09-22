/// Represents the response from a remote update configuration endpoint.
class RemoteUpdateResponse {
  final PlatformUpdateData? android;
  final PlatformUpdateData? ios;

  RemoteUpdateResponse({
    this.android,
    this.ios,
  });

  factory RemoteUpdateResponse.fromJson(Map<String, dynamic> json) {
    return RemoteUpdateResponse(
      android: json['android'] != null
          ? PlatformUpdateData.fromJson(json['android'] as Map<String, dynamic>)
          : null,
      ios: json['ios'] != null
          ? PlatformUpdateData.fromJson(json['ios'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (android != null) 'android': android!.toJson(),
      if (ios != null) 'ios': ios!.toJson(),
    };
  }
}

/// Platform-specific update data.
class PlatformUpdateData {
  final String latestVersion;
  final String? minimumVersion;
  final String? url;

  PlatformUpdateData({
    required this.latestVersion,
    this.minimumVersion,
    this.url,
  });

  factory PlatformUpdateData.fromJson(Map<String, dynamic> json) {
    if (json['latestVersion'] == null) {
      throw FormatException('latestVersion is required in platform data');
    }
    return PlatformUpdateData(
      latestVersion: json['latestVersion'] as String,
      minimumVersion: json['minimumVersion'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      if (minimumVersion != null) 'minimumVersion': minimumVersion,
      if (url != null) 'url': url,
    };
  }
}
