import '../core/config/app_config.dart';
import '../core/utils/json_utils.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final int? categoryId;
  final String? categoryName;

  bool get isAvailable => stock > 0;

  factory Product.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    final category = asMap(map['category']);
    final categoryId = readInt(map, 'categoryId') ??
        readInt(map, 'categoriaId') ??
        readInt(category, 'id');
    final categoryName = readString(map, 'categoryName') ??
        readString(map, 'categoria') ??
        readString(category, 'name') ??
        readString(category, 'nombre');
    return Product(
      id: readInt(map, 'id') ?? 0,
      name: readString(map, 'name') ?? readString(map, 'nombre') ?? 'Producto',
      description: readString(map, 'description') ?? readString(map, 'descripcion'),
      price: readDouble(map, 'price') ?? readDouble(map, 'precio') ?? 0,
      stock: readInt(map, 'stock') ?? readInt(map, 'cantidad') ?? 0,
      imageUrl: AppConfig.resolveImageUrl(
        readString(map, 'imageUrl') ??
            readString(map, 'image') ??
            readString(map, 'imagen'),
      ),
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}
