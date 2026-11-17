package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.dto.AuthDtos.*;
import com.uniminuto.ecommerce.dto.UserDtos.UserResponse;
import com.uniminuto.ecommerce.entity.PasswordResetToken;
import com.uniminuto.ecommerce.entity.User;
import com.uniminuto.ecommerce.exception.ApiException;
import com.uniminuto.ecommerce.repository.PasswordResetTokenRepository;
import com.uniminuto.ecommerce.repository.UserRepository;
import com.uniminuto.ecommerce.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

@Service
public class AuthService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository resetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final MailService mailService;
    private final String resetBaseUrl;
    private final Duration resetExpiration;

    public AuthService(UserRepository userRepository,
                       PasswordResetTokenRepository resetTokenRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       MailService mailService,
                       @Value("${app.reset-password.base-url}") String resetBaseUrl,
                       @Value("${app.reset-password.expiration-minutes}") long resetExpirationMinutes) {
        this.userRepository = userRepository;
        this.resetTokenRepository = resetTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.mailService = mailService;
        this.resetBaseUrl = resetBaseUrl;
        this.resetExpiration = Duration.ofMinutes(resetExpirationMinutes);
    }

    // ---------------------------------------------------------------- registro

    @Transactional
    public UserResponse register(RegisterRequest req) {
        String username = req.username().trim();
        String email = req.email().trim().toLowerCase();

        Map<String, String> errors = new LinkedHashMap<>();
        if (!req.password().equals(req.confirmPassword())) {
            errors.put("confirmPassword", "Las contraseñas no coinciden");
        }
        boolean duplicated = false;
        if (userRepository.existsByUsernameIgnoreCase(username)) {
            errors.put("username", "El username ya está en uso");
            duplicated = true;
        }
        if (userRepository.existsByEmailIgnoreCase(email)) {
            errors.put("email", "Ya existe una cuenta con este correo");
            duplicated = true;
        }
        if (!errors.isEmpty()) {
            HttpStatus status = duplicated && errors.size() == countDuplicates(errors)
                    ? HttpStatus.CONFLICT : HttpStatus.BAD_REQUEST;
            throw new ApiException(status, "No se pudo completar el registro", errors);
        }

        User user = User.builder()
                .firstName(req.firstName().trim())
                .lastName(req.lastName().trim())
                .username(username)
                .email(email)
                .passwordHash(passwordEncoder.encode(req.password()))
                .avatarUrl(defaultAvatar(req.firstName().trim(), req.lastName().trim()))
                .build();
        return UserResponse.from(userRepository.save(user));
    }

    private static int countDuplicates(Map<String, String> errors) {
        return (errors.containsKey("username") ? 1 : 0) + (errors.containsKey("email") ? 1 : 0);
    }

    public static String defaultAvatar(String firstName, String lastName) {
        return "https://ui-avatars.com/api/?background=random&size=256&name="
                + URLEncoder.encode(firstName + " " + lastName, StandardCharsets.UTF_8);
    }

    // ---------------------------------------------------------------- login / logout

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest req) {
        String identifier = req.usernameOrEmail().trim();
        Optional<User> found = identifier.contains("@")
                ? userRepository.findByEmailIgnoreCase(identifier)
                : userRepository.findByUsernameIgnoreCase(identifier);

        User user = found
                .filter(u -> passwordEncoder.matches(req.password(), u.getPasswordHash()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Usuario o contraseña incorrectos"));

        return new AuthResponse(jwtService.generateToken(user), "Bearer",
                jwtService.getExpirationSeconds(), UserResponse.from(user));
    }

    /** Invalida todos los JWT emitidos al usuario incrementando su tokenVersion. */
    @Transactional
    public void logout(Long userId) {
        userRepository.findById(userId).ifPresent(u -> u.setTokenVersion(u.getTokenVersion() + 1));
    }

    // ---------------------------------------------------------------- disponibilidad

    @Transactional(readOnly = true)
    public boolean isUsernameAvailable(String username) {
        return username != null && !username.isBlank()
                && !userRepository.existsByUsernameIgnoreCase(username.trim());
    }

    @Transactional(readOnly = true)
    public boolean isEmailAvailable(String email) {
        return email != null && !email.isBlank()
                && !userRepository.existsByEmailIgnoreCase(email.trim());
    }

    // ---------------------------------------------------------------- recuperacion de contrasena

    /**
     * Si el correo existe genera un token de un solo uso y envía el enlace por correo.
     * Siempre responde igual (exista o no el correo) para no revelar qué cuentas existen.
     */
    @Transactional
    public void forgotPassword(ForgotPasswordRequest req) {
        userRepository.findByEmailIgnoreCase(req.email().trim()).ifPresent(user -> {
            byte[] bytes = new byte[32];
            RANDOM.nextBytes(bytes);
            String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

            resetTokenRepository.save(PasswordResetToken.builder()
                    .tokenHash(sha256(rawToken))
                    .user(user)
                    .expiresAt(Instant.now().plus(resetExpiration))
                    .build());

            mailService.sendPasswordReset(user, resetBaseUrl + rawToken, resetExpiration.toMinutes());
        });
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest req) {
        if (!req.newPassword().equals(req.confirmPassword())) {
            throw ApiException.field(HttpStatus.BAD_REQUEST, "confirmPassword", "Las contraseñas no coinciden");
        }
        PasswordResetToken token = resetTokenRepository.findByTokenHash(sha256(req.token().trim()))
                .filter(t -> !t.isUsed() && t.getExpiresAt().isAfter(Instant.now()))
                .orElseThrow(() -> ApiException.badRequest("El enlace de recuperación es inválido o ya expiró"));

        User user = token.getUser();
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        user.setTokenVersion(user.getTokenVersion() + 1); // cierra las sesiones abiertas
        token.setUsed(true);
    }

    private static String sha256(String value) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
