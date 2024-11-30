import '../models/user/user_model.dart';
import 'api_provider.dart';

class AuthProvider {
  final ApiProvider _apiProvider;

  AuthProvider(this._apiProvider);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiProvider.post('/auth/login', {
      'email': email,
      'password': password,
    });
    _apiProvider.setAuthToken(response['token']);
    return UserModel.fromJson(response['user']);
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await _apiProvider.post('/auth/register', {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    _apiProvider.setAuthToken(response['token']);
    return UserModel.fromJson(response['user']);
  }

  Future<void> logout() async {
    await _apiProvider.post('/auth/logout', {});
    _apiProvider.setAuthToken('');
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiProvider.get('/auth/me');
    return UserModel.fromJson(response['user']);
  }
}