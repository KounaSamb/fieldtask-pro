// Tests FieldTask Pro  -  commande : flutter test
//
// Les anciens tests d'ecran (demarrage, connexion, filtres...) supposaient
// SharedPreferences et une connexion simulee. L'app utilise maintenant SQLite
// et JSON-Server : ces tests de bout en bout se font a la main (voir README).
// Ici : tests unitaires (domaine) + test du widget de connexion.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldtask_pro/core/services/notification_service.dart';
import 'package:fieldtask_pro/domain/entities/intervention.dart';
import 'package:fieldtask_pro/domain/entities/user.dart';
import 'package:fieldtask_pro/presentation/blocs/auth_cubit.dart';
import 'package:fieldtask_pro/presentation/pages/login_page.dart';

Intervention _make({InterventionStatus s = InterventionStatus.enAttente, DateTime? rdv}) =>
    Intervention(
      id: 'INT-100',
      client: 'Test Client',
      adresse: 'Dakar',
      latitude: 14.6,
      longitude: -17.4,
      description: 'Description test',
      equipement: 'Equipement test',
      statut: s,
      priorite: 'H',
      dateRdv: rdv ?? DateTime(2026, 10, 3, 14, 30),
      notes: '',
      synced: false,
    );

void main() {
  // ---------------- Widget : ecran de connexion ----------------
  testWidgets('L\'ecran de connexion affiche ses champs',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(create: (_) => AuthCubit(), child: const LoginPage()),
    ));
    await tester.pump();

    expect(find.text('SE CONNECTER'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  // ---------------- Unitaires : domaine ----------------
  test('Intervention - serialisation/deserialisation JSON', () {
    final restored = Intervention.fromJson(_make(s: InterventionStatus.enCours).toJson());
    expect(restored.id, 'INT-100');
    expect(restored.client, 'Test Client');
    expect(restored.statut, InterventionStatus.enCours);
    expect(restored.priorite, 'H');
    expect(restored.synced, false);
  });

  test('InterventionStatus - conversion valeur/libelle', () {
    expect(InterventionStatus.enAttente.value, 'en_attente');
    expect(InterventionStatus.enCours.value, 'en_cours');
    expect(InterventionStatus.terminee.value, 'terminee');
    expect(InterventionStatus.enAttente.label, 'En attente');
    expect(InterventionStatus.enCours.label, 'En cours');
    expect(InterventionStatus.terminee.label, 'Terminée');
    expect(InterventionStatusX.fromString('en_cours'), InterventionStatus.enCours);
    expect(InterventionStatusX.fromString('inconnu'), InterventionStatus.enAttente);
  });

  test('User - serialisation JSON', () {
    const user = User(
      id: '1', email: 'test@techfix.sn', nom: 'Test User', role: 'Technicien',
      matricule: 'MAT-0001', telephone: '+221770000000', token: 'token-xyz');
    final restored = User.fromJson(user.toJson());
    expect(restored.email, 'test@techfix.sn');
    expect(restored.token, 'token-xyz');
    expect(restored.matricule, 'MAT-0001');
  });

  test('Intervention.copyWith change le statut et marque non synchronise', () {
    final updated = _make().copyWith(statut: InterventionStatus.enCours, synced: false);
    expect(updated.statut, InterventionStatus.enCours);
    expect(updated.synced, false);
    expect(updated.id, 'INT-100');
  });

  test('Intervention.fromJson accepte synced = 1 (SQLite)', () {
    final j = _make().toJson()..['synced'] = 1;
    expect(Intervention.fromJson(j).synced, true);
  });

  test('Rappel programme 30 min avant le RDV', () {
    final now = DateTime(2026, 10, 10, 8, 0);
    final i = _make(rdv: DateTime(2026, 10, 10, 10, 0));
    expect(NotificationService.reminderTime(i, now: now),
        DateTime(2026, 10, 10, 9, 30));
  });

  test('Pas de rappel si terminee ou si l\'heure est passee', () {
    final now = DateTime(2026, 10, 10, 8, 0);
    final done = _make(s: InterventionStatus.terminee, rdv: DateTime(2026, 10, 10, 10));
    final past = _make(rdv: DateTime(2026, 10, 10, 8, 10));
    expect(NotificationService.reminderTime(done, now: now), isNull);
    expect(NotificationService.reminderTime(past, now: now), isNull);
  });

  test('User.copyWith modifie nom/email/telephone sans toucher au reste', () {
    const u = User(
      id: '1', email: 'a@b.sn', nom: 'Ancien', role: 'Technicien',
      matricule: 'MAT-1', telephone: '770000000', token: 't');
    final v = u.copyWith(nom: 'Nouveau', telephone: '771111111');
    expect(v.nom, 'Nouveau');
    expect(v.telephone, '771111111');
    expect(v.email, 'a@b.sn');
    expect(v.matricule, 'MAT-1');
    expect(v.token, 't');
  });
}
