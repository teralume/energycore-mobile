import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../shared/presentation/widgets/brand_mark.dart';
import '../../shared/presentation/widgets/mascot_panel.dart';
import '../application/auth_controller.dart';

enum _AuthMode { signIn, signUp, recover, reset }

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.controller,
    required this.locale,
    required this.onLocaleChanged,
  });

  final AuthController controller;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tokenController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    widget.controller.clearFeedback();
    _formKey.currentState?.reset();
    setState(() => _mode = mode);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    switch (_mode) {
      case _AuthMode.signIn:
        await widget.controller.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      case _AuthMode.signUp:
        await widget.controller.signUp(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      case _AuthMode.recover:
        await widget.controller.recoverPassword(_emailController.text);
      case _AuthMode.reset:
        await widget.controller.resetPassword(
          token: _tokenController.text,
          password: _passwordController.text,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final form = _AuthForm(
              formKey: _formKey,
              controller: widget.controller,
              mode: _mode,
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              tokenController: _tokenController,
              hidePassword: _hidePassword,
              onTogglePassword: () =>
                  setState(() => _hidePassword = !_hidePassword),
              onSubmit: _submit,
              onModeChanged: _setMode,
              locale: widget.locale,
              onLocaleChanged: widget.onLocaleChanged,
            );

            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: MascotPanel(
                        title: context.strings.text('tagline'),
                        message: context.strings.text('authVisualMessage'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 9, child: form),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                children: [
                  SizedBox(
                    height: 245,
                    child: MascotPanel(
                      compact: true,
                      title: context.strings.text('tagline'),
                      message: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  form,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.controller,
    required this.mode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.tokenController,
    required this.hidePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onModeChanged,
    required this.locale,
    required this.onLocaleChanged,
  });

  final GlobalKey<FormState> formKey;
  final AuthController controller;
  final _AuthMode mode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController tokenController;
  final bool hidePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final ValueChanged<_AuthMode> onModeChanged;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = switch (mode) {
      _AuthMode.signIn => strings.text('welcome'),
      _AuthMode.signUp => strings.text('createTitle'),
      _AuthMode.recover => strings.text('recoverTitle'),
      _AuthMode.reset => strings.text('resetPasswordTitle'),
    };
    final action = switch (mode) {
      _AuthMode.signIn => strings.text('signIn'),
      _AuthMode.signUp => strings.text('signUp'),
      _AuthMode.recover => strings.text('sendRecovery'),
      _AuthMode.reset => strings.text('resetPassword'),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const BrandMark(),
                      const Spacer(),
                      _LanguageMenu(
                        locale: locale ?? Localizations.localeOf(context),
                        onChanged: onLocaleChanged,
                      ),
                    ],
                  ),
                  SizedBox(height: mode == _AuthMode.signIn ? 34 : 18),
                  if (mode != _AuthMode.signIn) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('auth-back-to-login'),
                        onPressed: () => onModeChanged(_AuthMode.signIn),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(strings.text('backToLogin')),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    strings.text('tagline'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (mode == _AuthMode.signUp) ...[
                    TextFormField(
                      controller: nameController,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.text('fullName'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.text('required')
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (mode != _AuthMode.reset)
                    TextFormField(
                      controller: emailController,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: mode == _AuthMode.recover
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onFieldSubmitted: mode == _AuthMode.recover
                          ? (_) => onSubmit()
                          : null,
                      decoration: InputDecoration(
                        labelText: strings.text('email'),
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return strings.text('required');
                        if (!email.contains('@') || !email.contains('.')) {
                          return strings.text('invalidEmail');
                        }
                        return null;
                      },
                    ),
                  if (mode == _AuthMode.reset) ...[
                    TextFormField(
                      controller: tokenController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.text('recoveryToken'),
                        prefixIcon: const Icon(Icons.key_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.text('required')
                          : null,
                    ),
                  ],
                  if (mode != _AuthMode.recover) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      autofillHints: mode == _AuthMode.signIn
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                      obscureText: hidePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        labelText: strings.text('password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? strings.text('showPassword')
                              : strings.text('hidePassword'),
                          onPressed: onTogglePassword,
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings.text('required');
                        }
                        if (value.length < 8) {
                          return strings.text('shortPassword');
                        }
                        return null;
                      },
                    ),
                    if (mode == _AuthMode.reset) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          labelText: strings.text('confirmPassword'),
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings.text('required');
                          }
                          if (value != passwordController.text) {
                            return strings.text('passwordsDoNotMatch');
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                  if (controller.failure case final failure?) ...[
                    const SizedBox(height: 14),
                    _FeedbackMessage(
                      icon: failure.isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.error_outline_rounded,
                      message: failure.isOffline
                          ? strings.text('offline')
                          : failure.message,
                      isError: true,
                    ),
                  ],
                  if (controller.notice case final notice?) ...[
                    const SizedBox(height: 14),
                    _FeedbackMessage(
                      icon: Icons.mark_email_read_outlined,
                      message: strings.text(notice),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: controller.isBusy ? null : onSubmit,
                    icon: controller.isBusy
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Icon(Icons.bolt_rounded),
                    label: Text(action),
                  ),
                  const SizedBox(height: 12),
                  if (mode == _AuthMode.signIn) ...[
                    TextButton(
                      onPressed: () => onModeChanged(_AuthMode.recover),
                      child: Text(strings.text('forgot')),
                    ),
                    _ModePrompt(
                      prompt: strings.text('noAccount'),
                      action: strings.text('signUp'),
                      onPressed: () => onModeChanged(_AuthMode.signUp),
                    ),
                  ] else ...[
                    if (mode == _AuthMode.recover)
                      TextButton(
                        onPressed: () => onModeChanged(_AuthMode.reset),
                        child: Text(strings.text('haveRecoveryToken')),
                      ),
                    _ModePrompt(
                      prompt: mode == _AuthMode.signUp
                          ? strings.text('hasAccount')
                          : '',
                      action: strings.text('backToLogin'),
                      onPressed: () => onModeChanged(_AuthMode.signIn),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _ModePrompt extends StatelessWidget {
  const _ModePrompt({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (prompt.isNotEmpty) Text(prompt),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.locale, required this.onChanged});

  final Locale locale;
  final ValueChanged<Locale?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.strings.text('language'),
      initialValue: locale.languageCode,
      onSelected: (value) => onChanged(Locale(value)),
      icon: const Icon(Icons.language_rounded),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'es', child: Text('Español')),
        PopupMenuItem(value: 'pt', child: Text('Português')),
      ],
    );
  }
}
