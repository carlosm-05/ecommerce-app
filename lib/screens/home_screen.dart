import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/banner.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  final _bannerController = PageController();
  late Future<List<BannerItem>> _banners;
  late Future<List<Category>> _categories;
  late Future<List<Product>> _products;
  Timer? _searchDebounce;
  Timer? _bannerTimer;
  int? _categoryId;
  int _bannerIndex = 0;
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    final service = ref.read(productServiceProvider);
    _banners = service.getBanners();
    _categories = service.getCategories();
    _products = service.getProducts();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerController.hasClients) return;
      _bannerPage++;
      _bannerController.animateToPage(
        _bannerPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bannerTimer?.cancel();
    _search.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _reloadProducts() {
    setState(() {
      _products = ref.read(productServiceProvider).getProducts(
            search: _search.text,
            categoryId: _categoryId,
          );
    });
  }

  void _searchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      _reloadProducts,
    );
  }

  Future<void> _refresh() async {
    final service = ref.read(productServiceProvider);
    setState(() {
      _banners = service.getBanners();
      _categories = service.getCategories();
      _products = service.getProducts(
        search: _search.text,
        categoryId: _categoryId,
      );
    });
    await Future.wait<Object?>(<Future<Object?>>[
      _banners,
      _categories,
      _products,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _bannerCarousel()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _search,
                onChanged: _searchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar productos',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _search.clear();
                            _reloadProducts();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _categoryChips()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Text(
                'Productos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 40),
                      const Text('No se pudieron cargar los productos.'),
                      TextButton(
                        onPressed: _reloadProducts,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final products = snapshot.data ?? <Product>[];
              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: emptyState(context, 'No encontramos productos'),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(
                      product: products[index],
                      onTap: () =>
                          context.push('/products/${products[index].id}'),
                    ),
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.67,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bannerCarousel() {
    return FutureBuilder<List<BannerItem>>(
      future: _banners,
      builder: (context, snapshot) {
        final banners = snapshot.data ?? <BannerItem>[];
        if (snapshot.hasError || banners.isEmpty) {
          return const SizedBox(height: 20);
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (index) => setState(() {
                      _bannerIndex = index % banners.length;
                    }),
                    itemBuilder: (context, index) => Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        AppNetworkImage(
                          url: banners[index % banners.length].imageUrl,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: <Color>[
                                Color(0xB8000000),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        if (banners[index % banners.length].title != null)
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Text(
                              banners[index % banners.length].title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (banners.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      banners.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _bannerIndex == index ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _bannerIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 50,
      child: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(
                  () => _categories =
                      ref.read(productServiceProvider).getCategories(),
                ),
                child: const Text('No se cargaron las categorías · Reintentar'),
              ),
            );
          }
          final categories = snapshot.data ?? <Category>[];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              _categoryChip('Todos', null, null),
              ...categories.map(
                (category) => _categoryChip(
                  category.name,
                  category.id,
                  _categoryIcon(category.icon),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryChip(String label, int? id, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: _categoryId == id,
        onSelected: (_) {
          setState(() => _categoryId = id);
          _reloadProducts();
        },
      ),
    );
  }

  IconData? _categoryIcon(String? icon) {
    switch (icon) {
      case 'checkroom':
        return Icons.checkroom;
      case 'devices':
        return Icons.devices;
      case 'chair':
        return Icons.chair;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'spa':
        return Icons.spa;
      default:
        return Icons.category_outlined;
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AppNetworkImage(url: product.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.currency(product.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
