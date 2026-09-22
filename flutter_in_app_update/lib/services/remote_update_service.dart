import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/in_app_update_config.dart';
import '../models/remote_update_response.dart';
import 'update_cache_service.dart';
import '../exceptions/in_app_update_exception.dart';

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
      throw const InAppUpdateException(
        InAppUpdateErrorCode.invalidConfiguration,
        'Endpoint must not be null or empty for remote source.',
      );
    }

    final uri = Uri.tryParse(endpoint);
    if (uri == null) {
      throw const InAppUpdateException(
        InAppUpdateErrorCode.invalidConfiguration,
        'Invalid endpoint URL.',
      );
    }

    if (uri.scheme != 'https') {
      throw const InAppUpdateException(
        InAppUpdateErrorCode.invalidConfiguration,
        'Endpoint URL must use HTTPS.',
      );
    }

    RemoteUpdateResponse? response;
    int attempts = 0;
    while (attempts <= config.maxRetries) {
      try {
        response = await _attemptFetch(uri, config.timeout);
        break; // Success
      } on InAppUpdateException catch (e) {
        if (e.code == InAppUpdateErrorCode.invalidVersion) {
          rethrow;
        }
        attempts++;
        if (attempts > config.maxRetries) {
          final cached = await _cacheService.getCache();
          if (cached != null) {
            return cached;
          }
          throw InAppUpdateException(
            e.code,
            'Failed to fetch remote config after $attempts attempts.',
            e,
          );
        }
        await Future.delayed(config.retryDelay);
      }
    }

    if (response != null) {
      await _cacheService.saveCache(response);
      return response;
    }

    throw const InAppUpdateException(
      InAppUpdateErrorCode.networkError,
      'Failed to fetch remote config.',
    );
  }

  Future<RemoteUpdateResponse> _attemptFetch(Uri uri, Duration timeout) async {
    try {
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        throw InAppUpdateException(
          InAppUpdateErrorCode.networkError,
          'HTTP Error: ${response.statusCode}',
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();
      
      try {
        final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
        return RemoteUpdateResponse.fromJson(jsonMap);
      } catch (e) {
        throw InAppUpdateException(
          InAppUpdateErrorCode.invalidVersion,
          'Failed to parse JSON response: $e',
          e,
        );
      }
    } on TimeoutException catch (e) {
      throw InAppUpdateException(
        InAppUpdateErrorCode.timeout,
        'Request timed out.',
        e,
      );
    } on SocketException catch (e) {
      throw InAppUpdateException(
        InAppUpdateErrorCode.networkError,
        'Network error: ${e.message}',
        e,
      );
    }
  }
}
