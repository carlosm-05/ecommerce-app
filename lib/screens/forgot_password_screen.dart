import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isSending = false;
  String? _message;
  String? _fieldError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSending = true;
      _fieldError = null;
    });
    try {
      final message =
          await ref.read(authServiceProvider).forgotPassword(_email.text);
      if (mounted) setState(() => _message = message);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _fieldError = error.fieldErrors['email']);
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _message == null
                  ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Icon(Icons.mark_email_read_outlined, size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'Te enviaremos un enlace para restablecer tu contraseña.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: const Icon(Icons.email_outlined),
                              errorText: _fieldError,
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _isSending ? null : _submit,
                            child: _isSending
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Enviar enlace'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        const Icon(Icons.mark_email_read, size: 56),
                        const SizedBox(height: 16),
                        Text(_message!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Volver al Login'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
