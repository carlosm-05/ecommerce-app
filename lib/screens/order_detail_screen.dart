import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Future<Order> _order;

  @override
  void initState() {
    super.initState();
    _order = ref.read(orderServiceProvider).getOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
      body: FutureBuilder<Order>(
        future: _order,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudo cargar el pedido.'),
                  TextButton(
                    onPressed: () => setState(
                      () => _order = ref
                          .read(orderServiceProvider)
                          .getOrder(widget.orderId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return _content(snapshot.data!);
        },
      ),
    );
  }

  Widget _content(Order order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Estado: ${order.status}'),
                const SizedBox(height: 6),
                Text('Fecha: ${Formatters.dateTime(order.createdAt)}'),
                if (order.shippingAddress?.isNotEmpty == true)
                  Text('Dirección: ${order.shippingAddress}'),
                if (order.paymentMethod?.isNotEmpty == true)
                  Text('Pago: ${order.paymentMethod}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => _OrderItemTile(item: item),
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Subtotal',
          value: Formatters.currency(order.subtotal),
        ),
        _SummaryRow(label: 'IVA', value: Formatters.currency(order.tax)),
        _SummaryRow(
          label: 'Envío',
          value: order.shipping == 0 ? 'Gratis' : Formatters.currency(order.shipping),
        ),
        const Divider(),
        _SummaryRow(
          label: 'Total',
          value: Formatters.currency(order.total),
          emphasized: true,
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(url: item.imageUrl, width: 52, height: 52),
        ),
        title: Text(item.productName),
        subtitle: Text(
          '${item.quantity} × ${Formatters.currency(item.unitPrice)}',
        ),
        trailing: Text(Formatters.currency(item.lineTotal)),
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
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
