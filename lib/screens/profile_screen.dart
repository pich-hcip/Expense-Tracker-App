import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../models/user_profile_model.dart';

import 'auth/login_screen.dart';
import 'auth/change_password_screen.dart';
import 'edit_profile.dart';
import 'personal_information_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profile = await _userService.getProfile();

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();

      authProvider.updateProfile(
        fullName: profile.fullName,
        email: profile.email,
        profileImageUrl: profile.avatarUrl,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'profile_load_error';
      });
    }
  }

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute<UserProfile>(builder: (_) => const EditProfilePage()),
    );

    if (!mounted) return;

    await _loadUserProfile();
  }

  // =========================================================
  // PERSONAL INFORMATION
  // =========================================================

  Future<void> _openPersonalInformation() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PersonalInformationScreen(),
      ),
    );

    if (!mounted) return;

    await _loadUserProfile();
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // =========================================================
  // CURRENCY
  // =========================================================

  void _openCurrency() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('currency'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  context.tr('choose_currency'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 16),

                // For now USD is your current project currency.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Text('\$')),
                  title: const Text(
                    'USD',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.tr('us_dollar')),
                  trailing: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Text('៛')),
                  title: const Text(
                    'KHR',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.tr('khmer_riel')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('khr_coming')),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // NOTIFICATION SETTINGS
  // =========================================================

  void _openNotifications() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationScreen()),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // =========================================================
  // LOGOUT DIALOG
  // =========================================================

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('sign_out')),
          content: Text(context.tr('sign_out_confirm')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleLogout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(context.tr('sign_out')),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    final colorScheme = Theme.of(context).colorScheme;

    final String userName = authProvider.fullName ?? '';
    final String userEmail = authProvider.email ?? '';
    final String? profileImageUrl = authProvider.profileImageUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark
        ? const Color(0xFF101318)
        : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: pageColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        actionsPadding: const EdgeInsets.only(right: 12),
        title: Text(
          context.tr('account'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? context.tr('light_mode')
                : context.tr('dark_mode'),
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =====================================
                      // ERROR
                      // =====================================
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
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
                                onPressed: _loadUserProfile,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // =====================================
                      // PROFILE HEADER
                      // =====================================
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2463DB), Color(0xFF20479C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                              child: ClipOval(
                                child: _buildProfileAvatar(
                                  userName: userName,
                                  profileImageUrl: profileImageUrl,
                                ),
                              ),
                            ),

                            const SizedBox(width: 18),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName.isNotEmpty ? userName : context.tr('user'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =====================================
                      // EDIT PROFILE
                      // =====================================
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              label: context.tr('edit_profile'),
                              icon: Icons.manage_accounts_outlined,
                              onPressed: _openEditProfile,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildQuickAction(
                              label: context.tr('settings'),
                              icon: Icons.settings_outlined,
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // =====================================
                      // ACCOUNT
                      // =====================================
                      _buildSectionLabel(context.tr('account')),
                      const SizedBox(height: 10),
                      _buildMenuGroup([
                        _buildMenuItem(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: context.tr('personal_information'),
                          subtitle: context.tr('personal_info_sub'),
                          onTap: _openPersonalInformation,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: context.tr('change_password'),
                          subtitle: context.tr('change_password_sub'),
                          onTap: _openChangePassword,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionLabel(context.tr('preferences')),
                      const SizedBox(height: 10),
                      _buildMenuGroup([
                        _buildMenuItem(
                          context,
                          icon: Icons.language_rounded,
                          title: context.tr('currency'),
                          subtitle: context.tr('default_currency'),
                          trailingText: 'USD (\$)',
                          onTap: _openCurrency,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.notifications_none_rounded,
                          title: context.tr('notifications'),
                          subtitle: context.tr('notifications_sub'),
                          onTap: _openNotifications,
                        ),
                        // Language: opens Settings, where the picker is
                        _buildMenuItem(
                          context,
                          icon: Icons.translate_rounded,
                          title: context.tr('language'),
                          subtitle: context.tr('language_sub'),
                          trailingText:
                              languageProvider.isKhmer ? 'ខ្មែរ' : 'English',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 26),

                      // =====================================
                      // SIGN OUT
                      // =====================================
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            context.tr('sign_out'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.redAccent,
                          ),
                          onTap: _showLogoutDialog,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =====================================
                      // APP VERSION
                      // =====================================
                      Center(
                        child: Text(
                          context.tr('app_name'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Center(
                        child: Text(
                          context.tr('version'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
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

  // =========================================================
  // AVATAR
  // =========================================================

  Widget _buildProfileAvatar({
    required String userName,
    required String? profileImageUrl,
  }) {
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      return Image.network(
        profileImageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return _fallbackAvatar(userName);
            },
      );
    }

    return _fallbackAvatar(userName);
  }

  Widget _fallbackAvatar(String userName) {
    final String letter = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';

    return Container(
      alignment: Alignment.center,
      color: const Color(0xFF1E3A8A),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1A1F27) : Colors.white,
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          elevation: isDark ? 0 : 1,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
            color: isDark ? const Color(0xFF282F39) : const Color(0xFFE0E4EA),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 25,
                color: isDark ? colors.primary : const Color(0xFF005BBB),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A1F27) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF282F39) : const Color(0xFFE7EBF0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    String? trailingText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 12,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: colors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colors.onSurfaceVariant.withValues(alpha: 0.65),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}