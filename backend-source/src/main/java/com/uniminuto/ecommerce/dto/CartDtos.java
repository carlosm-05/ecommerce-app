package com.uniminuto.ecommerce.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;

/** DTOs del carrito de compras. */
public final class CartDtos {

    private CartDtos() {}

    public record AddToCartRequest(
            @NotNull(message = "El producto es obligatorio")
            Long productId,

            @NotNull(message = "La cantidad es obligatoria")
            @Min(value = 1, message = "La cantidad mínima es 1")
            @Max(value = 99, message = "La cantidad máxima es 99")
            Integer quantity
    ) {}

    public record UpdateCartItemRequest(
            @NotNull(message = "La cantidad es obligatoria")
            @Min(value = 1, message = "La cantidad mínima es 1")
            @Max(value = 99, message = "La cantidad máxima es 99")
            Integer quantity
    ) {}

    public record CartItemResponse(
            Long id,
            Long productId,
            String name,
            String imageUrl,
            BigDecimal unitPrice,
            int quantity,
            int stock,
            BigDecimal lineTotal
    ) {}

    public record CartSummary(
            int itemCount,
            BigDecimal subtotal,
            BigDecimal taxRate,
            BigDecimal tax,
            BigDecimal shipping,
            BigDecimal total
    ) {}

    public record CartResponse(List<CartItemResponse> items, CartSummary summary) {}
}
