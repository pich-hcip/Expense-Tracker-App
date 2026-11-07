import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../models/otp_purpose.dart';
import '../../providers/auth_provider.dart';

import 'login_screen.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();

  Timer? _timer;

  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final otp = _otpController.text.trim();

    final success = await auth.verifyOtp(widget.email, otp, widget.purpose);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? context.tr('invalid_code')),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    // =======================================================
    // FORGOT PASSWORD
    // =======================================================

    if (widget.purpose == OtpPurpose.resetPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordScreen(email: widget.email, otp: otp),
        ),
      );

      return;
    }

    // =======================================================
    // REGISTER
    //
    // Registration verification does NOT log user in.
    // Go to Login so login API can return JWT.
    // =======================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('account_verified')),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.sendOtp(widget.email, widget.purpose);

    if (!mounted) return;

    if (success) {
      _otpController.clear();

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('code_resent')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? context.tr('resend_failed')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 55,
                      color: Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  context.tr('verify_email_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text(
                  context.tr('otp_sent_to'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 40),

                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 32),
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final otp = value?.trim() ?? '';

                    if (otp.isEmpty) {
                      return context.tr('otp_required');
                    }

                    if (otp.length != 6) {
                      return context.tr('otp_6_digits');
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading) {
                      _verifyOtp();
                    }
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('verify_code'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  context.tr('no_code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 8),

                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          context.tr('resend_in').replaceFirst('{s}', '$_secondsRemaining'),
                          style: const TextStyle(color: Colors.grey),
                        )
                      : TextButton(
                          onPressed: auth.isLoading ? null : _resendOtp,
                          child: Text(
                            context.tr('resend_code'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();

    super.dispose();
  }
}