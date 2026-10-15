import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/backend.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
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
  final _code = TextEditingController();

  /// Set once the backend mailed a code; the screen then shows the code step.
  String? _pendingEmail;
  String? _codeError;
  int _resendIn = 0;
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    for (final c in [_name, _email, _password, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await ref
        .read(authControllerProvider.notifier)
        .signUp(name: _name.text, email: _email.text, password: _password.text);
    if (!mounted || outcome != SignUpOutcome.needsCode) return;
    setState(() => _pendingEmail = _email.text.trim());
    _startCooldown();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _codeError = context.l10n.invalidCode);
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .verifySignUpCode(email: _pendingEmail!, code: code);
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendSignUpCode(_pendingEmail!);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.codeResent)));
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _resendIn = 30);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn -= 1);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBusy = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (_, next) {
      final error = next.error;
      if (error == null || !context.mounted) return;
      if (_pendingEmail != null) {
        // On the code step the reason belongs under the field.
        setState(() => _codeError = authErrorMessage(context, error));
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(authErrorMessage(context, error))),
        );
    });

    if (_pendingEmail != null) {
      return AuthScaffold(
        title: l10n.enterCode,
        subtitle: l10n.codeSentTo(_pendingEmail!),
        children: _codeStep(isBusy),
      );
    }

    return AuthScaffold(
      title: l10n.signUpTitle,
      subtitle: l10n.signUpExplain,
      children: _detailsStep(isBusy),
    );
  }

  List<Widget> _detailsStep(bool isBusy) {
    final l10n = context.l10n;
    final validators = Validators(l10n);
    return [
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
            : const Icon(Icons.arrow_forward, size: 18),
        label: Text(l10n.signUp),
      ),
      const SizedBox(height: Gap.md),
      TextButton(
        onPressed: isBusy ? null : () => context.goNamed(AppRoute.signIn.name),
        child: Text(l10n.alreadyHaveAccount),
      ),
    ];
  }

  List<Widget> _codeStep(bool isBusy) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDemo = ref.watch(backendProvider) == Backend.local;
    return [
      TextField(
        controller: _code,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        autofillHints: const [AutofillHints.oneTimeCode],
        textAlign: TextAlign.center,
        style: theme.textTheme.mono.copyWith(fontSize: 28, letterSpacing: 10),
        decoration: InputDecoration(
          labelText: l10n.verificationCode,
          errorText: _codeError,
          counterText: '',
        ),
        onChanged: (_) {
          if (_codeError != null) setState(() => _codeError = null);
        },
        onSubmitted: (_) => _verify(),
      ),
      if (isDemo) ...[
        const SizedBox(height: Gap.sm),
        Text(l10n.demoCodeHint, style: theme.textTheme.bodySmall),
      ],
      const SizedBox(height: Gap.xl),
      FilledButton.icon(
        onPressed: isBusy ? null : _verify,
        icon: isBusy
            ? const ButtonSpinner()
            : const Icon(Icons.check, size: 18),
        label: Text(l10n.verify),
      ),
      const SizedBox(height: Gap.md),
      TextButton(
        onPressed: isBusy || _resendIn > 0 ? null : _resend,
        child: Text(_resendIn > 0 ? l10n.resendIn(_resendIn) : l10n.resendCode),
      ),
      TextButton(
        onPressed: isBusy
            ? null
            : () => setState(() {
                _pendingEmail = null;
                _codeError = null;
                _code.clear();
              }),
        child: Text(l10n.changeEmail),
      ),
    ];
  }
}
