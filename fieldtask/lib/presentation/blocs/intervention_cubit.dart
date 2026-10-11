import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/intervention_repository.dart';
import '../../data/repositories/interventionRepositoryImpl.dart';
import '../../domain/entities/intervention.dart';
import '../../domain/entities/intervention_status.dart';
import '../../domain/repositories/intervention_repository_interface.dart';
import '../../domain/usecases/intervention_usecases.dart';

abstract class InterventionState {}

class InterventionInitial extends InterventionState {}

class InterventionLoading extends InterventionState {}

class InterventionLoaded extends InterventionState {
  final List<Intervention> all;
  InterventionLoaded(this.all);
}

class InterventionError extends InterventionState {
  final String message;
  InterventionError(this.message);
}

class InterventionCubit extends Cubit<InterventionState> {
  final InterventionRepository repo;
  late final IInterventionRepository _domainRepo =
      InterventionRepositoryImpl(repo);
  late final GetInterventions _getAll = GetInterventions(_domainRepo);
  late final ChangeInterventionStatus _changeStatus =
      ChangeInterventionStatus(_domainRepo);
  late final PushPendingChanges _push = PushPendingChanges(_domainRepo);
  late final PullFromServer _pull = PullFromServer(_domainRepo);

  InterventionCubit({InterventionRepository? repository})
      : repo = repository ?? InterventionRepository(),
        super(InterventionInitial());

  /// Affiche d'abord le local, puis tente de rafraichir depuis le serveur.
  Future<void> load({bool pull = true}) async {
    emit(InterventionLoading());
    try {
      _emit();
    } catch (e) {
      emit(InterventionError(e.toString()));
      return;
    }
    if (pull) {
      await _push();
      await _pull();
      _emit();
    }
  }

  void _emit() {
    final list = _getAll();
    emit(InterventionLoaded(list));
    NotificationService.instance.syncReminders(list); // rappels 30 min avant
  }

  Future<void> changeStatus(String id, InterventionStatus statut) async {
    await _changeStatus(id, statut);
    _emit();
    if (await _push() > 0) {
      _emit();
    }
  }
}