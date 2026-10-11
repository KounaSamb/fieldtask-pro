import '../../domain/entities/intervention.dart';
import '../../domain/entities/intervention_status.dart';
import '../../domain/repositories/intervention_repository_interface.dart';
import 'intervention_repository.dart';

/// Implementation de l'interface du Domain : delegue au repository existant
/// (SQLite + API REST + file de synchronisation).
class InterventionRepositoryImpl implements IInterventionRepository {
  final InterventionRepository _inner;
  InterventionRepositoryImpl([InterventionRepository? inner])
      : _inner = inner ?? InterventionRepository();

  @override
  List<Intervention> getAll() => _inner.getAll();

  @override
  Future<void> updateStatus(String id, InterventionStatus statut) async {
    await _inner.updateStatus(id, statut);
  }

  @override
  Future<int> processSyncQueue() => _inner.processSyncQueue();

  @override
  Future<void> refreshFromServer() async {
    await _inner.refreshFromServer();
  }
}