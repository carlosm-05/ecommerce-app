class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernameRegex = RegExp(r'^[A-Za-z0-9._]+$');

  static String? required(String? value, {String message = 'Este campo es obligatorio'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    if (value.trim().length < 3) return 'Ingresa tu nombre completo';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    final String trimmed = value.trim();
    if (trimmed.length < 3 || trimmed.length > 40) {
      return 'El username debe tener entre 3 y 40 caracteres';
    }
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'El username solo puede tener letras, números, punto y guion bajo';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    if (!_emailRegex.hasMatch(value.trim())) return 'Ingresa un correo electrónico válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  static String? registrationPassword(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    if (value.length < 8) return 'La contraseña debe tener mínimo 8 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
