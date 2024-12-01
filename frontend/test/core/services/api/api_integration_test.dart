import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:budget_tracker/core/services/api/api_client.dart';
import 'package:budget_tracker/core/exceptions/api_exception.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../../../mocks/mocks.mocks.dart';

void main() {
  late MockDio dio;
  late MockTokenManager tokenManager;
  late ApiClient apiClient;
  late Directory tempDir;

  // Create a mock method channel handler
  Future<dynamic> mockPathProviderHandler(MethodCall methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      return tempDir.path;
    }
    return null;
  }

  setUpAll(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('budget_tracker_test_');

    // Mock path_provider method
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Stub the getApplicationDocumentsDirectory method
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    
    // Use the recommended method for mocking method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, mockPathProviderHandler);
  });

  setUp(() async {
    // Mock Hive initialization to prevent actual Hive box opening
    await Hive.initFlutter(tempDir.path);

    dio = MockDio();
    tokenManager = MockTokenManager();

    // Configure token manager mock
    when(tokenManager.tokenStream).thenAnswer((_) => Stream.value('mock_token'));

    apiClient = await ApiClient.initialize(
      baseUrl: 'https://test.api',
      testDio: dio,
      tokenManager: tokenManager,
    );
  });

  group('ApiClient Integration', () {
    test('handles network errors', () async {
      when(dio.get<dynamic>(
        captureAny, 
        options: captureAnyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 503,
        ),
      ));

      expect(
        () => apiClient.get('/test'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503)),
      );
    });

    test('handles invalid responses', () async {
      when(dio.post<dynamic>(
        captureAny, 
        data: captureAnyNamed('data'), 
        options: captureAnyNamed('options'),
        queryParameters: captureAnyNamed('queryParameters'),
        cancelToken: captureAnyNamed('cancelToken'),
        onSendProgress: captureAnyNamed('onSendProgress'),
        onReceiveProgress: captureAnyNamed('onReceiveProgress'),
      )).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/test'),
            data: {'invalid': 'response'},
            statusCode: 400,
          ));

      expect(
        () => apiClient.post('/test', data: {'data': 'test'}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  tearDown(() async {
    await Hive.close();
  });

  tearDownAll(() async {
    // Clear the mock method handler
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    
    // Clean up temporary directory
    await tempDir.delete(recursive: true);
  });
}
