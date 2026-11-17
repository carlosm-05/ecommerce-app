package com.uniminuto.ecommerce.dto;

import com.uniminuto.ecommerce.entity.Order;
import com.uniminuto.ecommerce.entity.OrderItem;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** DTOs de pedidos (compra simulada y "Mis pedidos"). */
public final class OrderDtos {

    private OrderDtos() {}

    /** Ambos campos son opcionales: la compra es simulada. */
    public record CheckoutRequest(
            @Size(max = 250, message = "La dirección es demasiado larga")
            String shippingAddress,

            @Size(max = 40, message = "El método de pago es demasiado largo")
            String paymentMethod
    ) {}

    public record OrderItemResponse(
            Long productId,
            String productName,
            String imageUrl,
            BigDecimal unitPrice,
            int quantity,
            BigDecimal lineTotal
    ) {
        public static OrderItemResponse from(OrderItem i) {
            return new OrderItemResponse(i.getProductId(), i.getProductName(), i.getImageUrl(),
                    i.getUnitPrice(), i.getQuantity(), i.getLineTotal());
        }
    }

    public record OrderResponse(
            Long id,
            String status,
            Instant createdAt,
            int itemCount,
            BigDecimal subtotal,
            BigDecimal tax,
            BigDecimal shipping,
            BigDecimal total,
            String shippingAddress,
            String paymentMethod,
            List<OrderItemResponse> items
    ) {
        public static OrderResponse from(Order o) {
            List<OrderItemResponse> items = o.getItems().stream().map(OrderItemResponse::from).toList();
            int count = o.getItems().stream().mapToInt(OrderItem::getQuantity).sum();
            return new OrderResponse(o.getId(), o.getStatus().name(), o.getCreatedAt(), count,
                    o.getSubtotal(), o.getTax(), o.getShipping(), o.getTotal(),
                    o.getShippingAddress(), o.getPaymentMethod(), items);
        }
    }
}
