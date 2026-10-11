import '../../core/services/token_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import '../local/local_storage.dart';
import '../remote/remote_api.dart';

/// Implementation : API REST pour la connexion, SQLite pour l'utilisateur,
/// stockage securise pour le jeton.
class AuthRepository implements IAuthRepository {
  final RemoteApi _api;
  AuthRepository({RemoteApi? api}) : _api = api ?? RemoteApi();

  @override
  Future<User> login(String email, String password) async {
    final json = await _api.login(email.trim(), password);
    final user = User.fromJson(json);
    await LocalStorage.instance.saveUser(user.toJson());
    final token = json['token'];
    if (token is String) await TokenStore.save(token);
    return user;
  }

  @override
  Future<User?> restoreSession() async {
    final u = LocalStorage.instance.getUser();
    if (u == null) return null;
    final token = await TokenStore.read();
    // Sans jeton, la session n'est pas valide (sauf si le stockage securise
    // n'est pas disponible sur cette plateforme).
    if (token == null && !TokenStore.unavailable) return null;
    return User.fromJson(u);
  }

  @override
  Future<void> logout() async {
    await LocalStorage.instance.logout();
    await TokenStore.clear();
  }
}