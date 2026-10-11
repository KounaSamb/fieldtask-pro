import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/repositories/intervention_repository.dart';

abstract class SyncState {}

class SyncOnline extends SyncState {}

class SyncOffline extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncCompleted extends SyncState {
  final int processed;
  SyncCompleted(this.processed);
}

class SyncCubit extends Cubit<SyncState> {
  final ConnectivityService connectivity;
  final void Function()? onSynced;
  final repo = InterventionRepository();
  StreamSubscription? _sub;
  Timer? _timer;
  bool _busy = false;

  SyncCubit({required this.connectivity, this.onSynced})
      : super(connectivity.isOnline ? SyncOnline() : SyncOffline());

  void start() {
    // Retour du reseau detecte par connectivity_plus -> synchro immediate
    _sub = connectivity.onlineStream.listen((online) {
      emit(online ? SyncOnline() : SyncOffline());
      if (online) _run();
    });
    // Filet de securite : reessaie toutes les 8 s s'il reste des elements
    // (ex. serveur redemarre alors que le Wi-Fi n'a jamais coupe)
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (repo.pendingCount() > 0) _run();
    });
    _run();
  }

  Future<void> _run() async {
    if (_busy || repo.pendingCount() == 0) return;
    _busy = true;
    emit(SyncInProgress());
    final n = await repo.processSyncQueue();
    _busy = false;
    if (n > 0) {
      emit(SyncCompleted(n));
      onSynced?.call();
    } else {
      emit(connectivity.isOnline ? SyncOnline() : SyncOffline());
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
