import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<Product> _product;
  int _quantity = 1;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _product = ref.read(productServiceProvider).getProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: FutureBuilder<Product>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudo cargar el producto.'),
                  TextButton(
                    onPressed: () => setState(
                      () => _product =
                          ref.read(productServiceProvider).getProduct(widget.productId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return _productDetails(snapshot.data!);
        },
      ),
    );
  }

  Widget _productDetails(Product product) {
    final unavailable = product.stock < 1;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 300,
            child: AppNetworkImage(url: product.imageUrl),
          ),
        ),
        const SizedBox(height: 20),
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
        if (product.categoryName != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            product.categoryName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          Formatters.currency(product.price),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (product.stock < 5)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              unavailable ? 'Agotado' : 'Quedan ${product.stock}',
              style: TextStyle(
                color: unavailable ? Colors.red : Colors.deepOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(product.description ?? 'Sin descripción disponible.'),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Disminuir cantidad',
              onPressed:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Aumentar cantidad',
              onPressed: _quantity < product.stock
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: unavailable || _isAdding
              ? null
              : () => _addToCart(product),
          icon: _isAdding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shopping_cart_outlined),
          label: const Text('Agregar al carrito'),
        ),
      ],
    );
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _isAdding = true);
    try {
      await ref.read(cartProvider).addItem(product.id, _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Agregado al carrito'),
            action: SnackBarAction(
              label: 'Ver carrito',
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
    } catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
