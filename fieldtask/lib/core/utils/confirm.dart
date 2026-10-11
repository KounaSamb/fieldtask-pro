import 'package:flutter/material.dart';

/// Boite de dialogue Oui / Non. Renvoie true si l'utilisateur confirme.
Future<bool> confirm(BuildContext context, String title, String message,
    {String yes = 'Supprimer'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return r ?? false;
}
