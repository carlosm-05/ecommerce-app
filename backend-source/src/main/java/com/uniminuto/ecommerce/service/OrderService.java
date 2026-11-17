package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.dto.CartDtos.CartSummary;
import com.uniminuto.ecommerce.dto.OrderDtos.CheckoutRequest;
import com.uniminuto.ecommerce.dto.OrderDtos.OrderResponse;
import com.uniminuto.ecommerce.entity.*;
import com.uniminuto.ecommerce.exception.ApiException;
import com.uniminuto.ecommerce.repository.CartItemRepository;
import com.uniminuto.ecommerce.repository.OrderRepository;
import com.uniminuto.ecommerce.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final CartItemRepository cartItemRepository;
    private final UserRepository userRepository;
    private final CartService cartService;

    public OrderService(OrderRepository orderRepository, CartItemRepository cartItemRepository,
                        UserRepository userRepository, CartService cartService) {
        this.orderRepository = orderRepository;
        this.cartItemRepository = cartItemRepository;
        this.userRepository = userRepository;
        this.cartService = cartService;
    }

    /**
     * Simula el pago: convierte el carrito en un pedido, descuenta el stock
     * y vacía el carrito. Todo en una sola transacción.
     */
    @Transactional
    public OrderResponse checkout(Long userId, CheckoutRequest req) {
        List<CartItem> cart = cartItemRepository.findByUserIdOrderByIdAsc(userId);
        if (cart.isEmpty()) {
            throw ApiException.badRequest("Tu carrito está vacío");
        }
        cart.forEach(i -> CartService.checkStock(i.getProduct(), i.getQuantity()));

        CartSummary summary = cartService.summarize(cart);
        Order order = Order.builder()
                .user(userRepository.getReferenceById(userId))
                .status(OrderStatus.PAGADO)
                .subtotal(summary.subtotal())
                .tax(summary.tax())
                .shipping(summary.shipping())
                .total(summary.total())
                .shippingAddress(req != null ? req.shippingAddress() : null)
                .paymentMethod(req != null && req.paymentMethod() != null ? req.paymentMethod() : "SIMULADO")
                .build();

        for (CartItem ci : cart) {
            Product p = ci.getProduct();
            order.getItems().add(OrderItem.builder()
                    .order(order)
                    .productId(p.getId())
                    .productName(p.getName())
                    .imageUrl(p.getImageUrl())
                    .unitPrice(p.getPrice())
                    .quantity(ci.getQuantity())
                    .lineTotal(p.getPrice().multiply(BigDecimal.valueOf(ci.getQuantity())))
                    .build());
            p.setStock(p.getStock() - ci.getQuantity());
        }

        Order saved = orderRepository.save(order);
        cartItemRepository.deleteAll(cart);
        return OrderResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> myOrders(Long userId) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(OrderResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public OrderResponse myOrder(Long userId, Long orderId) {
        return orderRepository.findByIdAndUserId(orderId, userId).map(OrderResponse::from)
                .orElseThrow(() -> ApiException.notFound("Pedido no encontrado"));
    }
}
