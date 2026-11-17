package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.dto.UserDtos.ChangePasswordRequest;
import com.uniminuto.ecommerce.dto.UserDtos.UpdateProfileRequest;
import com.uniminuto.ecommerce.dto.UserDtos.UserResponse;
import com.uniminuto.ecommerce.entity.User;
import com.uniminuto.ecommerce.exception.ApiException;
import com.uniminuto.ecommerce.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserResponse getProfile(Long userId) {
        return UserResponse.from(find(userId));
    }

    @Transactional
    public UserResponse updateProfile(Long userId, UpdateProfileRequest req) {
        User user = find(userId);
        String username = req.username().trim();
        if (userRepository.existsByUsernameIgnoreCaseAndIdNot(username, userId)) {
            throw ApiException.field(HttpStatus.CONFLICT, "username", "El username ya está en uso");
        }
        user.setFirstName(req.firstName().trim());
        user.setLastName(req.lastName().trim());
        user.setUsername(username);
        if (req.avatarUrl() != null && !req.avatarUrl().isBlank()) {
            user.setAvatarUrl(req.avatarUrl().trim());
        }
        return UserResponse.from(user);
    }

    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest req) {
        User user = find(userId);
        if (!passwordEncoder.matches(req.currentPassword(), user.getPasswordHash())) {
            throw ApiException.field(HttpStatus.BAD_REQUEST, "currentPassword", "La contraseña actual no es correcta");
        }
        if (!req.newPassword().equals(req.confirmPassword())) {
            throw ApiException.field(HttpStatus.BAD_REQUEST, "confirmPassword", "Las contraseñas no coinciden");
        }
        if (passwordEncoder.matches(req.newPassword(), user.getPasswordHash())) {
            throw ApiException.field(HttpStatus.BAD_REQUEST, "newPassword", "La nueva contraseña debe ser diferente a la actual");
        }
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
    }

    private User find(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> ApiException.notFound("Usuario no encontrado"));
    }
}
