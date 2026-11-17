import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/order.dart';

class OrderService {
  OrderService(this._client);

  final ApiClient _client;

  Future<List<Order>> getOrders() async {
    final response = await _client.get('/orders');
    return extractMapList(response)
        .map(Order.fromJson)
        .toList(growable: false);
  }

  Future<Order> getOrder(int id) async {
    return Order.fromJson(await _client.get('/orders/$id'));
  }
}
