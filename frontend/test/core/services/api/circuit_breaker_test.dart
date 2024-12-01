import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/core/services/api/circuit_breaker.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  late CircuitBreaker circuitBreaker;

  setUp(() {
    circuitBreaker = CircuitBreaker(
      failureThreshold: 3,
      resetTimeout: const Duration(seconds: 5),
    );
  });

  group('Circuit States', () {
    test('starts in closed state', () {
      expect(circuitBreaker.currentState, CircuitState.closed);
    });

    test('opens after reaching failure threshold', () async {
      // Simulate failures
      for (var i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() => throw Exception('test error'));
        } catch (_) {}
      }

      expect(circuitBreaker.currentState, CircuitState.open);
    });

    test('transitions to half-open state after reset timeout', () {
      fakeAsync((async) async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() => Future.error(Exception('test error')));
          } catch (_) {}
        }
        expect(circuitBreaker.currentState, CircuitState.open);

        // Advance time past reset timeout
        async.elapse(const Duration(seconds: 6));

        expect(circuitBreaker.currentState, CircuitState.halfOpen);
      });
    });
  });

  group('Request Handling', () {
    test('allows requests in closed state', () async {
      final result = await circuitBreaker.execute(() => Future.value(true));
      expect(result, true);
    });

    test('blocks requests in open state', () async {
      // Force circuit to open
      for (var i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() => throw Exception('test error'));
        } catch (_) {}
      }

      expect(
        () => circuitBreaker.execute(() => Future.value(true)),
        throwsA(isA<CircuitBreakerException>()),
      );
    });

    test('allows single request in half-open state', () {
      fakeAsync((async) async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() => Future.error(Exception('test error')));
          } catch (_) {}
        }

        // Advance time to transition to half-open
        async.elapse(const Duration(seconds: 6));

        // Should allow one request
        await circuitBreaker.execute(() => Future.value(true));
        expect(circuitBreaker.currentState, CircuitState.closed);
      });
    });
  });

  group('State Transitions', () {
    test('closes circuit after successful request in half-open state', () {
      fakeAsync((async) async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() => Future.error(Exception('test error')));
          } catch (_) {}
        }

        // Advance time to transition to half-open
        async.elapse(const Duration(seconds: 6));

        // Execute successful request
        await circuitBreaker.execute(() => Future.value(true));

        expect(circuitBreaker.currentState, CircuitState.closed);
      });
    });

    test('reopens circuit after failure in half-open state', () {
      fakeAsync((async) async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() => Future.error(Exception('test error')));
          } catch (_) {}
        }

        // Advance time to transition to half-open
        async.elapse(const Duration(seconds: 6));

        // Execute failing request
        try {
          await circuitBreaker.execute(() => Future.error(Exception('test error')));
        } catch (_) {}

        expect(circuitBreaker.currentState, CircuitState.open);
      });
    });
  });

  group('Failure Counting', () {
    test('resets failure count after successful request', () async {
      // Record some failures
      try {
        await circuitBreaker.execute(() => Future.error(Exception('test error')));
      } catch (_) {}
      try {
        await circuitBreaker.execute(() => Future.error(Exception('test error')));
      } catch (_) {}

      // Record success
      await circuitBreaker.execute(() => Future.value(true));

      expect(circuitBreaker.failureCount, 0);
      expect(circuitBreaker.currentState, CircuitState.closed);
    });

    test('maintains failure count across requests', () async {
      // Record failures up to threshold - 1
      for (var i = 0; i < 2; i++) {
        try {
          await circuitBreaker.execute(() => Future.error(Exception('test error')));
        } catch (_) {}
      }

      expect(circuitBreaker.failureCount, 2);
      expect(circuitBreaker.currentState, CircuitState.closed);

      // One more failure should open the circuit
      try {
        await circuitBreaker.execute(() => Future.error(Exception('test error')));
      } catch (_) {}

      expect(circuitBreaker.currentState, CircuitState.open);
    });
  });
}
