package com.uniminuto.ecommerce.controller;

import com.uniminuto.ecommerce.dto.CommonDtos.MessageResponse;
import com.uniminuto.ecommerce.dto.UserDtos.ChangePasswordRequest;
import com.uniminuto.ecommerce.dto.UserDtos.UpdateProfileRequest;
import com.uniminuto.ecommerce.dto.UserDtos.UserResponse;
import com.uniminuto.ecommerce.security.AuthUser;
import com.uniminuto.ecommerce.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users/me")
@Tag(name = "Perfil", description = "Datos del usuario autenticado")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    @Operation(summary = "Obtener mi perfil")
    public UserResponse me(@AuthenticationPrincipal AuthUser me) {
        return userService.getProfile(me.id());
    }

    @PutMapping
    @Operation(summary = "Actualizar nombre, apellidos, username y avatar")
    public UserResponse update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody UpdateProfileRequest req) {
        return userService.updateProfile(me.id(), req);
    }

    @PutMapping("/password")
    @Operation(summary = "Cambiar contraseña")
    public MessageResponse changePassword(@AuthenticationPrincipal AuthUser me,
                                          @Valid @RequestBody ChangePasswordRequest req) {
        userService.changePassword(me.id(), req);
        return new MessageResponse("Contraseña actualizada correctamente");
    }
}
