import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert'; // Added import for jsonDecode

class WebSocketService {
  late WebSocketChannel _channel;
  final _budgetUpdatesController = BehaviorSubject<Map<String, dynamic>>();
  final _transactionUpdatesController = BehaviorSubject<Map<String, dynamic>>();
  final _notificationUpdatesController =
      BehaviorSubject<Map<String, dynamic>>();

  Stream<Map<String, dynamic>> get budgetUpdates =>
      _budgetUpdatesController.stream;
  Stream<Map<String, dynamic>> get transactionUpdates =>
      _transactionUpdatesController.stream;
  Stream<Map<String, dynamic>> get notificationUpdates =>
      _notificationUpdatesController.stream;

  void connect(String token) {
    final wsUrl = Uri.parse('ws://your-api-url/ws?token=$token');
    _channel = WebSocketChannel.connect(wsUrl);
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'budget.updated':
          _budgetUpdatesController.add(data['payload']);
          break;
        case 'transaction.created':
          _transactionUpdatesController.add(data['payload']);
          break;
        case 'notification.created':
          _notificationUpdatesController.add(data['payload']);
          break;
      }
    }, onError: (error) {
      // Implement reconnection logic
      print('WebSocket error: $error');
    });
  }

  void disconnect() {
    _channel.sink.close();
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  void dispose() {
    _channel.sink.close();
    _budgetUpdatesController.close();
    _transactionUpdatesController.close();
    _notificationUpdatesController.close();
  }
}
