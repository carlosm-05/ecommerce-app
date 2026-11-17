import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce/models/cart.dart';
import 'package:ecommerce/models/product.dart';

void main() {
  group('API models', () {
    test('parses numeric product prices as doubles', () {
      final product = Product.fromJson(<String, dynamic>{
        'id': 12,
        'name': 'Producto',
        'price': 249900.0,
        'stock': 3,
      });

      expect(product.price, 249900.0);
      expect(product.stock, 3);
    });

    test('uses the server-provided cart summary without recalculating it', () {
      final cart = Cart.fromJson(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 81,
            'productId': 12,
            'name': 'Producto',
            'unitPrice': 100000,
            'quantity': 2,
            'stock': 5,
            'lineTotal': 200000,
          },
        ],
        'summary': <String, dynamic>{
          'itemCount': 2,
          'subtotal': 200000,
          'taxRate': 0.19,
          'tax': 38000,
          'shipping': 0,
          'total': 238000,
        },
      });

      expect(cart.items.single.id, 81);
      expect(cart.summary.itemCount, 2);
      expect(cart.summary.tax, 38000);
      expect(cart.summary.total, 238000);
    });
  });
}
