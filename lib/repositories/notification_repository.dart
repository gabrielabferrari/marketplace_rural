import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../models/app_notification.dart';
import '../models/json_utils.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final data = await _api.get(Endpoints.notifications);
    return Json.list(data).map(AppNotification.fromJson).toList();
  }

  Future<void> markAllRead() => _api.post(Endpoints.notificationsRead);
}
