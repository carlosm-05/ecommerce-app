import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  Timer? _usernameDebounce;
  Map<String, String> _fieldErrors = <String, String>{};
  bool _usernameUnavailable = false;
  bool _checkingUsername = false;
  bool _isSending = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() {
      _usernameUnavailable = false;
      _fieldErrors.remove('username');
    });
    if (Validators.username(value) != null) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _checkingUsername = true);
      try {
        final available =
            await ref.read(authServiceProvider).checkUsername(value.trim());
        if (mounted && _username.text.trim() == value.trim()) {
          setState(() => _usernameUnavailable = !available);
        }
      } catch (error) {
        if (mounted) showApiError(context, error);
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _usernameUnavailable) return;
    setState(() {
      _isSending = true;
      _fieldErrors = <String, String>{};
    });
    try {
      await ref.read(authProvider).register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            username: _username.text,
            email: _email.text,
            password: _password.text,
            confirmPassword: _confirmPassword.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada, inicia sesión')),
      );
      context.go('/login');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.fieldErrors);
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Regístrate para empezar a comprar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _field(
                controller: _firstName,
                label: 'Nombre',
                serverKey: 'firstName',
                validator: Validators.required,
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                controller: _lastName,
                label: 'Apellidos',
                serverKey: 'lastName',
                validator: Validators.required,
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                controller: _username,
                label: 'Username',
                serverKey: 'username',
                validator: (value) => _usernameUnavailable
                    ? 'El username ya está en uso'
                    : Validators.username(value),
                onChanged: _onUsernameChanged,
                suffixIcon: _checkingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _usernameUnavailable
                        ? const Icon(Icons.error_outline)
                        : null,
              ),
              _field(
                controller: _email,
                label: 'Correo',
                serverKey: 'email',
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                controller: _password,
                label: 'Contraseña',
                serverKey: 'password',
                validator: Validators.registrationPassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              _field(
                controller: _confirmPassword,
                label: 'Verificar contraseña',
                serverKey: 'confirmPassword',
                validator: (value) =>
                    Validators.confirmPassword(value, _password.text),
                obscureText: _obscureConfirmation,
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmation
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isSending || _usernameUnavailable
                    ? null
                    : _submit,
                child: _isSending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarse'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String serverKey,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: _fieldErrors[serverKey],
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}
