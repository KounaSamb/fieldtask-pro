import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/intervention.dart';

/// Rappels locaux : une notification 30 min avant chaque intervention
/// non terminee. Supporte Android, iOS et macOS (sans effet ailleurs).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const reminderLead = Duration(minutes: 30);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get isSupported => _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'rappels',
      'Rappels d\'intervention',
      channelDescription: 'Rappel avant une intervention imminente',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    final p = defaultTargetPlatform;
    final supported = !kIsWeb &&
        (p == TargetPlatform.android ||
            p == TargetPlatform.iOS ||
            p == TargetPlatform.macOS);
    if (!supported) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ));
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications indisponibles : $e');
    }
  }

  /// Heure du rappel, ou null s'il ne faut pas en programmer.
  static DateTime? reminderTime(Intervention i, {DateTime? now}) {
    if (i.statut == InterventionStatus.terminee) return null;
    final when = i.dateRdv.subtract(reminderLead);
    return when.isAfter(now ?? DateTime.now()) ? when : null;
  }

  int _idFor(String interventionId) => interventionId.codeUnits
      .fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);

  /// Programme / annule les rappels selon l'etat actuel des interventions.
  Future<void> syncReminders(List<Intervention> list) async {
    if (!_ready) return;
    for (final i in list) {
      try {
        final id = _idFor(i.id);
        final when = reminderTime(i);
        if (when == null) {
          await _plugin.cancel(id);
          continue;
        }
        await _plugin.zonedSchedule(
          id,
          'Intervention imminente',
          '${i.client} - ${i.adresse}',
          tz.TZDateTime.from(when, tz.local),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Rappel non programme pour ${i.id} : $e');
      }
    }
  }

  /// Programme une notification de test dans [delay] (verifie la planification).
  Future<bool> scheduleIn(Duration delay, String title, String body) async {
    if (!_ready) return false;
    try {
      await _plugin.zonedSchedule(
        1,
        title,
        body,
        tz.TZDateTime.from(DateTime.now().add(delay), tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Notification immediate (bouton de test). Renvoie false si non supporte.
  Future<bool> showNow(String title, String body) async {
    if (!_ready) return false;
    try {
      await _plugin.show(0, title, body, _details);
      return true;
    } catch (_) {
      return false;
    }
  }
}
