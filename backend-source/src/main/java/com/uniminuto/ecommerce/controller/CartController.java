package com.uniminuto.ecommerce.controller;

import com.uniminuto.ecommerce.dto.CartDtos.AddToCartRequest;
import com.uniminuto.ecommerce.dto.CartDtos.CartResponse;
import com.uniminuto.ecommerce.dto.CartDtos.UpdateCartItemRequest;
import com.uniminuto.ecommerce.security.AuthUser;
import com.uniminuto.ecommerce.service.CartService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Todas las operaciones devuelven el carrito completo actualizado con su resumen. */
@RestController
@RequestMapping("/cart")
@Tag(name = "Carrito", description = "Carrito del usuario autenticado")
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    @Operation(summary = "Ver mi carrito con subtotal, IVA, envío y total")
    public CartResponse get(@AuthenticationPrincipal AuthUser me) {
        return cartService.getCart(me.id());
    }

    @PostMapping("/items")
    @Operation(summary = "Agregar producto (si ya existe, suma la cantidad)")
    public CartResponse add(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody AddToCartRequest req) {
        return cartService.addItem(me.id(), req);
    }

    @PatchMapping("/items/{itemId}")
    @Operation(summary = "Cambiar la cantidad de un item (+ / -)")
    public CartResponse update(@AuthenticationPrincipal AuthUser me, @PathVariable Long itemId,
                               @Valid @RequestBody UpdateCartItemRequest req) {
        return cartService.updateItem(me.id(), itemId, req);
    }

    @DeleteMapping("/items/{itemId}")
    @Operation(summary = "Eliminar un item del carrito")
    public CartResponse remove(@AuthenticationPrincipal AuthUser me, @PathVariable Long itemId) {
        return cartService.removeItem(me.id(), itemId);
    }

    @DeleteMapping
    @Operation(summary = "Vaciar el carrito")
    public CartResponse clear(@AuthenticationPrincipal AuthUser me) {
        return cartService.clear(me.id());
    }
}
