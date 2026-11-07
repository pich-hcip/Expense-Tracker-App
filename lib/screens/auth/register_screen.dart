import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../models/otp_purpose.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

const Color kPrimaryBlue = Color(0xFF2563EB);
const Color kErrorRed = Colors.redAccent;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitted = false;

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return context.tr('full_name_required');
    }

    if (!RegExp(r'^[A-Za-z]+ [A-Za-z]+$').hasMatch(name)) {
      return context.tr('invalid_name');
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return context.tr('email_required');
    }

    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email)) {
      return context.tr('email_invalid');
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return context.tr('password_required');
    }

    if (password.length < 6) {
      return context.tr('password_min');
    }

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=]',
    ).hasMatch(password);

    if (!hasUpper || !hasLower || !hasNumber || !hasSymbol) {
      return context.tr('password_strength');
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('confirm_password_required');
    }

    if (value != _passwordController.text) {
      return context.tr('password_not_match');
    }

    return null;
  }

  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();

    if (auth.isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _submitted = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    final success = await auth.register(
      fullName,
      email,
      password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            email: email,
            purpose: OtpPurpose.register,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? context.tr('registration_failed'),
          ),
          backgroundColor: kErrorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openLogin() {
    if (context.read<AuthProvider>().isLoading) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final ink = dark
        ? colors.onSurface
        : const Color(0xFF080E38);

    final muted = dark
        ? colors.onSurfaceVariant
        : const Color(0xFF687595);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.surface,

      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? [
                          colors.surface,
                          colors.surfaceContainerLow,
                        ]
                      : [
                          const Color(0xFFF1F7FF),
                          Colors.white,
                          const Color(0xFFF8FBFF),
                        ],
                ),
              ),
            ),
          ),

          // Background circles
          Positioned(
            top: -145,
            left: -100,
            child: _bubble(300, dark),
          ),
          Positioned(
            top: -90,
            right: -130,
            child: _bubble(310, dark),
          ),
          Positioned(
            top: 120,
            right: -65,
            child: _bubble(145, dark),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keyboard-aware layout
                final keyboardOpen =
                    MediaQuery.viewInsetsOf(context).bottom > 0;

                final h = constraints.maxHeight;

                final compact = h < 850;
                final veryCompact = h < 720;

                final logoSize = veryCompact
                    ? 52.0
                    : compact
                        ? 62.0
                        : 76.0;

                Widget field(
                  String label,
                  String hint,
                  TextEditingController controller,
                  IconData icon, {
                  bool password = false,
                  bool confirm = false,
                  TextInputType? keyboard,
                  Iterable<String>? autofill,
                  String? Function(String?)? validator,
                }) {
                  final hidden = confirm
                      ? _obscureConfirmPassword
                      : _obscurePassword;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: veryCompact ? 6 : 10,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: ink,
                            fontSize: veryCompact ? 13 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(
                          height: veryCompact ? 4 : 6,
                        ),

                        TextFormField(
                          // Allows Flutter to scroll the field
                          // above the keyboard.
                          scrollPadding: const EdgeInsets.only(
                            bottom: 100,
                          ),
                          controller: controller,
                          enabled: !auth.isLoading,
                          keyboardType: keyboard,
                          autofillHints: autofill,
                          autocorrect: false,
                          enableSuggestions: !password,
                          obscureText: password && hidden,

                          textInputAction: confirm
                              ? TextInputAction.done
                              : TextInputAction.next,

                          onFieldSubmitted: confirm
                              ? (_) {
                                  if (!auth.isLoading) {
                                    _handleRegister();
                                  }
                                }
                              : null,

                          validator: validator,

                          style: TextStyle(
                            color: ink,
                            fontSize: 15,
                          ),

                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(color: muted),
                            filled: true,

                            fillColor: dark
                                ? colors.surfaceContainer
                                : const Color(0xFFF8FAFF),

                            isDense: true,

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: veryCompact
                                  ? 12
                                  : compact
                                      ? 14
                                      : 16,
                            ),

                            prefixIcon: Icon(
                              icon,
                              color: const Color(0xFF0860FF),
                              size: 22,
                            ),

                            prefixIconConstraints:
                                const BoxConstraints(
                              minWidth: 50,
                              minHeight: 44,
                            ),

                            suffixIcon: password
                                ? IconButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              if (confirm) {
                                                _obscureConfirmPassword =
                                                    !hidden;
                                              } else {
                                                _obscurePassword =
                                                    !hidden;
                                              }
                                            });
                                          },

                                    icon: Icon(
                                      hidden
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: muted,
                                      size: 21,
                                    ),
                                  )
                                : null,

                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: dark
                                    ? colors.outlineVariant
                                    : const Color(0xFFD4E2FF),
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF0860FF),
                                width: 1.5,
                              ),
                            ),

                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              height: 1.15,
                            ),
                            errorMaxLines: 2,

                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),

                            focusedErrorBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,

                  // Additional scroll space when typing.
                  padding: EdgeInsets.only(
                    bottom: keyboardOpen ? 32 : 12,
                  ),

                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: h - (keyboardOpen ? 32 : 12),
                    ),

                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 520,
                        ),

                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            keyboardOpen
                                ? 4
                                : veryCompact
                                    ? 4
                                    : 8,
                            24,
                            veryCompact ? 4 : 10,
                          ),

                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,

                              autovalidateMode: _submitted
                                  ? AutovalidateMode
                                      .onUserInteraction
                                  : AutovalidateMode.disabled,

                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,

                                children: [
                                  // Back button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: veryCompact ? 38 : 44,
                                      height: veryCompact ? 38 : 44,

                                      child: IconButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : _openLogin,

                                        icon: const Icon(
                                          Icons
                                              .arrow_back_ios_new_rounded,
                                          color: Color(0xFF0860FF),
                                          size: 19,
                                        ),

                                        style: IconButton.styleFrom(
                                          backgroundColor: dark
                                              ? colors
                                                  .surfaceContainer
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 2 : 4,
                                  ),

                                  // Logo
                                  Center(
                                    child: Container(
                                      width: logoSize,
                                      height: logoSize,

                                      decoration: BoxDecoration(
                                        color: dark
                                            ? colors
                                                .surfaceContainerHigh
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),

                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            color:
                                                const Color(0xFFFFBE2D),
                                            size: logoSize * .40,
                                          ),

                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                              top: 13,
                                            ),
                                            child: Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              color:
                                                  const Color(0xFF0860FF),
                                              size: logoSize * .58,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 5 : 10,
                                  ),

                                  // Title
                                  Text(
                                    context.tr('create_account'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: veryCompact
                                          ? 24
                                          : compact
                                              ? 27
                                              : 30,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 2 : 5,
                                  ),

                                  Text(
                                    context.tr('register_subtitle'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize:
                                          veryCompact ? 12 : 14,
                                    ),
                                  ),

                                  SizedBox(
                                    height: keyboardOpen
                                        ? 8
                                        : veryCompact
                                            ? 8
                                            : 14,
                                  ),

                                  // Full name
                                  field(
                                    context.tr('full_name'),
                                    context.tr('enter_full_name'),
                                    _fullNameController,
                                    Icons.person_outline_rounded,
                                    autofill: const [
                                      AutofillHints.name,
                                    ],
                                    validator: _validateFullName,
                                  ),

                                  // Email
                                  field(
                                    context.tr('email_address'),
                                    context.tr('enter_email'),
                                    _emailController,
                                    Icons.mail_outline_rounded,
                                    keyboard:
                                        TextInputType.emailAddress,
                                    autofill: const [
                                      AutofillHints.email,
                                    ],
                                    validator: _validateEmail,
                                  ),

                                  // Password
                                  field(
                                    context.tr('password'),
                                    context.tr('enter_password'),
                                    _passwordController,
                                    Icons.lock_outline_rounded,
                                    password: true,
                                    autofill: const [
                                      AutofillHints.newPassword,
                                    ],
                                    validator: _validatePassword,
                                  ),

                                  // Confirm password
                                  field(
                                    context.tr('confirm_password'),
                                    context.tr('confirm_password_hint'),
                                    _confirmPasswordController,
                                    Icons.lock_outline_rounded,
                                    password: true,
                                    confirm: true,
                                    autofill: const [
                                      AutofillHints.newPassword,
                                    ],
                                    validator:
                                        _validateConfirmPassword,
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 2 : 5,
                                  ),

                                  // Create account button
                                  SizedBox(
                                    height: veryCompact ? 48 : 54,

                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                          colors: [
                                            Color(0xFF0059F5),
                                            Color(0xFF287CFF),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),

                                      child: ElevatedButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : _handleRegister,

                                        style:
                                            ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shadowColor:
                                              Colors.transparent,
                                          foregroundColor: Colors.white,
                                        ),

                                        child: auth.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                context.tr('create_account'),
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 6 : 10,
                                  ),

                                  // OR divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color:
                                              colors.outlineVariant,
                                        ),
                                      ),

                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          context.tr('or'),
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Divider(
                                          color:
                                              colors.outlineVariant,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(
                                    height: veryCompact ? 0 : 3,
                                  ),

                                  // Login navigation
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          context.tr('have_account'),
                                          style: TextStyle(
                                            color: muted,
                                            fontSize:
                                                veryCompact ? 12 : 14,
                                          ),
                                        ),
                                      ),

                                      TextButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : _openLogin,
                                        child: Text(
                                          context.tr('login'),
                                          style: const TextStyle(
                                            color:
                                                Color(0xFF0860FF),
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(
                                    height: keyboardOpen ? 8 : 12,
                                  ),
                                ],
                              ),
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

  Widget _bubble(double size, bool dark) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF9CCAFF).withValues(
            alpha: dark ? 0.08 : 0.19,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}