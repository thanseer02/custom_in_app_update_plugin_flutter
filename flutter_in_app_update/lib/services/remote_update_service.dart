import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/in_app_update_config.dart';
import '../models/remote_update_response.dart';
import 'update_cache_service.dart';

/// Exception thrown when a network error occurs during update check.
class UpdateNetworkException implements Exception {
  final String message;
  UpdateNetworkException(this.message);
  @override
  String toString() => 'UpdateNetworkException: $message';
}

/// Exception thrown when the remote update response cannot be parsed.
class UpdateParseException implements Exception {
  final String message;
  UpdateParseException(this.message);
  @override
  String toString() => 'UpdateParseException: $message';
}

/// Service to fetch remote update configurations.
class RemoteUpdateService {
  final UpdateCacheService _cacheService;
  final HttpClient _httpClient;

  RemoteUpdateService({
    UpdateCacheService? cacheService,
    HttpClient? httpClient,
  })  : _cacheService = cacheService ?? UpdateCacheService(),
        _httpClient = httpClient ?? HttpClient();

  /// Fetches the update configuration from the remote endpoint.
  /// Validates the URL, handles retries, timeouts, and caching.
  Future<RemoteUpdateResponse> fetchUpdateConfig(InAppUpdateConfig config) async {
    final endpoint = config.endpoint;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('Endpoint must not be null or empty for remote source.');
    }

    final uri = Uri.tryParse(endpoint);
    if (uri == null) {
      throw ArgumentError('Invalid endpoint URL.');
    }

    if (uri.scheme != 'https') {
      throw ArgumentError('Endpoint URL must use HTTPS.');
    }

    RemoteUpdateResponse? response;
    int attempts = 0;
    while (attempts <= config.maxRetries) {
      try {
        response = await _attemptFetch(uri, config.timeout);
        break; // Success
      } on UpdateParseException {
        rethrow;
      } catch (e) {
        attempts++;
        if (attempts > config.maxRetries) {
          // If all retries fail, try to fall back to cache
          final cached = await _cacheService.getCache();
          if (cached != null) {
            return cached;
          }
          throw UpdateNetworkException('Failed to fetch remote config after $attempts attempts: $e');
        }
        await Future.delayed(config.retryDelay);
      }
    }

    if (response != null) {
      await _cacheService.saveCache(response);
      return response;
    }

    throw UpdateNetworkException('Failed to fetch remote config.');
  }

  Future<RemoteUpdateResponse> _attemptFetch(Uri uri, Duration timeout) async {
    try {
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        throw UpdateNetworkException('HTTP Error: ${response.statusCode}');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      
      try {
        final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
        return RemoteUpdateResponse.fromJson(jsonMap);
      } catch (e) {
        throw UpdateParseException('Failed to parse JSON response: $e');
      }
    } on TimeoutException {
      throw UpdateNetworkException('Request timed out.');
    } on SocketException catch (e) {
      throw UpdateNetworkException('Network error: ${e.message}');
    }
  }
}
