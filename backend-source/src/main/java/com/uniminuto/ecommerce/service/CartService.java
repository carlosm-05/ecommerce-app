package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.dto.CartDtos.*;
import com.uniminuto.ecommerce.entity.CartItem;
import com.uniminuto.ecommerce.entity.Product;
import com.uniminuto.ecommerce.exception.ApiException;
import com.uniminuto.ecommerce.repository.CartItemRepository;
import com.uniminuto.ecommerce.repository.ProductRepository;
import com.uniminuto.ecommerce.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Carrito guardado en la base de datos (por usuario). El resumen del pedido
 * (subtotal, IVA, envío y total) siempre lo calcula el servidor.
 */
@Service
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final BigDecimal taxRate;
    private final BigDecimal shippingCost;
    private final BigDecimal freeShippingFrom;

    public CartService(CartItemRepository cartItemRepository,
                       ProductRepository productRepository,
                       UserRepository userRepository,
                       @Value("${app.cart.tax-rate}") BigDecimal taxRate,
                       @Value("${app.cart.shipping-cost}") BigDecimal shippingCost,
                       @Value("${app.cart.free-shipping-from}") BigDecimal freeShippingFrom) {
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
        this.taxRate = taxRate;
        this.shippingCost = shippingCost;
        this.freeShippingFrom = freeShippingFrom;
    }

    @Transactional(readOnly = true)
    public CartResponse getCart(Long userId) {
        return toResponse(cartItemRepository.findByUserIdOrderByIdAsc(userId));
    }

    /** Agrega un producto. Si ya estaba en el carrito, suma la cantidad. */
    @Transactional
    public CartResponse addItem(Long userId, AddToCartRequest req) {
        Product product = productRepository.findById(req.productId())
                .orElseThrow(() -> ApiException.notFound("Producto no encontrado"));

        CartItem item = cartItemRepository.findByUserIdAndProductId(userId, product.getId())
                .orElseGet(() -> CartItem.builder()
                        .user(userRepository.getReferenceById(userId))
                        .product(product)
                        .quantity(0)
                        .build());

        int newQuantity = item.getQuantity() + req.quantity();
        checkStock(product, newQuantity);
        item.setQuantity(newQuantity);
        cartItemRepository.save(item);
        return getCart(userId);
    }

    /** Cambia la cantidad de un item (botones + / -). */
    @Transactional
    public CartResponse updateItem(Long userId, Long itemId, UpdateCartItemRequest req) {
        CartItem item = findItem(userId, itemId);
        checkStock(item.getProduct(), req.quantity());
        item.setQuantity(req.quantity());
        return getCart(userId);
    }

    @Transactional
    public CartResponse removeItem(Long userId, Long itemId) {
        cartItemRepository.delete(findItem(userId, itemId));
        return getCart(userId);
    }

    @Transactional
    public CartResponse clear(Long userId) {
        cartItemRepository.deleteAll(cartItemRepository.findByUserIdOrderByIdAsc(userId));
        return getCart(userId);
    }

    /** Calcula subtotal, IVA, envío y total. También lo usa OrderService al pagar. */
    public CartSummary summarize(List<CartItem> items) {
        BigDecimal subtotal = items.stream()
                .map(i -> i.getProduct().getPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
        BigDecimal tax = subtotal.multiply(taxRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal shipping = (items.isEmpty() || subtotal.compareTo(freeShippingFrom) >= 0)
                ? BigDecimal.ZERO.setScale(2) : shippingCost.setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = subtotal.add(tax).add(shipping);
        int count = items.stream().mapToInt(CartItem::getQuantity).sum();
        return new CartSummary(count, subtotal, taxRate, tax, shipping, total);
    }

    private CartResponse toResponse(List<CartItem> items) {
        List<CartItemResponse> list = items.stream().map(i -> {
            Product p = i.getProduct();
            return new CartItemResponse(i.getId(), p.getId(), p.getName(), p.getImageUrl(), p.getPrice(),
                    i.getQuantity(), p.getStock(),
                    p.getPrice().multiply(BigDecimal.valueOf(i.getQuantity())).setScale(2, RoundingMode.HALF_UP));
        }).toList();
        return new CartResponse(list, summarize(items));
    }

    private CartItem findItem(Long userId, Long itemId) {
        return cartItemRepository.findByIdAndUserId(itemId, userId)
                .orElseThrow(() -> ApiException.notFound("El producto no está en tu carrito"));
    }

    static void checkStock(Product product, int quantity) {
        if (quantity > product.getStock()) {
            throw ApiException.badRequest("Solo hay " + product.getStock() + " unidades disponibles de "
                    + product.getName());
        }
    }
}
