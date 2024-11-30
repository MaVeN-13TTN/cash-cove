import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  ApiProvider({required this.baseUrl});

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters,
    );
    final response = await http.get(
      uri,
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    }
    throw _handleError(response);
  }

  Exception _handleError(http.Response response) {
    final body = json.decode(response.body);
    final message = body['message'] ?? 'An error occurred';
    switch (response.statusCode) {
      case 400:
        return Exception('Bad request: $message');
      case 401:
        return Exception('Unauthorized: $message');
      case 403:
        return Exception('Forbidden: $message');
      case 404:
        return Exception('Not found: $message');
      default:
        return Exception('Server error: $message');
    }
  }
}
