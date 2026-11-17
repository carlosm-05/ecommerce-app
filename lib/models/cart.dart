import '../core/config/app_config.dart';
import '../core/utils/json_utils.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.stock,
    required this.lineTotal,
    this.imageUrl,
  });

  final int id;
  final int productId;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final int stock;
  final double lineTotal;

  factory CartItem.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return CartItem(
      id: readInt(map, 'id') ?? 0,
      productId: readInt(map, 'productId') ?? 0,
      name: readString(map, 'name') ?? 'Producto',
      imageUrl: AppConfig.resolveImageUrl(readString(map, 'imageUrl')),
      unitPrice: readDouble(map, 'unitPrice') ?? 0,
      quantity: readInt(map, 'quantity') ?? 0,
      stock: readInt(map, 'stock') ?? 0,
      lineTotal: readDouble(map, 'lineTotal') ?? 0,
    );
  }
}

class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.shipping,
    required this.total,
  });

  final int itemCount;
  final double subtotal;
  final double taxRate;
  final double tax;
  final double shipping;
  final double total;

  static const CartSummary empty = CartSummary(
    itemCount: 0,
    subtotal: 0,
    taxRate: 0,
    tax: 0,
    shipping: 0,
    total: 0,
  );

  factory CartSummary.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return CartSummary(
      itemCount: readInt(map, 'itemCount') ?? 0,
      subtotal: readDouble(map, 'subtotal') ?? 0,
      taxRate: readDouble(map, 'taxRate') ?? 0,
      tax: readDouble(map, 'tax') ?? 0,
      shipping: readDouble(map, 'shipping') ?? 0,
      total: readDouble(map, 'total') ?? 0,
    );
  }
}

class Cart {
  const Cart({required this.items, required this.summary});

  final List<CartItem> items;
  final CartSummary summary;

  static const Cart empty = Cart(items: <CartItem>[], summary: CartSummary.empty);

  factory Cart.fromJson(dynamic json) {
    final root = unwrapMap(asMap(json));
    final items = extractMapList(root['items'])
        .map(CartItem.fromJson)
        .toList(growable: false);
    return Cart(
      items: items,
      summary: CartSummary.fromJson(root['summary']),
    );
  }
}
