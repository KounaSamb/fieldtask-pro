import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/confirm.dart';
import '../../core/utils/toast.dart';
import '../../data/local/local_storage.dart';
import '../../data/repositories/intervention_repository.dart';
import '../../domain/entities/intervention.dart';
import '../blocs/intervention_cubit.dart';
import '../widgets/photo_section.dart';
import 'signature_page.dart';

class InterventionDetailPage extends StatefulWidget {
  final Intervention intervention;
  const InterventionDetailPage({super.key, required this.intervention});

  @override
  State<InterventionDetailPage> createState() => _InterventionDetailPageState();
}

class _InterventionDetailPageState extends State<InterventionDetailPage> {
  String? _signature; // PNG en base64, null si pas encore signe
  int _photoCount = 0; // photos de preuve deja ajoutees

  @override
  void initState() {
    super.initState();
    _loadSignature();
  }

  Future<void> _loadSignature() async {
    final s = await LocalStorage.instance.getSignature(widget.intervention.id);
    if (mounted) setState(() => _signature = s);
  }

  Future<void> _deleteSignature() async {
    final ok = await confirm(context, 'Supprimer la signature ?',
        'Le client devra signer à nouveau avant de terminer l\'intervention.');
    if (!ok) return;
    await InterventionRepository().deleteSignature(widget.intervention.id);
    await InterventionRepository().processSyncQueue();
    await _loadSignature();
    if (mounted) showToast(context, 'Signature supprimée');
  }

  String _heure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.intervention.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showToast(context, 'Options'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _statusCard(widget.intervention.statut),
          const SizedBox(height: 14),
          _infoBlock(
            '📌 Client',
            widget.intervention.client,
            'Contact : +221 33 839 00 00',
          ),
          _infoBlock('📍 Adresse', widget.intervention.adresse, 'Dakar, Sénégal'),
          _infoBlock(
            '🛠️ Équipement',
            widget.intervention.equipement,
            'Réf. SN-2024-8842',
          ),
          _infoBlock('📝 Description', widget.intervention.description, ''),
          _infoBlock('⏰ RDV', _heure(widget.intervention.dateRdv), ''),
          const SizedBox(height: 6),
          PhotoSection(
            interventionId: widget.intervention.id,
            editable: widget.intervention.statut != InterventionStatus.terminee,
            onCountChanged: (n) {
              if (mounted && n != _photoCount) setState(() => _photoCount = n);
            },
          ),
          const SizedBox(height: 12),
          _signatureSection(context),
          const SizedBox(height: 20),
          _actionButton(context),
        ],
      ),
    );
  }

  Widget _statusCard(InterventionStatus s) {
    Color color;
    IconData icon;
    switch (s) {
      case InterventionStatus.enCours:
        color = AppColors.warning;
        icon = Icons.timelapse;
        break;
      case InterventionStatus.terminee:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case InterventionStatus.enAttente:
        color = AppColors.muted;
        icon = Icons.hourglass_empty;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUT ACTUEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(icon, size: 46, color: Colors.white),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sub,
                style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
              ),
            ),
        ],
      ),
    );
  }

  Widget _signatureSection(BuildContext context) {
    final signed = _signature != null;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SignaturePage(interventionId: widget.intervention.id),
          ),
        );
        _loadSignature();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: signed ? AppColors.success : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(signed ? Icons.verified : Icons.draw_outlined,
                color: signed ? AppColors.success : AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                signed ? 'Signature enregistrée' : 'Signature client',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (signed)
              Container(
                margin: const EdgeInsets.only(right: 10),
                decoration:
                    BoxDecoration(border: Border.all(color: AppColors.border)),
                child: Image.memory(
                  base64Decode(_signature!),
                  height: 44,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 44),
                ),
              ),
            if (signed &&
                widget.intervention.statut != InterventionStatus.terminee)
              IconButton(
                tooltip: 'Supprimer la signature',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: _deleteSignature,
              ),
            Text(
              signed ? 'REFAIRE →' : 'SIGNER →',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    if (widget.intervention.statut == InterventionStatus.terminee) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Intervention terminée',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final next = widget.intervention.statut == InterventionStatus.enAttente
        ? InterventionStatus.enCours
        : InterventionStatus.terminee;
    final label = widget.intervention.statut == InterventionStatus.enAttente
        ? '▶️  DÉMARRER L\'INTERVENTION'
        : '✅  TERMINER L\'INTERVENTION';
    final color = widget.intervention.statut == InterventionStatus.enAttente
        ? AppColors.primary
        : AppColors.success;

    // Terminer exige une photo de preuve ET la signature du client
    final blocked = next == InterventionStatus.terminee &&
        (_photoCount == 0 || _signature == null);

    final button = SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: blocked ? AppColors.muted : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          if (blocked) {
            final missing = [
              if (_photoCount == 0) 'une photo de l\'intervention',
              if (_signature == null) 'la signature du client',
            ];
            showToast(context, 'Pour terminer, ajoutez ${missing.join(' et ')}');
            return;
          }
          await context.read<InterventionCubit>().changeStatus(
                widget.intervention.id,
                next,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut → ${next.label}'),
                backgroundColor: color,
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 14,
          ),
        ),
      ),
    );

       return button;
  }
}