import '../models/user/user_model.dart';
import 'api_provider.dart';
import '../../core/utils/logger_utils.dart';

class AuthProvider {
  final ApiProvider _apiProvider;

  AuthProvider(this._apiProvider);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiProvider.post('/auth/login', {
      'email': email,
      'password': password,
    });
    try {
      _apiProvider.setAuthToken(response['token']);
      LoggerUtils.info('Authorization token set: ${response['token']}');
    } catch (e) {
      LoggerUtils.error('Failed to set authorization token', e);
      throw Exception('Token setting failed');
    }
    return UserModel.fromJson(response['user']);
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await _apiProvider.post('/auth/register', {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    try {
      _apiProvider.setAuthToken(response['token']);
      LoggerUtils.info('Authorization token set: ${response['token']}');
    } catch (e) {
      LoggerUtils.error('Failed to set authorization token', e);
      throw Exception('Token setting failed');
    }
    return UserModel.fromJson(response['user']);
  }

  Future<void> logout() async {
    await _apiProvider.post('/auth/logout', {});
    try {
      _apiProvider.setAuthToken('');
      LoggerUtils.info('Authorization token cleared');
    } catch (e) {
      LoggerUtils.error('Failed to clear authorization token', e);
      throw Exception('Token clearing failed');
    }
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiProvider.get('/auth/me');
    return UserModel.fromJson(response['user']);
  }
}