import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/toast.dart';
import '../../domain/entities/intervention.dart';

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

/// Cloche : liste des rappels programmes + boutons de test.
Future<void> showRemindersDialog(BuildContext context, List<Intervention> list) {
  final svc = NotificationService.instance;
  final upcoming = <MapEntry<Intervention, DateTime>>[
    for (final i in list)
      if (NotificationService.reminderTime(i) != null)
        MapEntry(i, NotificationService.reminderTime(i)!),
  ]..sort((a, b) => a.value.compareTo(b.value));

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rappels d\'interventions'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!svc.isSupported)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Les notifications système fonctionnent sur Android, iOS et '
                    'macOS. Ici, la liste montre les rappels qui seraient programmés.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              if (upcoming.isEmpty)
                const Text(
                    'Aucun rappel à venir (rappel = 30 min avant l\'heure du RDV).')
              else
                for (final e in upcoming)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm),
                    title: Text('${e.key.id} · ${e.key.client}'),
                    subtitle: Text('Rappel le ${_fmt(e.value)}'),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final ok = await svc.showNow(
                'Test FieldTask Pro', 'Les notifications fonctionnent ✅');
            if (ctx.mounted) {
              showToast(ctx, ok ? 'Notification envoyée' : 'Non supporté ici');
            }
          },
          child: const Text('Tester'),
        ),
        TextButton(
          onPressed: () async {
            final ok = await svc.scheduleIn(const Duration(minutes: 1),
                'Intervention imminente', 'Rappel de test programmé ⏰');
            if (ctx.mounted) {
              showToast(ctx, ok ? 'Rappel dans ~1 min' : 'Non supporté ici');
            }
          },
          child: const Text('Rappel +1 min'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
