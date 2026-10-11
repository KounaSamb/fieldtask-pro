import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/confirm.dart';
import '../../core/utils/toast.dart';
import '../../data/local/local_storage.dart';
import '../../data/repositories/intervention_repository.dart';

/// Photos d'une intervention, chacune avec ses "Explications".
/// Appareil photo ou galerie, stockage dans SQLite.
class PhotoSection extends StatefulWidget {
  final String interventionId;
  final ValueChanged<int>? onCountChanged;

  /// false une fois l'intervention validee : plus de modification possible.
  final bool editable;
  const PhotoSection({
    super.key,
    required this.interventionId,
    this.onCountChanged,
    this.editable = true,
  });

  @override
  State<PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<PhotoSection> {
  final _picker = ImagePicker();
  final _repo = InterventionRepository();
  List<Map<String, dynamic>> _photos = []; // {path, explications}

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await LocalStorage.instance.getPhotoDetails(widget.interventionId);
    if (!mounted) return;
    setState(() => _photos = l);
    widget.onCountChanged?.call(l.length);
  }

  /// Boite de saisie des explications. Renvoie null si l'utilisateur annule.
  /// Le controleur de texte est gere par la boite elle-meme (voir
  /// _ExplicationsDialog) : le liberer ici, juste apres la fermeture,
  /// provoquait l'ecran rouge "_dependents.isEmpty".
  Future<String?> _askExplication(
      {String initial = '', String title = 'Explications de la photo'}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ExplicationsDialog(initial: initial, title: title),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1600);
      if (f == null || !mounted) return; // annule

      // On demande l'explication avant d'enregistrer ; Annuler = photo ignoree
      final explications = await _askExplication();
      if (explications == null) return;

      var path = f.path;
      if (!kIsWeb) {
        // Copie dans le dossier de l'app pour que la photo reste disponible
        try {
          final dir = await getApplicationDocumentsDirectory();
          final photosDir = Directory(p.join(dir.path, 'photos'));
          await photosDir.create(recursive: true);
          path = p.join(photosDir.path,
              '${DateTime.now().millisecondsSinceEpoch}${p.extension(f.path)}');
          await File(f.path).copy(path);
        } catch (_) {
          path = f.path;
        }
      }
      await _repo.addPhoto(widget.interventionId, path,
          explications: explications);
      await _repo.processSyncQueue();
      await _load();
      if (mounted) showToast(context, 'Photo ajoutée ✅');
    } catch (_) {
      if (!mounted) return;
      showToast(
        context,
        source == ImageSource.camera
            ? 'Caméra indisponible ici. Choisissez une photo dans la galerie.'
            : 'Impossible d\'ajouter la photo',
      );
    }
  }

  Future<void> _edit(Map<String, dynamic> ph) async {
    final t = await _askExplication(
        initial: ph['explications'] as String? ?? '',
        title: 'Modifier les explications');
    if (t == null) return;
    await _repo.updatePhotoExplications(
        widget.interventionId, ph['path'] as String, t);
    await _repo.processSyncQueue();
    await _load();
    if (mounted) showToast(context, 'Explications enregistrées');
  }

  Future<void> _delete(String path) async {
    final ok = await confirm(context, 'Supprimer la photo ?',
        'Cette photo et ses explications seront retirées de l\'intervention. Vous pourrez en reprendre une autre.');
    if (!ok) return;
    await _repo.deletePhoto(widget.interventionId, path);
    if (!kIsWeb) {
      try {
        await File(path).delete(); // libere aussi l'espace sur l'appareil
      } catch (_) {}
    }
    await _repo.processSyncQueue();
    await _load();
    if (mounted) showToast(context, 'Photo supprimée');
  }

  void _choose() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String path, {double? size}) {
    final broken = Container(
      width: size,
      height: size,
      color: AppColors.bg,
      child: const Icon(Icons.broken_image, color: AppColors.muted),
    );
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => broken);
    }
    return Image.file(File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => broken);
  }

  void _preview(Map<String, dynamic> ph) {
    final text = ph['explications'] as String? ?? '';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(child: _image(ph['path'] as String)),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(text, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> ph) {
    final path = ph['path'] as String;
    final text = ph['explications'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _preview(ph),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _image(path, size: 76),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: widget.editable ? () => _edit(ph) : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPLICATIONS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text.isEmpty ? 'Aucune explication' : text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontStyle: text.isEmpty ? FontStyle.italic : null,
                      color: text.isEmpty ? AppColors.muted : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.editable)
            Column(
              children: [
                IconButton(
                  tooltip: 'Modifier les explications',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.primary),
                  onPressed: () => _edit(ph),
                ),
                IconButton(
                  tooltip: 'Supprimer la photo',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.danger),
                  onPressed: () => _delete(path),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '📸 Photos de l\'intervention (${_photos.length})',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final ph in _photos) _card(ph),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_photos.isEmpty
                  ? 'Ajouter une photo'
                  : 'Ajouter une autre photo'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boite de saisie des explications : elle cree et libere elle-meme son
/// controleur de texte, donc le champ n'est jamais utilise apres dispose().
class _ExplicationsDialog extends StatefulWidget {
  final String initial;
  final String title;
  const _ExplicationsDialog({required this.initial, required this.title});

  @override
  State<_ExplicationsDialog> createState() => _ExplicationsDialogState();
}

class _ExplicationsDialogState extends State<_ExplicationsDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 4,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: 'Ex : état du câble avant la réparation',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}