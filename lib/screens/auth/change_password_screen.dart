import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../services/change_password_service.dart';
import 'change_password_otp_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ChangePasswordService _changePasswordService =
      ChangePasswordService();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _changePasswordService.sendOtp(
        currentPassword: _currentPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('otp_sent_email')),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChangePasswordOtpScreen(
            newPassword: _newPasswordController.text,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _changePasswordService.getErrorMessage(e),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
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
    final keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(context.tr('change_password')),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,

              padding: EdgeInsets.fromLTRB(
                24,
                keyboardOpen ? 8 : 24,
                24,
                keyboardOpen ? 32 : 24,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      (keyboardOpen ? 40 : 48),
                ),

                child: Form(
                  key: _formKey,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      SizedBox(
                        height: keyboardOpen ? 8 : 20,
                      ),

                      Icon(
                        Icons.lock_outline_rounded,
                        size: keyboardOpen ? 45 : 70,
                        color: Colors.blue,
                      ),

                      SizedBox(
                        height: keyboardOpen ? 12 : 25,
                      ),

                      Text(
                        context.tr('change_password'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: keyboardOpen ? 22 : 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        context.tr('change_password_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      SizedBox(
                        height: keyboardOpen ? 20 : 35,
                      ),

                      // CURRENT PASSWORD
                      TextFormField(
                        controller: _currentPasswordController,
                        scrollPadding: const EdgeInsets.only(
                          bottom: 100,
                        ),
                        obscureText: _hideCurrentPassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,

                        decoration: InputDecoration(
                          labelText: context.tr('current_password'),
                          prefixIcon:
                              const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideCurrentPassword =
                                    !_hideCurrentPassword;
                              });
                            },
                            icon: Icon(
                              _hideCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return context.tr('current_password_required');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // NEW PASSWORD
                      TextFormField(
                        controller: _newPasswordController,
                        scrollPadding: const EdgeInsets.only(
                          bottom: 100,
                        ),
                        obscureText: _hideNewPassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,

                        decoration: InputDecoration(
                          labelText: context.tr('new_password'),
                          prefixIcon:
                              const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideNewPassword =
                                    !_hideNewPassword;
                              });
                            },
                            icon: Icon(
                              _hideNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('new_password_required');
                          }

                          if (value.length < 6) {
                            return context.tr('password_min');
                          }

                          if (value ==
                              _currentPasswordController.text) {
                            return context.tr('new_password_different');
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // CONFIRM PASSWORD
                      TextFormField(
                        controller: _confirmPasswordController,
                        scrollPadding: const EdgeInsets.only(
                          bottom: 100,
                        ),
                        obscureText: _hideConfirmPassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,

                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _sendOtp();
                          }
                        },

                        decoration: InputDecoration(
                          labelText: context.tr('confirm_new_password'),
                          prefixIcon:
                              const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideConfirmPassword =
                                    !_hideConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('confirm_new_password_required');
                          }

                          if (value !=
                              _newPasswordController.text) {
                            return context.tr('password_not_match');
                          }

                          return null;
                        },
                      ),

                      SizedBox(
                        height: keyboardOpen ? 24 : 35,
                      ),

                      // CONTINUE BUTTON
                      SizedBox(
                        height: 55,

                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _sendOtp,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),

                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr('continue'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}