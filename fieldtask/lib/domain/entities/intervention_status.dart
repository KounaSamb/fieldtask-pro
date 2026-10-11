
enum InterventionStatus { enAttente, enCours, terminee }

extension InterventionStatusX on InterventionStatus {
  String get value {
    switch (this) {
      case InterventionStatus.enAttente:
        return 'en_attente';
      case InterventionStatus.enCours:
        return 'en_cours';
      case InterventionStatus.terminee:
        return 'terminee';
    }
  }

  String get label {
    switch (this) {
      case InterventionStatus.enAttente:
        return 'En attente';
      case InterventionStatus.enCours:
        return 'En cours';
      case InterventionStatus.terminee:
        return 'Terminée';
    }
  }

  static InterventionStatus fromString(String s) {
    switch (s) {
      case 'en_cours':
        return InterventionStatus.enCours;
      case 'terminee':
        return InterventionStatus.terminee;
      default:
        return InterventionStatus.enAttente;
    }
  }
}
