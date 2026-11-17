import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isSaving = false;
  bool _obscure = true;
  Map<String, String> _fieldErrors = <String, String>{};

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _fieldErrors = <String, String>{};
    });
    try {
      final message = await ref.read(authProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _newPassword.text,
            confirmPassword: _confirmation.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.fieldErrors);
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _current,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    errorText: _fieldErrors['currentPassword'],
                    suffixIcon: _visibilityButton(),
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _newPassword,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    errorText: _fieldErrors['newPassword'],
                    suffixIcon: _visibilityButton(),
                  ),
                  validator: Validators.registrationPassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmation,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    errorText: _fieldErrors['confirmPassword'],
                    suffixIcon: _visibilityButton(),
                  ),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _newPassword.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Actualizar contraseña'),
          ),
        ],
      ),
    );
  }

  Widget _visibilityButton() => IconButton(
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off),
      );
}
