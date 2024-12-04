import '../../data/providers/api_provider.dart';
import 'dio_client.dart';

class DioApiAdapter extends ApiProvider {
  final DioClient _dioClient;

  DioApiAdapter(this._dioClient) : super(baseUrl: _dioClient.baseUrl);

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _dioClient.get(
      endpoint,
      queryParameters: queryParameters?.map((key, value) => MapEntry(key, value)),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      endpoint,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      endpoint,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _dioClient.delete(endpoint);
    return response.data as Map<String, dynamic>;
  }

  @override
  void setAuthToken(String token) {
    // Token handling is managed by DioClient's AuthInterceptor
  }
}
