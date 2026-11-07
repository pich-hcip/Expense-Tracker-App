import '../core/api_client.dart';
import '../models/user_profile_model.dart';

class UserService {
  // =========================================================
  // GET CURRENT USER
  // =========================================================

  Future<UserProfile> getProfile() async {
    final response =
        await ApiClient.dio.get(
      '/users/me',
    );

    return UserProfile.fromJson(
      response.data,
    );
  }

  // =========================================================
  // UPDATE AVATAR
  // =========================================================

  Future<void> updateAvatar(
    String avatarUrl,
  ) async {
    await ApiClient.dio.put(
      '/users/me/avatar',
      data: {
        'avatarUrl': avatarUrl,
      },
    );
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<UserProfile> updateProfile({
    required String fullName,
    required String email,
    String? phoneNumber,
  }) async {
    await ApiClient.dio.put(
      '/users/me',
      data: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
      },
    );
    final saved = await getProfile();
    String normalize(String? value) =>
        (value ?? '').trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (normalize(saved.phoneNumber) != normalize(phoneNumber)) {
      throw StateError(
        'The server did not retain your phone number. Please try again. '
        'If this continues, the profile API needs to support saving and returning phoneNumber.',
      );
    }
    return saved;
  }
}
