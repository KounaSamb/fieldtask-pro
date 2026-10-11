import '../../domain/entities/intervention.dart';
import '../local/local_storage.dart';
import '../remote/remote_api.dart';

class InterventionRepository {
  final LocalStorage _storage = LocalStorage.instance;
  final RemoteApi _api = RemoteApi();

  List<Intervention> getAll() {
    return _storage.getInterventions().map(Intervention.fromJson).toList()
      ..sort((a, b) => a.dateRdv.compareTo(b.dateRdv));
  }

  Future<void> updateStatus(String id, InterventionStatus statut) async {
    final list = _storage.getInterventions();
    final idx = list.indexWhere((e) => e['id'] == id);
    if (idx < 0) return;
    list[idx]['statut'] = statut.value;
    list[idx]['synced'] = false;
    await _storage.saveInterventions(list);
    await _storage.enqueue({
      'entityType': 'intervention',
      'entityId': id,
      'action': 'update',
      'payload': {'id': id, 'statut': statut.value},
    });
  }

  Future<void> addPhoto(String id, String path,
      {String explications = ''}) async {
    await _storage.insertPhoto(id, path, explications: explications);
    await _storage.enqueue({
      'entityType': 'photo',
      'entityId': id,
      'action': 'create',
      'payload': {
        'interventionId': id,
        'cheminLocal': path,
        'explications': explications,
      },
    });
  }

  /// Modifie l'explication d'une photo deja ajoutee.
  Future<void> updatePhotoExplications(
      String id, String path, String text) async {
    await _storage.updatePhotoExplications(id, path, text);
    await _storage.enqueue({
      'entityType': 'photo',
      'entityId': id,
      'action': 'update',
      'payload': {
        'interventionId': id,
        'cheminLocal': path,
        'explications': text,
      },
    });
  }

  /// [pngBase64] : image PNG de la signature encodee en base64.
  Future<void> saveSignature(String id, String pngBase64) async {
    await _storage.insertSignature(id, pngBase64);
    await _storage.enqueue({
      'entityType': 'signature',
      'entityId': id,
      'action': 'create',
      'payload': {'interventionId': id, 'donnees': pngBase64},
    });
  }

  /// Supprime une photo (locale + file de synchro pour le serveur).
  Future<void> deletePhoto(String id, String path) async {
    await _storage.deletePhoto(id, path);
    await _storage.enqueue({
      'entityType': 'photo',
      'entityId': id,
      'action': 'delete',
      'payload': {'interventionId': id, 'cheminLocal': path},
    });
  }

  /// Supprime la signature d'une intervention.
  Future<void> deleteSignature(String id) async {
    await _storage.deleteSignatures(id);
    await _storage.enqueue({
      'entityType': 'signature',
      'entityId': id,
      'action': 'delete',
      'payload': {'interventionId': id},
    });
  }

  int pendingCount() => _storage.getSyncQueue().length;

  /// Telecharge les interventions du serveur (sans ecraser celles en attente d'envoi).
  Future<bool> refreshFromServer() async {
    try {
      final remote = await _api.fetchInterventions();
      final pending = _storage.getSyncQueue().map((e) => e['entityId']).toSet();
      final byId = {for (final m in _storage.getInterventions()) m['id']: m};
      for (final r in remote) {
        if (pending.contains(r['id'])) continue;
        byId[r['id']] = {...r, 'synced': true};
      }
      await _storage.saveInterventions(byId.values.toList());
      return true;
    } catch (_) {
      return false; // hors ligne : on garde les donnees locales
    }
  }

  /// Envoie la file d'attente au serveur, dans l'ordre. S'arrete a la
  /// premiere erreur (reseau coupe) et reessaiera plus tard.
  Future<int> processSyncQueue() async {
    var done = 0;
    for (final item in _storage.getSyncQueue()) {
      try {
        final p = Map<String, dynamic>.from(item['payload']);
        switch (item['entityType']) {
          case 'intervention':
            await _api.patchIntervention(item['entityId'], {'statut': p['statut']});
            break;
          case 'photo':
            if (item['action'] == 'delete') {
              await _api.deleteWhere('photos', {
                'interventionId': '${p['interventionId']}',
                'cheminLocal': '${p['cheminLocal']}',
              });
            } else if (item['action'] == 'update') {
              await _api.patchWhere(
                'photos',
                {
                  'interventionId': '${p['interventionId']}',
                  'cheminLocal': '${p['cheminLocal']}',
                },
                {'explications': '${p['explications']}'},
              );
            } else {
              await _api.post('photos', p);
            }
            break;
          case 'signature':
            if (item['action'] == 'delete') {
              await _api.deleteWhere(
                  'signatures', {'interventionId': '${p['interventionId']}'});
            } else {
              await _api.post('signatures', p);
            }
            break;
          case 'user':
            await _api.patchUser(item['entityId'], p);
            break;
        }
        await _storage.removeFromQueue(item['id'] as int);
        done++;
      } catch (_) {
        break;
      }
    }
    if (done > 0) {
      final pending = _storage.getSyncQueue().map((e) => e['entityId']).toSet();
      final list = _storage.getInterventions();
      for (final it in list) {
        it['synced'] = !pending.contains(it['id']);
      }
      await _storage.saveInterventions(list);
    }
    return done;
  }
}