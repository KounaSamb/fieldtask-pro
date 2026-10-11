import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Stockage local adosse a SQLite.
/// Les lectures se font depuis un cache memoire (charge au demarrage),
/// chaque ecriture est immediatement persistee dans SQLite.
class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  final _helper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _interventions = [];
  List<Map<String, dynamic>> _queue = [];
  Map<String, dynamic>? _user;

  Future<void> init() async {
    final db = await _helper.database;
    _interventions = (await db.query('interventions'))
        .map((r) => {...r, 'synced': r['synced'] == 1})
        .toList();
    _queue = (await db.query('sync_queue', orderBy: 'id'))
        .map((r) => {...r, 'payload': jsonDecode(r['payload'] as String)})
        .toList();
    final u = await db.query('session', where: 'key = ?', whereArgs: ['user']);
    _user = u.isEmpty ? null : jsonDecode(u.first['value'] as String);
  }

  Map<String, dynamic> _row(Map<String, dynamic> m) =>
      {...m, 'synced': m['synced'] == true ? 1 : 0};

  // ---- Interventions ----
  List<Map<String, dynamic>> getInterventions() =>
      _interventions.map((e) => Map<String, dynamic>.from(e)).toList();

  Future<void> saveInterventions(List<Map<String, dynamic>> list) async {
    _interventions = list.map((e) => Map<String, dynamic>.from(e)).toList();
    final db = await _helper.database;
    final batch = db.batch();
    for (final i in list) {
      batch.insert('interventions', _row(i),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateIntervention(Map<String, dynamic> updated) async {
    final idx = _interventions.indexWhere((e) => e['id'] == updated['id']);
    if (idx >= 0) _interventions[idx] = Map<String, dynamic>.from(updated);
    final db = await _helper.database;
    await db.update('interventions', _row(updated),
        where: 'id = ?', whereArgs: [updated['id']]);
  }

  // ---- Sync queue ----
  List<Map<String, dynamic>> getSyncQueue() =>
      _queue.map((e) => Map<String, dynamic>.from(e)).toList();

  Future<void> enqueue(Map<String, dynamic> item) async {
    final createdAt = DateTime.now().toIso8601String();
    final db = await _helper.database;
    final id = await db.insert('sync_queue', {
      'entityType': item['entityType'],
      'entityId': item['entityId'],
      'action': item['action'],
      'payload': jsonEncode(item['payload']),
      'createdAt': createdAt,
    });
    _queue.add({...item, 'id': id, 'createdAt': createdAt});
  }

  Future<void> removeFromQueue(int id) async {
    _queue.removeWhere((e) => e['id'] == id);
    await (await _helper.database).delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearQueue() async {
    _queue = [];
    await (await _helper.database).delete('sync_queue');
  }

  // ---- Photos / signatures ----
  Future<void> insertPhoto(String interventionId, String path,
          {String explications = ''}) async =>
      (await _helper.database).insert('photos', {
        'interventionId': interventionId,
        'cheminLocal': path,
        'explications': explications,
        'createdAt': DateTime.now().toIso8601String(),
      });

  /// Photos avec leur explication : [{path, explications}, ...]
  Future<List<Map<String, dynamic>>> getPhotoDetails(
      String interventionId) async {
    final rows = await (await _helper.database).query('photos',
        where: 'interventionId = ?', whereArgs: [interventionId], orderBy: 'id');
    return rows
        .map((r) => {
              'path': r['cheminLocal'] as String,
              'explications': (r['explications'] as String?) ?? '',
            })
        .toList();
  }

  Future<void> updatePhotoExplications(
          String interventionId, String path, String text) async =>
      (await _helper.database).update('photos', {'explications': text},
          where: 'interventionId = ? AND cheminLocal = ?',
          whereArgs: [interventionId, path]);

  Future<List<String>> getPhotos(String interventionId) async {
    final rows = await (await _helper.database).query('photos',
        where: 'interventionId = ?', whereArgs: [interventionId], orderBy: 'id');
    return rows.map((r) => r['cheminLocal'] as String).toList();
  }

  Future<void> deletePhoto(String interventionId, String path) async =>
      (await _helper.database).delete('photos',
          where: 'interventionId = ? AND cheminLocal = ?',
          whereArgs: [interventionId, path]);

  Future<void> deleteSignatures(String interventionId) async =>
      (await _helper.database).delete('signatures',
          where: 'interventionId = ?', whereArgs: [interventionId]);

  Future<void> insertSignature(String interventionId, String pngBase64) async =>
      (await _helper.database).insert('signatures', {
        'interventionId': interventionId,
        'donnees': pngBase64,
        'createdAt': DateTime.now().toIso8601String(),
      });

  /// Derniere signature (PNG en base64) d'une intervention, ou null.
  Future<String?> getSignature(String interventionId) async {
    final rows = await (await _helper.database).query('signatures',
        where: 'interventionId = ? AND donnees IS NOT NULL',
        whereArgs: [interventionId],
        orderBy: 'id DESC',
        limit: 1);
    return rows.isEmpty ? null : rows.first['donnees'] as String?;
  }

  // ---- Session ----
  Future<void> saveUser(Map<String, dynamic> user) async {
    _user = user;
    await (await _helper.database).insert(
        'session', {'key': 'user', 'value': jsonEncode(user)},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, dynamic>? getUser() => _user;

  Future<void> logout() async {
    _user = null;
    await (await _helper.database)
        .delete('session', where: 'key = ?', whereArgs: ['user']);
  }
}