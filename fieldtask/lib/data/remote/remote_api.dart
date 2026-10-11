import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Client REST pour JSON-Server.
class RemoteApi {
  static const _timeout = Duration(seconds: 5);
  final _json = {'Content-Type': 'application/json'};

  Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('${ApiConfig.baseUrl}/$path').replace(queryParameters: q);

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(_timeout);
      if (r.statusCode >= 400) throw ApiException('Erreur serveur ${r.statusCode}');
      return r;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Serveur injoignable (${ApiConfig.baseUrl}) : $e');
    }
  }

  /// Login : cherche l'utilisateur dans /users, renvoie un token simule.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _send(() => http.get(_uri('users', {'email': email, 'password': password})));
    final list = jsonDecode(r.body) as List;
    if (list.isEmpty) throw ApiException('Identifiants invalides');
    final u = Map<String, dynamic>.from(list.first)..remove('password');
    return {...u, 'id': u['id'].toString(), 'token': 'jwt-simule-${u['id']}'};
  }

  Future<List<Map<String, dynamic>>> fetchInterventions() async {
    final r = await _send(() => http.get(_uri('interventions')));
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> patchIntervention(String id, Map<String, dynamic> body) async {
    await _send(() => http.patch(_uri('interventions/$id'), headers: _json, body: jsonEncode(body)));
  }

  Future<void> patchUser(String id, Map<String, dynamic> body) async {
    await _send(() => http.patch(_uri('users/$id'), headers: _json, body: jsonEncode(body)));
  }

  /// Supprime sur le serveur les enregistrements correspondant au filtre
  /// (rien a faire s'il n'y en a pas : operation idempotente).
  Future<void> deleteWhere(String collection, Map<String, String> filter) async {
    final r = await _send(() => http.get(_uri(collection, filter)));
    for (final e in jsonDecode(r.body) as List) {
      await _send(() => http.delete(_uri('$collection/${e['id']}')));
    }
  }

  /// Modifie sur le serveur les enregistrements correspondant au filtre.
  Future<void> patchWhere(String collection, Map<String, String> filter,
      Map<String, dynamic> body) async {
    final r = await _send(() => http.get(_uri(collection, filter)));
    for (final e in jsonDecode(r.body) as List) {
      await _send(() => http.patch(_uri('$collection/${e['id']}'),
          headers: _json, body: jsonEncode(body)));
    }
  }

  Future<void> post(String collection, Map<String, dynamic> body) async {
    await _send(() => http.post(_uri(collection), headers: _json, body: jsonEncode(body)));
  }
}