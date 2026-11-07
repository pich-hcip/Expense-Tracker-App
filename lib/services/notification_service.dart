import '../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiClient.dio.get('/notifications');

    final List<dynamic> data = response.data as List<dynamic>;

    return data
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response =
        await ApiClient.dio.get('/notifications/unread-count');

    return (response.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await ApiClient.dio.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await ApiClient.dio.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await ApiClient.dio.delete('/notifications/$id');
  }
}