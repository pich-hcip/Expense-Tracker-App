import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/image_upload_service.dart';
import '../services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final UserService _userService = UserService();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _avatarUrl;

  // New photo picked but NOT uploaded yet (uploads only when Save is tapped)
  XFile? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _userService.getProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? '';
        _avatarUrl = profile.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'profile_load_error';
        _isLoading = false;
      });
    }
  }

  // Only pick and preview the photo, do not upload
  Future<void> _changePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _pickedPhoto = pickedFile);
  }

  void _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload the new photo only now (if the user picked one)
      if (_pickedPhoto != null) {
        final objectKey = await _uploadService.uploadImage(_pickedPhoto!);
        await _userService.updateAvatar(objectKey);
      }

      // 2. Save name and phone
      final savedProfile = await _userService.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim().replaceAll(RegExp(r'[\s()-]'), ''),
      );

      // 3. Photo changed: get the new https link so other screens update
      if (_pickedPhoto != null) {
        final profile = await _userService.getProfile();
        if (mounted && profile.avatarUrl != null) {
          context.read<AuthProvider>().updateProfileImage(profile.avatarUrl!);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('profile_updated'))));
      Navigator.pop(context, savedProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError
                ? e.message.toString()
                : context.tr('confirm_changes_failed'),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(_error!),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProfile,
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final primaryColor = theme.colorScheme.primary;

    final personIcon = Icon(
      Icons.person,
      size: 48,
      color: isDark
          ? theme.colorScheme.onSurfaceVariant
          : const Color(0xFFB6C0D9),
    );

    // Only load real web links
    final hasAvatar =
        _avatarUrl != null && _avatarUrl!.startsWith('http');

    // Preview: new picked photo first, then saved photo, then icon
    Widget avatarImage;
    if (_pickedPhoto != null) {
      avatarImage = Image.file(
        File(_pickedPhoto!.path),
        fit: BoxFit.cover,
      );
    } else if (hasAvatar) {
      avatarImage = CachedNetworkImage(
        imageUrl: _avatarUrl!,
        // Same file = same cache, even when the S3 link changes
        cacheKey: Uri.parse(_avatarUrl!).path,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => personIcon,
      );
    } else {
      avatarImage = personIcon;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  children: [
                    _EditHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 28),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? theme.colorScheme.outlineVariant
                                    : const Color(0xFFE7ECF7),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(child: avatarImage),
                          ),
                          Positioned(
                            right: -2,
                            bottom: 2,
                            child: Material(
                              color: primaryColor,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _isSaving ? null : _changePhoto,
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 31,
                                  height: 31,
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 29),
                    _ProfileField(
                      label: context.tr('full_name'),
                      controller: _nameController,
                      readOnly: _isSaving,
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? context.tr('full_name_required')
                          : null,
                    ),
                    const SizedBox(height: 17),
                    _ProfileField(
                      label: context.tr('phone_optional'),
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      readOnly: _isSaving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final phone = (value ?? '').trim();
                        if (phone.isEmpty) return null;
                        final normalized = phone.replaceAll(
                          RegExp(r'[\s()-]'),
                          '',
                        );
                        if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
                          return context.tr('phone_invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),
                    _ProfileField(
                      label: context.tr('email_address'),
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      readOnly: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5)
                          : const Color(0xFFF1F5F9),
                      suffixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: isDark
                            ? theme.colorScheme.outline
                            : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('save_changes'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 37,
              height: 37,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 19,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          context.tr('edit_profile'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.fillColor,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultFillColor = isDark
        ? theme.colorScheme.surfaceContainer
        : const Color(0xFFFAFBFD);

    final defaultBorderColor = isDark
        ? theme.colorScheme.outlineVariant
        : const Color(0xFFE1E6EF);

    final readOnlyBorderColor = isDark
        ? theme.colorScheme.outlineVariant.withOpacity(0.5)
        : const Color(0xFFCBD5E1);

    final labelColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF4F5870);

    final textColor = readOnly
        ? (isDark
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : const Color(0xFF64748B))
        : theme.colorScheme.onSurface;

    final iconColor = readOnly
        ? (isDark ? theme.colorScheme.outline : const Color(0xFF94A3B8))
        : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          scrollPadding: const EdgeInsets.only(bottom: 32),
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? defaultFillColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: readOnly ? readOnlyBorderColor : defaultBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: readOnly
                    ? readOnlyBorderColor
                    : theme.colorScheme.primary,
                width: readOnly ? 1.0 : 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}