package com.uniminuto.ecommerce.security;

/**
 * Usuario autenticado que queda en el SecurityContext después de validar el JWT.
 * En los controladores se obtiene con {@code @AuthenticationPrincipal AuthUser me}.
 */
public record AuthUser(Long id, String username) {}
