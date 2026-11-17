package com.uniminuto.ecommerce.dto;

import com.uniminuto.ecommerce.entity.User;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/** DTOs del perfil de usuario. */
public final class UserDtos {

    private UserDtos() {}

    public record UserResponse(
            Long id,
            String firstName,
            String lastName,
            String fullName,
            String username,
            String email,
            String avatarUrl,
            Instant createdAt
    ) {
        public static UserResponse from(User u) {
            return new UserResponse(u.getId(), u.getFirstName(), u.getLastName(),
                    u.getFirstName() + " " + u.getLastName(), u.getUsername(), u.getEmail(),
                    u.getAvatarUrl(), u.getCreatedAt());
        }
    }

    public record UpdateProfileRequest(
            @NotBlank(message = "El nombre es obligatorio")
            @Size(max = 80, message = "El nombre no puede superar 80 caracteres")
            String firstName,

            @NotBlank(message = "Los apellidos son obligatorios")
            @Size(max = 80, message = "Los apellidos no pueden superar 80 caracteres")
            String lastName,

            @NotBlank(message = "El username es obligatorio")
            @Size(min = 3, max = 40, message = "El username debe tener entre 3 y 40 caracteres")
            @Pattern(regexp = AuthDtos.USERNAME_REGEX, message = "El username solo puede tener letras, números, punto y guion bajo")
            String username,

            /** Opcional: URL de la foto de perfil. Si viene null se conserva la actual. */
            @Size(max = 500, message = "La URL del avatar es demasiado larga")
            String avatarUrl
    ) {}

    public record ChangePasswordRequest(
            @NotBlank(message = "La contraseña actual es obligatoria")
            String currentPassword,

            @NotBlank(message = "La nueva contraseña es obligatoria")
            @Size(min = 8, message = "La contraseña debe tener mínimo 8 caracteres")
            String newPassword,

            @NotBlank(message = "Debes confirmar la contraseña")
            String confirmPassword
    ) {}
}
