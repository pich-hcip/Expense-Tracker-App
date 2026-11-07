import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';

import '../services/user_service.dart';
import '../models/user_profile_model.dart';
import 'edit_profile.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _error;

  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  String _defaultCurrency = 'USD';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profile = await _userService.getProfile();

      if (!mounted) return;

      setState(() {
        _fullName = profile.fullName;
        _email = profile.email;

        _phoneNumber = profile.phoneNumber?.trim() ?? '';
        _defaultCurrency = profile.defaultCurrency;

        _avatarUrl = profile.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'personal_info_load_error';
      });
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute<UserProfile>(
        builder: (_) => const EditProfilePage(),
      ),
    );

    if (!mounted) return;

    if (saved != null) {
      setState(() {
        _fullName = saved.fullName;
        _email = saved.email;
        _phoneNumber = saved.phoneNumber?.trim() ?? '';
        _defaultCurrency = saved.defaultCurrency;
        _avatarUrl = saved.avatarUrl;
        _error = null;
      });
      return;
    }
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('personal_information'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        _buildErrorMessage(),
                        const SizedBox(height: 20),
                      ],

                      // ========================================
                      // PROFILE PHOTO
                      // ========================================

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primaryContainer,
                                border: Border.all(
                                  color: colorScheme.primary,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildAvatar(),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              _fullName.isEmpty ? context.tr('user') : _fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _email,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ========================================
                      // ACCOUNT INFORMATION
                      // ========================================

                      Text(
                        context.tr('account_information'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInformationItem(
                              context,
                              icon: Icons.person_outline,
                              title: context.tr('full_name'),
                              value: _fullName.isEmpty
                                  ? context.tr('not_added')
                                  : _fullName,
                            ),

                            _divider(context),

                            _buildInformationItem(
                              context,
                              icon: Icons.email_outlined,
                              title: context.tr('email_address'),
                              value: _email.isEmpty
                                  ? context.tr('not_added')
                                  : _email,
                            ),

                            _divider(context),

                            _buildInformationItem(
                              context,
                              icon: Icons.phone_outlined,
                              title: context.tr('phone_number'),
                              value: _phoneNumber.isEmpty
                                  ? context.tr('not_added')
                                  : _phoneNumber,
                            ),

                            _divider(context),

                            _buildInformationItem(
                              context,
                              icon: Icons.attach_money,
                              title: context.tr('default_currency'),
                              value: '$_defaultCurrency (\$)',
                            ),

                            _divider(context),

                            _buildInformationItem(
                              context,
                              icon: Icons.verified_user_outlined,
                              title: context.tr('account_status'),
                              value: context.tr('verified'),
                              valueColor: Colors.green,
                              trailingIcon: Icons.check_circle,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ========================================
                      // EDIT BUTTON
                      // ========================================

                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          label: Text(
                            context.tr('edit_profile'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        context.tr('password_note'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Widget _buildAvatar() {
    if (_avatarUrl != null && _avatarUrl!.trim().isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return _buildFallbackAvatar();
        },
      );
    }

    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final firstLetter =
        _fullName.trim().isNotEmpty ? _fullName.trim()[0].toUpperCase() : 'U';

    return Container(
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // INFORMATION ITEM
  // =========================================================

  Widget _buildInformationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    IconData? trailingIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          if (trailingIcon != null)
            Icon(
              trailingIcon,
              size: 20,
              color: valueColor ?? colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withOpacity(0.5),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(_error!),
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(
              Icons.refresh,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}