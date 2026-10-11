import 'package:flutter_test/flutter_test.dart';
import 'package:fieldtask_pro/domain/entities/intervention.dart';
import 'package:fieldtask_pro/domain/entities/intervention_status.dart';
import 'package:fieldtask_pro/domain/entities/user.dart';
import 'package:fieldtask_pro/domain/repositories/auth_repository_interface.dart';
import 'package:fieldtask_pro/domain/repositories/intervention_repository_interface.dart';
import 'package:fieldtask_pro/domain/usecases/auth_usecases.dart';
import 'package:fieldtask_pro/domain/usecases/intervention_usecases.dart';

class FakeInterventionRepo implements IInterventionRepository {
  String? lastId;
  InterventionStatus? lastStatus;
  bool pulled = false;

  @override
  List<Intervention> getAll() => <Intervention>[];

  @override
  Future<void> updateStatus(String id, InterventionStatus statut) async {
    lastId = id;
    lastStatus = statut;
  }

  @override
  Future<int> processSyncQueue() async => 3;

  @override
  Future<void> refreshFromServer() async => pulled = true;
}

class FakeAuthRepo implements IAuthRepository {
  bool loggedOut = false;

  @override
  Future<User> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<void> logout() async => loggedOut = true;
}

void main() {
  test('GetInterventions lit la liste du repository', () {
    expect(GetInterventions(FakeInterventionRepo())(), isEmpty);
  });

  test('ChangeInterventionStatus transmet id et statut', () async {
    final repo = FakeInterventionRepo();
    await ChangeInterventionStatus(repo)('INT-001', InterventionStatus.terminee);
    expect(repo.lastId, 'INT-001');
    expect(repo.lastStatus, InterventionStatus.terminee);
  });

  test('PushPendingChanges retourne le nombre envoye', () async {
    expect(await PushPendingChanges(FakeInterventionRepo())(), 3);
  });

  test('PullFromServer appelle le repository', () async {
    final repo = FakeInterventionRepo();
    await PullFromServer(repo)();
    expect(repo.pulled, isTrue);
  });

  test('RestoreSessionUseCase retourne null sans session', () async {
    expect(await RestoreSessionUseCase(FakeAuthRepo())(), isNull);
  });

  test('LogoutUseCase deconnecte', () async {
    final repo = FakeAuthRepo();
    await LogoutUseCase(repo)();
    expect(repo.loggedOut, isTrue);
  });
}
