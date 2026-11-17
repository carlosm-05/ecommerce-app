import '../core/config/app_config.dart';
import '../core/utils/json_utils.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  final int productId;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return OrderItem(
      productId: readInt(map, 'productId') ?? 0,
      productName: readString(map, 'productName') ?? 'Producto',
      imageUrl: AppConfig.resolveImageUrl(readString(map, 'imageUrl')),
      unitPrice: readDouble(map, 'unitPrice') ?? 0,
      quantity: readInt(map, 'quantity') ?? 0,
      lineTotal: readDouble(map, 'lineTotal') ?? 0,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.itemCount,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.items,
    this.createdAt,
    this.shippingAddress,
    this.paymentMethod,
  });

  final int id;
  final String status;
  final DateTime? createdAt;
  final int itemCount;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String? shippingAddress;
  final String? paymentMethod;
  final List<OrderItem> items;

  factory Order.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return Order(
      id: readInt(map, 'id') ?? 0,
      status: readString(map, 'status') ?? 'PENDIENTE',
      createdAt: readDate(map, 'createdAt'),
      itemCount: readInt(map, 'itemCount') ?? 0,
      subtotal: readDouble(map, 'subtotal') ?? 0,
      tax: readDouble(map, 'tax') ?? 0,
      shipping: readDouble(map, 'shipping') ?? 0,
      total: readDouble(map, 'total') ?? 0,
      shippingAddress: readString(map, 'shippingAddress'),
      paymentMethod: readString(map, 'paymentMethod'),
      items: extractMapList(map['items'])
          .map(OrderItem.fromJson)
          .toList(growable: false),
    );
  }
}
