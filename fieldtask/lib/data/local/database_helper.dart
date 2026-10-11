import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Ouvre la base SQLite, cree les tables et insere les donnees de depart.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'fieldtask.db');
    return openDatabase(path,
        version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // v2 : la signature (PNG en base64) est stockee dans la table
      await db.execute('ALTER TABLE signatures ADD COLUMN donnees TEXT');
    }
    if (oldV < 3) {
      // v3 : explication saisie pour chaque photo
      await db.execute('ALTER TABLE photos ADD COLUMN explications TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE interventions(
      id TEXT PRIMARY KEY, client TEXT, adresse TEXT, latitude REAL,
      longitude REAL, description TEXT, equipement TEXT, statut TEXT,
      priorite TEXT, dateRdv TEXT, notes TEXT, synced INTEGER)''');
    await db.execute('''CREATE TABLE sync_queue(
      id INTEGER PRIMARY KEY AUTOINCREMENT, entityType TEXT, entityId TEXT,
      action TEXT, payload TEXT, createdAt TEXT)''');
    await db.execute('''CREATE TABLE photos(
      id INTEGER PRIMARY KEY AUTOINCREMENT, interventionId TEXT,
      cheminLocal TEXT, explications TEXT, createdAt TEXT)''');
    await db.execute('''CREATE TABLE signatures(
      id INTEGER PRIMARY KEY AUTOINCREMENT, interventionId TEXT,
      cheminLocal TEXT, donnees TEXT, createdAt TEXT)''');
    await db.execute('CREATE TABLE session(key TEXT PRIMARY KEY, value TEXT)');

    const seed = [
      {
        'id': 'INT-001',
        'client': 'Sénélec : M. Diop',
        'adresse': '12 Rue Carnot, Plateau, Dakar',
        'latitude': 14.6708,
        'longitude': -17.4381,
        'description': 'Surchauffe du module principal, alarme active.',
        'equipement': 'Transformateur TR-45',
        'statut': 'en_cours',
        'priorite': 'H',
        'dateRdv': '2026-10-11T14:30:00',
        'notes': '',
        'synced': true,
      },
      {
        'id': 'INT-002',
        'client': 'Orange SN : Mme Fall',
        'adresse': 'Avenue L.S. Senghor, Thiès',
        'latitude': 14.7910,
        'longitude': -16.9256,
        'description': 'Antenne 4G en panne, signal instable.',
        'equipement': 'Antenne 4G Huawei',
        'statut': 'en_attente',
        'priorite': 'M',
        'dateRdv': '2026-10-11T16:00:00',
        'notes': '',
        'synced': true,
      },
      {
        'id': 'INT-003',
        'client': 'Sonatel : M. Sow',
        'adresse': 'Route de Rufisque, Rufisque',
        'latitude': 14.7158,
        'longitude': -17.2736,
        'description': 'Routeur Cisco à reconfigurer.',
        'equipement': 'Routeur Cisco 2900',
        'statut': 'en cours',
        'priorite': 'B',
        'dateRdv': '2026-10-11T10:00:00',
        'notes': 'Configuration appliquée.',
        'synced': true,
      },
    ];
    for (final i in seed) {
      await db.insert('interventions', {...i, 'synced': 1});
    }
  }
}