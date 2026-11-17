import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/banner.dart';
import '../models/category.dart';
import '../models/product.dart';

class ProductService {
  ProductService(this._client);

  final ApiClient _client;

  Future<List<BannerItem>> getBanners() async {
    final response = await _client.get('/banners');
    return extractMapList(response)
        .map(BannerItem.fromJson)
        .toList(growable: false);
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/categories');
    return extractMapList(response)
        .map(Category.fromJson)
        .toList(growable: false);
  }

  Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    final query = <String, dynamic>{};
    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) query['search'] = trimmed;
    if (categoryId != null) query['categoryId'] = categoryId;
    final response = await _client.get(
      '/products',
      query: query.isEmpty ? null : query,
    );
    return extractMapList(response)
        .map(Product.fromJson)
        .toList(growable: false);
  }

  Future<Product> getProduct(int id) async {
    return Product.fromJson(await _client.get('/products/$id'));
  }
}
