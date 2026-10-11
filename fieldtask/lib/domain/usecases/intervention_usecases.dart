import '../entities/intervention.dart';
import '../entities/intervention_status.dart';
import '../repositories/intervention_repository_interface.dart';

/// Lit les interventions depuis le stockage local.
class GetInterventions {
  final IInterventionRepository _repo;
  GetInterventions(this._repo);
  List<Intervention> call() => _repo.getAll();
}

/// Change le statut d'une intervention (ecriture locale + file de synchro).
class ChangeInterventionStatus {
  final IInterventionRepository _repo;
  ChangeInterventionStatus(this._repo);
  Future<void> call(String id, InterventionStatus statut) =>
      _repo.updateStatus(id, statut);
}

/// Envoie au serveur les modifications en attente.
class PushPendingChanges {
  final IInterventionRepository _repo;
  PushPendingChanges(this._repo);
  Future<int> call() => _repo.processSyncQueue();
}

/// Rafraichit la base locale depuis le serveur.
class PullFromServer {
  final IInterventionRepository _repo;
  PullFromServer(this._repo);
  Future<void> call() => _repo.refreshFromServer();
}
