import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/l10n.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../services/push_notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitted = false;

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();

    if (auth.isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _submitted = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // =======================================================
      // INITIALIZE PUSH NOTIFICATIONS ONLY ON MOBILE
      // =======================================================
      if (!kIsWeb) {
        await PushNotificationService.initialize();
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? context.tr('login_failed')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF0E1525) : Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -140,
            left: -100,
            child: _BackgroundCircle(
              size: 350,
              color: isDark ? Colors.blue.withOpacity(0.08) : const Color(0xFFE8F3FF),
            ),
          ),
          Positioned(
            top: -70,
            right: -120,
            child: _BackgroundCircle(
              size: 330,
              color: isDark ? Colors.blue.withOpacity(0.07) : const Color(0xFFF0F7FF),
            ),
          ),
          Positioned(
            top: 190,
            right: -110,
            child: _BackgroundCircle(
              size: 250,
              color: isDark ? Colors.blue.withOpacity(0.06) : const Color(0xFFDDEEFF),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
                final h = constraints.maxHeight;
                final compact = h < 760;
                final veryCompact = h < 650;

                final logoSize = veryCompact ? 66.0 : compact ? 78.0 : 96.0;
                final titleSize = veryCompact ? 28.0 : compact ? 32.0 : 38.0;
                final horizontalPadding = constraints.maxWidth < 500 ? 30.0 : 50.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: keyboardOpen ? 24 : 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (keyboardOpen ? 24 : 16),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: veryCompact ? 8 : 16,
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _submitted
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: keyboardOpen ? 8 : 28),
                                Center(
                                  child: Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      color: isDark ? colors.surface : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(isDark ? 0.10 : 0.13),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Center(child: _WalletLogo()),
                                  ),
                                ),
                                SizedBox(height: veryCompact ? 12 : 26),
                                Text(
                                  context.tr('welcome_back'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    color: isDark ? colors.onSurface : const Color(0xFF071A4A),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.tr('login_subtitle'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 14 : 16,
                                    color: isDark ? colors.onSurfaceVariant : const Color(0xFF7080A3),
                                  ),
                                ),
                                SizedBox(height: keyboardOpen ? 18 : compact ? 28 : 42),
                                _FieldLabel(
                                  text: context.tr('email_address'),
                                  color: isDark ? colors.onSurface : const Color(0xFF071A4A),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  enabled: !auth.isLoading,
                                  controller: _emailController,
                                  scrollPadding: const EdgeInsets.only(bottom: 100),
                                  autofillHints: const [AutofillHints.email],
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(fontSize: 16, color: colors.onSurface),
                                  decoration: _inputDecoration(
                                    context: context,
                                    hint: context.tr('enter_email'),
                                    icon: Icons.mail_outline_rounded,
                                    compact: compact,
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) return context.tr('email_required');
                                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                                      return context.tr('email_invalid');
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: veryCompact ? 12 : 20),
                                _FieldLabel(
                                  text: context.tr('password'),
                                  color: isDark ? colors.onSurface : const Color(0xFF071A4A),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  enabled: !auth.isLoading,
                                  controller: _passwordController,
                                  scrollPadding: const EdgeInsets.only(bottom: 100),
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!auth.isLoading) _handleLogin();
                                  },
                                  style: TextStyle(fontSize: 16, color: colors.onSurface),
                                  decoration: _inputDecoration(
                                    context: context,
                                    hint: context.tr('enter_password'),
                                    icon: Icons.lock_outline_rounded,
                                    compact: compact,
                                    suffix: IconButton(
                                      tooltip: _obscurePassword
                                          ? context.tr('show_password')
                                          : context.tr('hide_password'),
                                      onPressed: auth.isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF7180A1),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return context.tr('password_required');
                                    }
                                    return null;
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (_) => const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                    child: Text(
                                      context.tr('forgot_password_q'),
                                      style: const TextStyle(
                                        color: Color(0xFF0868F7),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: veryCompact ? 6 : 14),
                                SizedBox(
                                  height: compact ? 54 : 60,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0067F4), Color(0xFF2D8CFF)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0878F9).withOpacity(0.22),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        disabledBackgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              context.tr('login'),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: veryCompact ? 12 : 28),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: colors.outlineVariant)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      child: Text(context.tr('or'), style: TextStyle(color: colors.onSurfaceVariant)),
                                    ),
                                    Expanded(child: Divider(color: colors.outlineVariant)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        context.tr('no_account'),
                                        style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) => const RegisterScreen(),
                                                ),
                                              );
                                            },
                                      child: Text(
                                        context.tr('register'),
                                        style: const TextStyle(
                                          color: Color(0xFF0868F7),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: keyboardOpen ? 8 : 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    required bool compact,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF0868F7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFF8FAFF),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 14 : 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? theme.colorScheme.outlineVariant : const Color(0xFFDCE5F4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0868F7), width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _FieldLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _WalletLogo extends StatelessWidget {
  const _WalletLogo();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.account_balance_wallet_rounded,
      size: 48,
      color: Color(0xFF0868F7),
    );
  }
}