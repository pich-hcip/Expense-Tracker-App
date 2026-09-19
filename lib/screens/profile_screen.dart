import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../services/image_upload_service.dart';
import '../services/user_service.dart';
import '../screens/auth/login_screen.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const Color primaryBlue = Color(0xFF2458C6);
  static const Color textColor = Color(0xFF17213D);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _error;
  UserProfile? _profile;

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
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final url = await _uploadService.uploadImage(pickedFile);
      await _userService.updateAvatar(url);

      setState(() {
        _profile = UserProfile(
          id: _profile!.id,
          fullName: _profile!.fullName,
          email: _profile!.email,
          avatarUrl: url,
          defaultCurrency: _profile!.defaultCurrency,
        );
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update photo. Try again.')),
      );
    }
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= HEADER =================
                        Row(
                          children: [
                            Container(
                              width: 37,
                              height: 37,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FD),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 19,
                                  color: ProfileScreen.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Profile  ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ProfileScreen  .textColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Edit profile',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 25,
                                color: ProfileScreen .primaryBlue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ================= PROFILE CARD =================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3A55D8), Color(0xFF18285E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _isUploadingPhoto ? null : _changePhoto,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white24,
                                      ),
                                      child: _isUploadingPhoto
                                          ? const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : ClipOval(
                                              child: _profile?.avatarUrl != null
                                                  ? Image.network(_profile!.avatarUrl!, fit: BoxFit.cover)
                                                  : const Icon(Icons.person, color: Colors.white, size: 34),
                                            ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: ProfileScreen.primaryBlue, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profile?.fullName ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      _profile?.email ?? '',
                                      style: const TextStyle(color: Color(0xFFD9E1FF), fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ================= MENU =================
                        _menuItem(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                          onTap: () {},
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap: () {},
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment Methods',
                          onTap: () {},
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.language,
                          title: 'Currency',
                          trailingText: _profile?.defaultCurrency ?? 'USD',
                          onTap: () {},
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.notifications_none,
                          title: 'Notification Settings',
                          onTap: () {},
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {},
                        ),

                        const SizedBox(height: 42),

                        // ================= SIGN OUT =================
                        _menuItem(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          isLogout: true,
                          onTap: _handleSignOut,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 47,
        child: Row(
          children: [
            Icon(icon, size: 21, color: isLogout ? const Color(0xFFFF4D4D) : ProfileScreen.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isLogout ? const Color(0xFFFF4D4D) : ProfileScreen.textColor,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 12, color: ProfileScreen.primaryBlue, fontWeight: FontWeight.w500),
              ),
            const SizedBox(width: 13),
            const Icon(Icons.chevron_right, size: 21, color: Color(0xFF65728A)),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 37),
      child: Divider(height: 1, thickness: 0.7, color: Color(0xFFF0F2F5)),
    );
  }
}