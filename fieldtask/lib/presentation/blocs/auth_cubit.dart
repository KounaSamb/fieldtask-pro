import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local/local_storage.dart';
import '../../data/remote/remote_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/intervention_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import '../../domain/usecases/auth_usecases.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _login;
  final RestoreSessionUseCase _restore;
  final LogoutUseCase _logout;

  AuthCubit({IAuthRepository? repository})
      : this._(repository ?? AuthRepository());

  AuthCubit._(IAuthRepository repo)
      : _login = LoginUseCase(repo),
        _restore = RestoreSessionUseCase(repo),
        _logout = LogoutUseCase(repo),
        super(AuthInitial());

  Future<void> checkSession() async {
    final user = await _restore();
    emit(user != null ? AuthAuthenticated(user) : AuthUnauthenticated());
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _login(email.trim(), password);
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Connexion impossible : $e'));
    }
  }

  /// Modifie le profil : SQLite d'abord, puis file de synchro vers le serveur.
  Future<void> updateProfile({
    required String nom,
    required String email,
    required String telephone,
  }) async {
    final s = state;
    if (s is! AuthAuthenticated) return;
    final user = s.user.copyWith(
        nom: nom.trim(), email: email.trim(), telephone: telephone.trim());
    await LocalStorage.instance.saveUser(user.toJson());
    emit(AuthAuthenticated(user));
    await LocalStorage.instance.enqueue({
      'entityType': 'user',
      'entityId': user.id,
      'action': 'update',
      'payload': {
        'nom': user.nom,
        'email': user.email,
        'telephone': user.telephone
      },
    });
    await InterventionRepository().processSyncQueue(); // sinon reessaye plus tard
  }

  Future<void> logout() async {
    await _logout();
    emit(AuthUnauthenticated());
  }
}