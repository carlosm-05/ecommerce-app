package com.uniminuto.ecommerce.security;

import com.uniminuto.ecommerce.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Lee el header {@code Authorization: Bearer <token>}, valida el JWT y autentica la petición.
 * Tambien compara la "version" del token con la del usuario: si el usuario cerro sesión
 * (version incrementada) el token viejo queda inválido.
 */
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public JwtAuthFilter(JwtService jwtService, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7).trim();
            try {
                Claims claims = jwtService.parse(token);
                Long userId = Long.valueOf(claims.getSubject());
                Integer version = claims.get(JwtService.CLAIM_VERSION, Integer.class);
                userRepository.findById(userId)
                        .filter(u -> version != null && u.getTokenVersion() == version)
                        .ifPresent(u -> {
                            var auth = new UsernamePasswordAuthenticationToken(
                                    new AuthUser(u.getId(), u.getUsername()), null, List.of());
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
            } catch (JwtException | IllegalArgumentException ignored) {
                // Token inválido o expirado: la petición sigue como anonima y Security responde 401.
            }
        }
        chain.doFilter(request, response);
    }
}
