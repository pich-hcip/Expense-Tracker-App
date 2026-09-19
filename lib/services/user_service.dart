import '../core/api_client.dart';
import '../models/user_profile_model.dart';

class UserService {
  Future<UserProfile> getProfile() async {
    final response = await ApiClient.dio.get('/users/me');
    return UserProfile.fromJson(response.data);
  }

  Future<void> updateAvatar(String avatarUrl) async {
    await ApiClient.dio.put('/users/me/avatar', data: {
      'avatarUrl': avatarUrl,
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phoneNumber,
  }) async {
    await ApiClient.dio.put('/users/me', data: {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    });
  }

}