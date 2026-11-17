import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../providers/app_providers.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _username;
  bool _isSaving = false;
  Map<String, String> _fieldErrors = <String, String>{};

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _username = TextEditingController(text: user.username);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _fieldErrors = <String, String>{};
    });
    try {
      await ref.read(authProvider).updateProfile(
            firstName: _firstName.text,
            lastName: _lastName.text,
            username: _username.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
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
    final user = ref.watch(authProvider).user!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: user.avatarUrl == null
                ? Text(
                    user.initials,
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                : ClipOval(
                    child: AppNetworkImage(
                      url: AppConfig.resolveImageUrl(user.avatarUrl),
                      width: 96,
                      height: 96,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  errorText: _fieldErrors['firstName'],
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  errorText: _fieldErrors['lastName'],
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: _fieldErrors['username'],
                ),
                validator: Validators.username,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  helperText: 'El correo no se puede modificar',
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
              : const Text('Guardar cambios'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/password'),
          icon: const Icon(Icons.lock_reset),
          label: const Text('Cambiar contraseña'),
        ),
      ],
    );
  }
}
