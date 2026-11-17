package com.uniminuto.ecommerce.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** DTOs del modulo de autenticación. */
public final class AuthDtos {

    private AuthDtos() {}

    public static final String EMAIL_REGEX = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$";
    public static final String USERNAME_REGEX = "^[a-zA-Z0-9._]+$";

    public record RegisterRequest(
            @NotBlank(message = "El nombre es obligatorio")
            @Size(max = 80, message = "El nombre no puede superar 80 caracteres")
            String firstName,

            @NotBlank(message = "Los apellidos son obligatorios")
            @Size(max = 80, message = "Los apellidos no pueden superar 80 caracteres")
            String lastName,

            @NotBlank(message = "El username es obligatorio")
            @Size(min = 3, max = 40, message = "El username debe tener entre 3 y 40 caracteres")
            @Pattern(regexp = USERNAME_REGEX, message = "El username solo puede tener letras, números, punto y guion bajo")
            String username,

            @NotBlank(message = "El correo es obligatorio")
            @Email(regexp = EMAIL_REGEX, message = "El formato del correo no es válido")
            String email,

            @NotBlank(message = "La contraseña es obligatoria")
            @Size(min = 8, message = "La contraseña debe tener mínimo 8 caracteres")
            String password,

            @NotBlank(message = "Debes confirmar la contraseña")
            String confirmPassword
    ) {}

    public record LoginRequest(
            @NotBlank(message = "El username o correo es obligatorio")
            String usernameOrEmail,

            @NotBlank(message = "La contraseña es obligatoria")
            @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
            String password
    ) {}

    public record AuthResponse(
            String token,
            String tokenType,
            long expiresIn,
            UserDtos.UserResponse user
    ) {}

    public record ForgotPasswordRequest(
            @NotBlank(message = "El correo es obligatorio")
            @Email(regexp = EMAIL_REGEX, message = "El formato del correo no es válido")
            String email
    ) {}

    public record ResetPasswordRequest(
            @NotBlank(message = "El token es obligatorio")
            String token,

            @NotBlank(message = "La nueva contraseña es obligatoria")
            @Size(min = 8, message = "La contraseña debe tener mínimo 8 caracteres")
            String newPassword,

            @NotBlank(message = "Debes confirmar la contraseña")
            String confirmPassword
    ) {}

    public record AvailabilityResponse(boolean available) {}
}
