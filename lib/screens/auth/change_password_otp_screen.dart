import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../services/change_password_service.dart';
import 'login_screen.dart';

class ChangePasswordOtpScreen extends StatefulWidget {
  final String newPassword;

  const ChangePasswordOtpScreen({super.key, required this.newPassword});

  @override
  State<ChangePasswordOtpScreen> createState() =>
      _ChangePasswordOtpScreenState();
}

class _ChangePasswordOtpScreenState extends State<ChangePasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();

  final ChangePasswordService _changePasswordService = ChangePasswordService();

  bool _isLoading = false;

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _changePasswordService.changePassword(
        otp: _otpController.text,
        newPassword: widget.newPassword,
      );

      if (!mounted) {
        return;
      }

      // Password successfully changed.
      //
      // Remove the old JWT from the device.
      await context.read<AuthProvider>().logout();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('password_changed')),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_changePasswordService.getErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('verify_otp'))),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const SizedBox(height: 40),

                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Colors.blue,
                ),

                const SizedBox(height: 25),

                Text(
                  context.tr('check_email'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text(
                  context.tr('change_otp_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),

                const SizedBox(height: 40),

                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 32),
                  controller: _otpController,

                  keyboardType: TextInputType.number,

                  textAlign: TextAlign.center,

                  maxLength: 6,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),

                  decoration: InputDecoration(
                    labelText: context.tr('otp_code'),

                    counterText: '',

                    prefixIcon: const Icon(Icons.verified_outlined),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  validator: (value) {
                    final otp = value?.trim() ?? '';

                    if (otp.isEmpty) {
                      return context.tr('enter_otp');
                    }

                    if (otp.length != 6) {
                      return context.tr('otp_must_6');
                    }

                    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                      return context.tr('otp_numbers_only');
                    }

                    return null;
                  },

                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _submit();
                    }
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,

                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('verify_change_password'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
    _otpController.dispose();

    super.dispose();
  }
}