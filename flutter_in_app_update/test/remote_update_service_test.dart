import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_in_app_update/flutter_in_app_update.dart';
import 'package:flutter_in_app_update/services/update_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) => null;
  @override
  String? value(String name) => null;
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = -1;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  int? port;
  @override
  bool persistentConnection = false;
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final int _statusCode;
  final Stream<List<int>> _stream;

  MockHttpClientResponse(this._statusCode, String body)
      : _stream = Stream.value(utf8.encode(body));

  @override
  int get statusCode => _statusCode;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientRequest implements HttpClientRequest {
  final MockHttpClientResponse _response;

  MockHttpClientRequest(this._response);

  @override
  Future<HttpClientResponse> close() async {
    return _response;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClient implements HttpClient {
  int statusCode = 200;
  String responseBody = '{}';
  int callCount = 0;
  bool shouldTimeout = false;
  bool shouldThrowSocketException = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    callCount++;
    if (shouldTimeout) {
      // Simulate timeout by throwing or hanging
      await Future.delayed(const Duration(seconds: 1));
      throw TimeoutException('Simulated timeout');
    }
    if (shouldThrowSocketException) {
      throw const SocketException('Simulated socket exception');
    }
    return MockHttpClientRequest(MockHttpClientResponse(statusCode, responseBody));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUpdateCacheService implements UpdateCacheService {
  RemoteUpdateResponse? cachedResponse;

  @override
  Future<void> saveCache(RemoteUpdateResponse response) async {
    cachedResponse = response;
  }

  @override
  Future<RemoteUpdateResponse?> getCache() async {
    return cachedResponse;
  }

  @override
  Future<void> clearCache() async {
    cachedResponse = null;
  }
}

void main() {
  group('RemoteUpdateService', () {
    late RemoteUpdateService service;
    late MockHttpClient mockClient;
    late MockUpdateCacheService mockCache;

    setUp(() {
      mockClient = MockHttpClient();
      mockCache = MockUpdateCacheService();
      service = RemoteUpdateService(
        httpClient: mockClient,
        cacheService: mockCache,
      );
    });

    test('fetches and parses remote config successfully', () async {
      mockClient.statusCode = 200;
      mockClient.responseBody = jsonEncode({
        "android": {
          "latestVersion": "2.5.0",
          "minimumVersion": "2.0.0",
          "url": "https://example.com/android"
        },
        "ios": {
          "latestVersion": "2.6.0"
        }
      });

      final config = InAppUpdateConfig(
        source: UpdateSource.remote,
        endpoint: 'https://example.com/app-version',
      );

      final response = await service.fetchUpdateConfig(config);

      expect(response.android?.latestVersion, '2.5.0');
      expect(response.android?.minimumVersion, '2.0.0');
      expect(response.android?.url, 'https://example.com/android');
      expect(response.ios?.latestVersion, '2.6.0');
      expect(response.ios?.minimumVersion, isNull);
    });

    test('throws InAppUpdateException if endpoint is missing or empty', () async {
      expect(
        () => InAppUpdateConfig(source: UpdateSource.remote),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws InAppUpdateException if endpoint is not https', () async {
      final config = InAppUpdateConfig(
        source: UpdateSource.remote,
        endpoint: 'http://example.com/app-version',
      );

      expect(
        () => service.fetchUpdateConfig(config),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.invalidConfiguration,
          ),
        ),
      );
    });

    test('retries on failure', () async {
      mockClient.shouldThrowSocketException = true;

      final config = InAppUpdateConfig(
        source: UpdateSource.remote,
        endpoint: 'https://example.com/app-version',
        maxRetries: 2,
        retryDelay: const Duration(milliseconds: 10),
      );

      try {
        await service.fetchUpdateConfig(config);
        fail('Should throw exception');
      } catch (e) {
        expect(e, isA<InAppUpdateException>());
        final ex = e as InAppUpdateException;
        expect(ex.code, InAppUpdateErrorCode.networkError);
        expect(mockClient.callCount, 3); // Initial + 2 retries
      }
    });

    test('throws InAppUpdateException on invalid JSON', () async {
      mockClient.statusCode = 200;
      mockClient.responseBody = 'invalid json';

      final config = InAppUpdateConfig(
        source: UpdateSource.remote,
        endpoint: 'https://example.com/app-version',
        maxRetries: 0,
      );

      expect(
        () => service.fetchUpdateConfig(config),
        throwsA(
          isA<InAppUpdateException>().having(
            (e) => e.code,
            'code',
            InAppUpdateErrorCode.invalidVersion,
          ),
        ),
      );
    });
  });
}
