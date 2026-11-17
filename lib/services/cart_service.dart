import '../core/network/api_client.dart';
import '../models/cart.dart';
import '../models/order.dart';

class CartService {
  CartService(this._client);

  final ApiClient _client;

  Future<Cart> getCart() async => Cart.fromJson(await _client.get('/cart'));

  Future<Cart> addItem({
    required int productId,
    int quantity = 1,
  }) async {
    final response = await _client.post(
      '/cart/items',
      body: <String, dynamic>{'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(response);
  }

  Future<Cart> updateItemQuantity({
    required int itemId,
    required int quantity,
  }) async {
    final response = await _client.patch(
      '/cart/items/$itemId',
      body: <String, dynamic>{'quantity': quantity},
    );
    return Cart.fromJson(response);
  }

  Future<Cart> removeItem(int itemId) async {
    return Cart.fromJson(await _client.delete('/cart/items/$itemId'));
  }

  Future<Cart> clear() async => Cart.fromJson(await _client.delete('/cart'));

  Future<Order> checkout({
    String? shippingAddress,
    String? paymentMethod,
  }) async {
    final response = await _client.post(
      '/orders/checkout',
      body: <String, dynamic>{
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      },
    );
    return Order.fromJson(response);
  }
}
