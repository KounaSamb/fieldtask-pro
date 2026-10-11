import 'package:equatable/equatable.dart';
import 'intervention_status.dart';

export 'intervention_status.dart';

class Intervention extends Equatable {
  final String id, client, adresse, description, equipement, priorite, notes;
  final double latitude, longitude;
  final InterventionStatus statut;
  final DateTime dateRdv;
  final bool synced;

  const Intervention({
    required this.id,
    required this.client,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.equipement,
    required this.statut,
    required this.priorite,
    required this.dateRdv,
    required this.notes,
    required this.synced,
  });

  factory Intervention.fromJson(Map<String, dynamic> j) => Intervention(
        id: j['id'],
        client: j['client'] ?? '',
        adresse: j['adresse'] ?? '',
        latitude: (j['latitude'] ?? 0).toDouble(),
        longitude: (j['longitude'] ?? 0).toDouble(),
        description: j['description'] ?? '',
        equipement: j['equipement'] ?? '',
        statut: InterventionStatusX.fromString(j['statut'] ?? 'en_attente'),
        priorite: j['priorite'] ?? 'M',
        dateRdv: DateTime.tryParse(j['dateRdv'] ?? '') ?? DateTime.now(),
        notes: j['notes'] ?? '',
        synced: j['synced'] == true || j['synced'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client': client,
        'adresse': adresse,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'equipement': equipement,
        'statut': statut.value,
        'priorite': priorite,
        'dateRdv': dateRdv.toIso8601String(),
        'notes': notes,
        'synced': synced,
      };

  Intervention copyWith({
    InterventionStatus? statut,
    String? notes,
    bool? synced,
  }) =>
      Intervention(
        id: id,
        client: client,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
        description: description,
        equipement: equipement,
        statut: statut ?? this.statut,
        priorite: priorite,
        dateRdv: dateRdv,
        notes: notes ?? this.notes,
        synced: synced ?? this.synced,
      );

  @override
  List<Object?> get props => [id, statut, synced, notes];
}
