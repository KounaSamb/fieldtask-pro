import 'package:flutter_test/flutter_test.dart';
import 'package:fieldtask_pro/domain/entities/intervention.dart';

void main() {
  test('statut <-> texte', () {
    for (final s in InterventionStatus.values) {
      expect(InterventionStatusX.fromString(s.value), s);
    }
  });

  test('Intervention JSON aller-retour', () {
    final i = Intervention(
      id: 'INT-9', client: 'Test', adresse: 'Thies', latitude: 14.79,
      longitude: -16.92, description: 'd', equipement: 'e',
      statut: InterventionStatus.enCours, priorite: 'H',
      dateRdv: DateTime(2026, 10, 10, 9), notes: 'ok', synced: false);
    expect(Intervention.fromJson(i.toJson()), i);
  });

  test('copyWith marque le statut modifie', () {
    final i = Intervention.fromJson({
      'id': '1', 'client': 'c', 'statut': 'en_attente', 'synced': true});
    final j = i.copyWith(statut: InterventionStatus.terminee, synced: false);
    expect(j.statut, InterventionStatus.terminee);
    expect(j.synced, false);
  });
}
