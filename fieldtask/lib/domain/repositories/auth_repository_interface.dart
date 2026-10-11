import '../entities/user.dart';

/// Contrat de l'authentification (couche Domain).
abstract class IAuthRepository {
  Future<User> login(String email, String password);

  /// Retourne l'utilisateur de la session enregistree, ou null.
  Future<User?> restoreSession();
  Future<void> logout();
}
