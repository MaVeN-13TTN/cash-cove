import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/core/services/api/request_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'dart:async';

@GenerateMocks([Dio])
import 'request_manager_test.mocks.dart';

void main() {
  late RequestManager requestManager;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    requestManager = RequestManager(
      dio: mockDio,
      batchWindow: const Duration(milliseconds: 50),
      maxBatchSize: 3,
    );

    // Set up default get method stub
    when(mockDio.get(
      any,
      data: anyNamed('data'),
      queryParameters: anyNamed('queryParameters'),
      options: anyNamed('options'),
      cancelToken: anyNamed('cancelToken'),
      onReceiveProgress: anyNamed('onReceiveProgress'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      data: {},
    ));

    // Set up default request method stub
    when(mockDio.request(
      any,
      data: anyNamed('data'),
      queryParameters: anyNamed('queryParameters'),
      options: anyNamed('options'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      data: {},
    ));
  });

  group('Request Queue Management', () {
    test('queues and executes requests in order', () async {
      final results = <int>[];
      
      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((invocation) async {
        final index = int.parse(invocation.positionalArguments[0]);
        results.add(index);
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: {'index': index},
        );
      });

      // Schedule requests
      final futures = List.generate(3, (i) => 
        requestManager.scheduleRequest(
          endpoint: '$i',
          method: 'GET',
        ),
      );

      // Wait for all requests to complete
      await Future.wait(futures);

      // Assert requests were executed in order
      expect(results, [0, 1, 2]);
    });

    test('handles request priorities', () async {
      final results = <String>[];
      
      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((invocation) async {
        results.add(invocation.positionalArguments[0]);
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: {'endpoint': invocation.positionalArguments[0]},
        );
      });

      // Queue low priority request first
      final lowPriorityFuture = requestManager.scheduleRequest(
        endpoint: 'low',
        method: 'GET',
        priority: RequestPriority.low,
      );

      // Queue high priority request second
      final highPriorityFuture = requestManager.scheduleRequest(
        endpoint: 'high',
        method: 'GET',
        priority: RequestPriority.high,
      );

      await Future.wait([lowPriorityFuture, highPriorityFuture]);

      // High priority request should be executed first
      expect(results, ['high', 'low']);
    });

    test('handles concurrent requests within batch size', () async {
      final results = <int>[];
      final completer = Completer<void>();

      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((invocation) async {
        await completer.future;
        final index = int.parse(invocation.positionalArguments[0]);
        results.add(index);
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: {'index': index},
        );
      });

      // Schedule more requests than batch size
      final futures = List.generate(5, (i) => 
        requestManager.scheduleRequest(
          endpoint: '$i',
          method: 'GET',
        ),
      );

      // Let the first batch complete
      completer.complete();

      await Future.wait(futures);

      expect(results.length, 5);
      // First batch should be processed in order
      expect(results.sublist(0, 3), [0, 1, 2]);
    });
  });

  group('Error Handling', () {
    test('handles request failures', () async {
      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Simulated failure',
      ));

      expect(
        () => requestManager.scheduleRequest(
          endpoint: 'test',
          method: 'GET',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('handles network errors', () async {
      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      expect(
        () => requestManager.scheduleRequest(
          endpoint: 'test',
          method: 'GET',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Queue Metrics', () {
    test('tracks queue size', () async {
      final completer = Completer<void>();

      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) => completer.future.then((_) => 
        Response(requestOptions: RequestOptions(path: ''))
      ));

      // Schedule multiple requests
      final futures = List.generate(5, (i) => 
        requestManager.scheduleRequest(
          endpoint: '$i',
          method: 'GET',
        ),
      );

      // Queue size should reflect pending requests
      expect(requestManager.queueSize, 5);

      // Complete all requests
      completer.complete();
      await Future.wait(futures);

      // Queue should be empty
      expect(requestManager.queueSize, 0);
    });

    test('tracks batched request count', () async {
      when(mockDio.get(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) async => 
        Response(requestOptions: RequestOptions(path: ''))
      );

      // Schedule multiple requests
      final futures = List.generate(5, (i) => 
        requestManager.scheduleRequest(
          endpoint: '$i',
          method: 'GET',
        ),
      );

      await Future.wait(futures);

      // All requests should be processed
      expect(requestManager.batchedRequestCount, 5);
    });
  });
}
