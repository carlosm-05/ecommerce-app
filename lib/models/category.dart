import '../core/utils/json_utils.dart';

class Category {
  const Category({required this.id, required this.name, this.icon});

  final int id;
  final String name;
  final String? icon;

  factory Category.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return Category(
      id: readInt(map, 'id') ?? 0,
      name: readString(map, 'name') ??
          readString(map, 'nombre') ??
          'Sin categoría',
      icon: readString(map, 'icon'),
    );
  }
}
