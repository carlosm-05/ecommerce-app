package com.uniminuto.ecommerce.controller;

import com.uniminuto.ecommerce.dto.OrderDtos.CheckoutRequest;
import com.uniminuto.ecommerce.dto.OrderDtos.OrderResponse;
import com.uniminuto.ecommerce.security.AuthUser;
import com.uniminuto.ecommerce.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/orders")
@Tag(name = "Pedidos", description = "Compra simulada y \"Mis pedidos\"")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping("/checkout")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Proceder al pago (simulado)", description = "Crea el pedido desde el carrito y lo vacía. El body es opcional.")
    public OrderResponse checkout(@AuthenticationPrincipal AuthUser me,
                                  @Valid @RequestBody(required = false) CheckoutRequest req) {
        return orderService.checkout(me.id(), req);
    }

    @GetMapping
    @Operation(summary = "Mis pedidos (más recientes primero)")
    public List<OrderResponse> myOrders(@AuthenticationPrincipal AuthUser me) {
        return orderService.myOrders(me.id());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalle de uno de mis pedidos")
    public OrderResponse myOrder(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        return orderService.myOrder(me.id(), id);
    }
}
