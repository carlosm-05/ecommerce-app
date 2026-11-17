import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/user.dart';

class UserService {
  UserService(this._client);

  final ApiClient _client;

  Future<User> getMe() async => User.fromJson(await _client.get('/users/me'));

  Future<User> updateMe({
    required String firstName,
    required String lastName,
    required String username,
    String? avatarUrl,
  }) async {
    final response = await _client.put(
      '/users/me',
      body: <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim(),
        'avatarUrl': avatarUrl,
      },
    );
    return User.fromJson(response);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _client.put(
      '/users/me/password',
      body: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return readString(unwrapMap(asMap(response)), 'message') ??
        'Contraseña actualizada correctamente';
  }
}
