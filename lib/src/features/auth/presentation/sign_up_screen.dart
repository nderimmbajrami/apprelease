import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../routing/app_routes.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';
import 'widgets/auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(name: _name.text, email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validators = Validators(l10n);
    final isBusy = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (_, next) {
      final error = next.error;
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(authErrorMessage(context, error))),
        );
    });

    return AuthScaffold(
      title: l10n.signUpTitle,
      subtitle: l10n.signUpExplain,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline, size: 19),
                ),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: validators.required,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.alternate_email, size: 19),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validators.email,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline, size: 19),
                ),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                validator: validators.password,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton.icon(
          onPressed: isBusy ? null : _submit,
          icon: isBusy
              ? const ButtonSpinner()
              : const Icon(Icons.rocket_launch_outlined, size: 18),
          label: Text(l10n.signUp),
        ),
        const SizedBox(height: Gap.md),
        TextButton(
          onPressed: isBusy
              ? null
              : () => context.goNamed(AppRoute.signIn.name),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }
}
