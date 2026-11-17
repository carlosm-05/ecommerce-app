import '../core/utils/json_utils.dart';
import 'user.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String token;
  final String tokenType;
  final int expiresIn;
  final User user;

  factory AuthResponse.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return AuthResponse(
      token: readString(map, 'token') ?? '',
      tokenType: readString(map, 'tokenType') ?? 'Bearer',
      expiresIn: readInt(map, 'expiresIn') ?? 0,
      user: User.fromJson(map['user']),
    );
  }
}
