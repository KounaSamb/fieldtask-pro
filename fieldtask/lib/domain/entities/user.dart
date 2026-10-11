import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id, email, nom, role, matricule, telephone, token;
  const User({
    required this.id,
    required this.email,
    required this.nom,
    required this.role,
    required this.matricule,
    required this.telephone,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        nom: j['nom'] ?? '',
        role: j['role'] ?? '',
        matricule: j['matricule'] ?? '',
        telephone: j['telephone'] ?? '',
        token: j['token'] ?? '',
      );

  User copyWith({String? nom, String? email, String? telephone}) => User(
        id: id,
        email: email ?? this.email,
        nom: nom ?? this.nom,
        role: role,
        matricule: matricule,
        telephone: telephone ?? this.telephone,
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nom': nom,
        'role': role,
        'matricule': matricule,
        'telephone': telephone,
        'token': token,
      };

  @override
  List<Object?> get props => [
        id,
        email,
        nom,
        role,
        matricule,
        telephone,
        token,
      ];
}
