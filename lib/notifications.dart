import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificações Importantes',
  description: 'Canal para notas criadas',
  importance: Importance.max,
);

class Notifications {
  static Future<void> init() async {
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    // CORREÇÃO: Adicionado o parâmetro nomeado 'settings'
    await _notifications.initialize(settings: init);
    
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    // CORREÇÃO: Todos os argumentos agora são nomeados (id:, title:, body:, notificationDetails:)
    return _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          channelDescription: 'Canal para notas criadas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}