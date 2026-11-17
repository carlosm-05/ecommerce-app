import '../core/utils/json_utils.dart';

class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get displayName =>
      fullName?.trim().isNotEmpty == true ? fullName! : '$firstName $lastName'.trim();

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory User.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return User(
      id: readInt(map, 'id') ?? 0,
      firstName: readString(map, 'firstName') ?? '',
      lastName: readString(map, 'lastName') ?? '',
      fullName: readString(map, 'fullName'),
      username: readString(map, 'username') ?? '',
      email: readString(map, 'email') ?? '',
      avatarUrl: readString(map, 'avatarUrl'),
      createdAt: readDate(map, 'createdAt'),
    );
  }
}
