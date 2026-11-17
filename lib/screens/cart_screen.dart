import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cartProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: state.load,
            child: state.isLoading && state.cart.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[loadingIndicator(height: 480)],
                  )
                : state.cart.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          const SizedBox(height: 120),
                          if (state.errorMessage != null) ...<Widget>[
                            Center(child: Text(state.errorMessage!)),
                            Center(
                              child: TextButton(
                                onPressed: state.load,
                                child: const Text('Reintentar'),
                              ),
                            ),
                          ] else ...<Widget>[
                            emptyState(context, 'Tu carrito está vacío'),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: FilledButton(
                                onPressed: () => context.go('/home'),
                                child: const Text('Ver productos'),
                              ),
                            ),
                          ],
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: state.cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.cart.items[index];
                          return _CartItemTile(
                            item: item,
                            enabled: !state.isUpdating,
                            onDecrease: () => _decrease(item),
                            onIncrease: () => _setQuantity(item, item.quantity + 1),
                            onRemove: () => _remove(item),
                          );
                        },
                      ),
          ),
        ),
        if (state.cart.items.isNotEmpty) _summary(state.cart.summary, state),
      ],
    );
  }

  Widget _summary(CartSummary summary, CartController state) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _SummaryRow(
                label: 'Subtotal',
                value: Formatters.currency(summary.subtotal),
              ),
              _SummaryRow(
                label: 'IVA (${(summary.taxRate * 100).round()} %)',
                value: Formatters.currency(summary.tax),
              ),
              _SummaryRow(
                label: 'Envío',
                value: summary.shipping == 0
                    ? 'Gratis'
                    : Formatters.currency(summary.shipping),
              ),
              const Divider(height: 18),
              _SummaryRow(
                label: 'Total',
                value: Formatters.currency(summary.total),
                emphasized: true,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: state.isUpdating ? null : _checkout,
                child: state.isUpdating
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Proceder al pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decrease(CartItem item) async {
    if (item.quantity == 1) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text('¿Quieres quitar "${item.name}" del carrito?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (remove != true) return;
      return _remove(item);
    }
    return _setQuantity(item, item.quantity - 1);
  }

  Future<void> _setQuantity(CartItem item, int quantity) async {
    try {
      await ref.read(cartProvider).setQuantity(item.id, quantity);
    } catch (error) {
      if (mounted) showApiError(context, error);
    }
  }

  Future<void> _remove(CartItem item) async {
    try {
      await ref.read(cartProvider).removeItem(item.id);
    } catch (error) {
      if (mounted) showApiError(context, error);
    }
  }

  Future<void> _checkout() async {
    final details = await showDialog<_CheckoutDetails>(
      context: context,
      builder: (context) => const _CheckoutDialog(),
    );
    if (details == null || !mounted) return;
    try {
      final order = await ref.read(cartProvider).checkout(
            shippingAddress: details.address,
            paymentMethod: details.paymentMethod,
          );
      if (mounted) await _showSuccess(order);
    } catch (error) {
      if (mounted) showApiError(context, error);
    }
  }

  Future<void> _showSuccess(Order order) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 56),
        title: const Text('¡Compra exitosa!'),
        content: Text('Pedido #${order.id}'),
        actions: <Widget>[
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/orders/${order.id}');
            },
            child: const Text('Ver pedido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppNetworkImage(
                url: item.imageUrl,
                width: 76,
                height: 76,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(Formatters.currency(item.unitPrice)),
                  Row(
                    children: <Widget>[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: enabled ? onDecrease : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            enabled && item.quantity < item.stock ? onIncrease : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _CheckoutDetails {
  const _CheckoutDetails(this.address, this.paymentMethod);

  final String? address;
  final String? paymentMethod;
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _address = TextEditingController();
  String _paymentMethod = 'TARJETA';

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar compra'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _address,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Dirección de envío (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'TARJETA', child: Text('Tarjeta simulada')),
                DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                DropdownMenuItem(
                  value: 'TRANSFERENCIA',
                  child: Text('Transferencia'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _CheckoutDetails(
              _address.text.trim().isEmpty ? null : _address.text.trim(),
              _paymentMethod,
            ),
          ),
          child: const Text('Confirmar compra'),
        ),
      ],
    );
  }
}
