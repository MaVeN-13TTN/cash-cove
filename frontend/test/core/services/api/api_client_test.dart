import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart' as dio;
import 'package:budget_tracker/core/services/api/api_client.dart';
import 'package:budget_tracker/core/exceptions/api_exception.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import '../../../mocks/mocks.mocks.dart';

void main() {
  late MockDio mockDio;
  late MockTokenManager mockTokenManager;
  late ApiClient apiClient;

  setUpAll(() async {
    // Create a temporary directory for Hive
    final tempDir = await Directory.systemTemp.createTemp('budget_tracker_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Initialize mocks
    mockDio = MockDio();
    mockTokenManager = MockTokenManager();

    // Configure token manager mock
    when(mockTokenManager.tokenStream).thenAnswer((_) => Stream.value('mock_token'));

    // Initialize ApiClient with mocks
    apiClient = await ApiClient.initialize(
      baseUrl: 'https://test.api',
      testDio: mockDio,
      tokenManager: mockTokenManager,
    );
  });

  group('ApiClient', () {
    test('get method handles successful response', () async {
      // Arrange
      final mockResponse = dio.Response<Map<String, dynamic>>(
        requestOptions: dio.RequestOptions(path: '/test'),
        data: {'key': 'value'},
        statusCode: 200,
      );

      when(mockDio.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiClient.get<Map<String, dynamic>>('/test');

      // Assert
      expect(result, equals({'key': 'value'}));
      verify(mockDio.get<Map<String, dynamic>>(
        '/test',
        queryParameters: null,
        options: anyNamed('options'),
        cancelToken: null,
      )).called(1);
    });

    test('post method handles successful response', () async {
      // Arrange
      final mockResponse = dio.Response<Map<String, dynamic>>(
        requestOptions: dio.RequestOptions(path: '/test'),
        data: {'result': 'success'},
        statusCode: 201,
      );

      // Use explicit method signature matching
      when(mockDio.post(
        '/test',
        data: {'key': 'value'},
        queryParameters: null,
        options: null,
        cancelToken: null,
        onSendProgress: null,
        onReceiveProgress: null,
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiClient.post<Map<String, dynamic>>(
        '/test', 
        data: {'key': 'value'}
      );

      // Assert
      expect(result, equals({'result': 'success'}));
      verify(mockDio.post(
        '/test',
        data: {'key': 'value'},
        queryParameters: null,
        options: null,
        cancelToken: null,
        onSendProgress: null,
        onReceiveProgress: null,
      )).called(1);
    });

    test('handles Dio exceptions', () async {
      // Arrange
      final dioException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/test'),
        response: dio.Response(
          requestOptions: dio.RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: dio.DioExceptionType.badResponse,
      );

      when(mockDio.get(
        '/test',
        queryParameters: null,
        options: anyNamed('options'),
        cancelToken: null,
      )).thenThrow(dioException);

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  tearDown(() async {
    await Hive.close();
  });

  tearDownAll(() async {
    // Clean up temporary directory
    final tempDir = await Directory.systemTemp.list().firstWhere((element) => element.path.contains('budget_tracker_test_'));
    await tempDir.delete(recursive: true);
  });
}
