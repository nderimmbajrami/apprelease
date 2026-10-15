import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/backend.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../routing/app_routes.dart';
import '../data/local_auth_repository.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';
import 'widgets/auth_scaffold.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validators = Validators(l10n);
    final isBusy = ref.watch(authControllerProvider).isLoading;
    final isDemo = ref.watch(backendProvider) == Backend.local;

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
      title: l10n.welcomeBack,
      subtitle: l10n.signInExplain,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.alternate_email, size: 19),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: validators.email,
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline, size: 19),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: validators.password,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton.icon(
          onPressed: isBusy ? null : _submit,
          icon: isBusy
              ? const ButtonSpinner()
              : const Icon(Icons.login, size: 18),
          label: Text(l10n.signIn),
        ),
        if (isDemo) ...[
          const SizedBox(height: Gap.sm),
          TextButton(
            onPressed: isBusy
                ? null
                : () {
                    _email.text = LocalAuthRepository.demoEmail;
                    _password.text = LocalAuthRepository.demoPassword;
                  },
            child: Text(l10n.fillDemo),
          ),
        ],
        const SizedBox(height: Gap.md),
        OutlinedButton.icon(
          onPressed: isBusy
              ? null
              : () => context.goNamed(AppRoute.signUp.name),
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: Text(l10n.noAccountYet),
        ),
      ],
    );
  }
}
