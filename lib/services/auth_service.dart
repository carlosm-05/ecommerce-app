import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(String usernameOrEmail, String password) async {
    final response = await _client.post(
      '/auth/login',
      body: <String, dynamic>{
        'usernameOrEmail': usernameOrEmail.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<User> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    return User.fromJson(response);
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }

  Future<bool> checkUsername(String username) async {
    final response = await _client.get(
      '/auth/check-username',
      query: <String, dynamic>{'username': username.trim()},
    );
    return readBool(asMap(response), 'available') ?? false;
  }

  Future<bool> checkEmail(String email) async {
    final response = await _client.get(
      '/auth/check-email',
      query: <String, dynamic>{'email': email.trim()},
    );
    return readBool(asMap(response), 'available') ?? false;
  }

  Future<String> forgotPassword(String email) async {
    final response = await _client.post(
      '/auth/forgot-password',
      body: <String, dynamic>{'email': email.trim()},
    );
    return readString(unwrapMap(asMap(response)), 'message') ??
        'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña';
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _client.post(
      '/auth/reset-password',
      body: <String, dynamic>{
        'token': token.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return readString(unwrapMap(asMap(response)), 'message') ??
        'Contraseña actualizada';
  }
}
