package com.uniminuto.ecommerce.controller;

import com.uniminuto.ecommerce.dto.AuthDtos.*;
import com.uniminuto.ecommerce.dto.CommonDtos.MessageResponse;
import com.uniminuto.ecommerce.dto.UserDtos.UserResponse;
import com.uniminuto.ecommerce.security.AuthUser;
import com.uniminuto.ecommerce.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@Tag(name = "Autenticación", description = "Registro, login, logout y recuperación de contraseña")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Registrar usuario", description = "No devuelve token: la app debe redirigir al Login.")
    public UserResponse register(@Valid @RequestBody RegisterRequest req) {
        return authService.register(req);
    }

    @PostMapping("/login")
    @Operation(summary = "Iniciar sesión con username o correo", description = "Devuelve el JWT para guardar en la app.")
    public AuthResponse login(@Valid @RequestBody LoginRequest req) {
        return authService.login(req);
    }

    @PostMapping("/logout")
    @Operation(summary = "Cerrar sesión", description = "Invalida el JWT actual (y cualquier otro del usuario).")
    public MessageResponse logout(@AuthenticationPrincipal AuthUser me) {
        authService.logout(me.id());
        return new MessageResponse("Sesión cerrada correctamente");
    }

    @GetMapping("/check-username")
    @Operation(summary = "Verificar si un username está disponible")
    public AvailabilityResponse checkUsername(@RequestParam String username) {
        return new AvailabilityResponse(authService.isUsernameAvailable(username));
    }

    @GetMapping("/check-email")
    @Operation(summary = "Verificar si un correo está disponible")
    public AvailabilityResponse checkEmail(@RequestParam String email) {
        return new AvailabilityResponse(authService.isEmailAvailable(email));
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Solicitar enlace de recuperación por correo")
    public MessageResponse forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        authService.forgotPassword(req);
        return new MessageResponse("Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña");
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Restablecer contraseña con el token del enlace")
    public MessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req);
        return new MessageResponse("Contraseña actualizada. Ya puedes iniciar sesión");
    }
}
