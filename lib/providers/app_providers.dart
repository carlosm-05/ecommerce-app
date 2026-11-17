import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';

final Provider<TokenStorage> tokenStorageProvider =
    Provider<TokenStorage>((ref) => TokenStorage());

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
  client.onUnauthorized = () => ref.read(authProvider).handleUnauthorized();
  return client;
});

final Provider<AuthService> authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));
final Provider<ProductService> productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(apiClientProvider)),
);
final Provider<CartService> cartServiceProvider =
    Provider<CartService>((ref) => CartService(ref.watch(apiClientProvider)));
final Provider<OrderService> orderServiceProvider =
    Provider<OrderService>((ref) => OrderService(ref.watch(apiClientProvider)));
final Provider<UserService> userServiceProvider =
    Provider<UserService>((ref) => UserService(ref.watch(apiClientProvider)));

final ChangeNotifierProvider<AuthController> authProvider =
    ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    authService: ref.watch(authServiceProvider),
    userService: ref.watch(userServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
  unawaited(controller.restoreSession());
  return controller;
});

final ChangeNotifierProvider<CartController> cartProvider =
    ChangeNotifierProvider<CartController>((ref) {
  return CartController(ref.watch(cartServiceProvider));
});

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    required UserService userService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _userService = userService,
        _tokenStorage = tokenStorage;

  final AuthService _authService;
  final UserService _userService;
  final TokenStorage _tokenStorage;

  User? user;
  bool isLoading = true;
  String? startupMessage;

  Future<void> restoreSession() async {
    try {
      final token = await _tokenStorage.readToken();
      if (token != null) user = await _userService.getMe();
    } on ApiException catch (error) {
      startupMessage = error.message;
      await _tokenStorage.deleteToken();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String usernameOrEmail, String password) async {
    final response = await _authService.login(usernameOrEmail, password);
    await _tokenStorage.saveToken(response.token);
    user = response.user;
    startupMessage = null;
    isLoading = false;
    notifyListeners();
  }

  Future<User> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _authService.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<String?> signOut() async {
    String? logoutMessage;
    try {
      await _authService.logout();
    } on ApiException catch (error) {
      logoutMessage = error.message;
    } finally {
      user = null;
      isLoading = false;
      await _tokenStorage.deleteToken();
      notifyListeners();
    }
    return logoutMessage;
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    String? avatarUrl,
  }) async {
    final updated = await _userService.updateMe(
      firstName: firstName,
      lastName: lastName,
      username: username,
      avatarUrl: avatarUrl,
    );
    user = updated;
    notifyListeners();
    return updated;
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _userService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  void handleUnauthorized() {
    user = null;
    isLoading = false;
    notifyListeners();
  }
}

class CartController extends ChangeNotifier {
  CartController(this._service);

  final CartService _service;

  Cart cart = Cart.empty;
  bool isLoading = false;
  bool isUpdating = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cart = await _service.getCart();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(int productId, int quantity) async {
    await _update(() async {
      cart = await _service.addItem(productId: productId, quantity: quantity);
    });
  }

  Future<void> setQuantity(int itemId, int quantity) async {
    await _update(() async {
      cart = await _service.updateItemQuantity(
        itemId: itemId,
        quantity: quantity,
      );
    });
  }

  Future<void> removeItem(int itemId) async {
    await _update(() async {
      cart = await _service.removeItem(itemId);
    });
  }

  Future<Order> checkout({
    String? shippingAddress,
    String? paymentMethod,
  }) async {
    late Order order;
    await _update(() async {
      order = await _service.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );
      cart = Cart.empty;
    });
    return order;
  }

  Future<void> _update(Future<void> Function() action) async {
    isUpdating = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }
}
