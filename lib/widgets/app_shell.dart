import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../providers/app_providers.dart';
import 'app_widgets.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cartProvider).load();
    });
  }

  int get _selectedIndex {
    if (widget.location == '/cart') return 1;
    if (widget.location == '/profile') return 2;
    return 0;
  }

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return 'Mi carrito';
      case 2:
        return 'Mi perfil';
      default:
        return 'Mi tienda';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final cart = ref.watch(cartProvider).cart;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              if (user != null)
                UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    child: user.avatarUrl == null
                        ? Text(user.initials)
                        : ClipOval(
                            child: AppNetworkImage(
                              url: AppConfig.resolveImageUrl(user.avatarUrl),
                              width: 52,
                              height: 52,
                            ),
                          ),
                  ),
                  accountName: Text(user.displayName),
                  accountEmail: Text(user.email),
                ),
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => _navigate('/home'),
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'Mis pedidos',
                onTap: () => _navigate('/orders'),
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => _navigate('/profile'),
              ),
              const Spacer(),
              const Divider(),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          context.go(<String>['/home', '/cart', '/profile'][index]);
        },
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: cart.summary.itemCount == 0
                ? const Icon(Icons.shopping_cart_outlined)
                : Badge(
                    label: Text('${cart.summary.itemCount}'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _navigate(String location) {
    Navigator.pop(context);
    context.go(location);
  }

  Future<void> _signOut() async {
    Navigator.pop(context);
    String? message;
    try {
      message = await ref.read(authProvider).signOut();
    } finally {
      if (mounted) context.go('/login');
    }
    if (mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      );
}
