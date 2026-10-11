import '../entities/user.dart';
import '../repositories/auth_repository_interface.dart';

class LoginUseCase {
  final IAuthRepository _repo;
  LoginUseCase(this._repo);
  Future<User> call(String email, String password) =>
      _repo.login(email, password);
}

class RestoreSessionUseCase {
  final IAuthRepository _repo;
  RestoreSessionUseCase(this._repo);
  Future<User?> call() => _repo.restoreSession();
}

class LogoutUseCase {
  final IAuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}
