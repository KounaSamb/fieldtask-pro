import '../entities/intervention.dart';
import '../entities/intervention_status.dart';

/// Contrat du repository des interventions (couche Domain).
/// L'implementation (SQLite + API REST) est dans la couche Data.
abstract class IInterventionRepository {
  List<Intervention> getAll();
  Future<void> updateStatus(String id, InterventionStatus statut);

  /// Envoie la file de synchronisation. Retourne le nombre d'elements envoyes.
  Future<int> processSyncQueue();

  /// Recupere les interventions du serveur dans la base locale.
  Future<void> refreshFromServer();
}
