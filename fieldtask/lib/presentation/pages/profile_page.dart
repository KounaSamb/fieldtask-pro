import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/toast.dart';
import '../../data/repositories/intervention_repository.dart';
import '../../domain/entities/user.dart';
import '../blocs/auth_cubit.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  void _edit(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  Future<void> _sync(BuildContext context) async {
    final n = await InterventionRepository().processSyncQueue();
    if (context.mounted) {
      showToast(context, n > 0 ? '$n élément(s) synchronisé(s) ✅' : 'Rien à synchroniser');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      final user = state is AuthAuthenticated ? state.user : null;
      final pending = InterventionRepository().pendingCount();
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, Color(0xFFFF6B1F)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user == null ? '?' : _initials(user.nom),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.nom ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user == null ? '' : '${user.role} · ${user.matricule}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),
                      if (user != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          onPressed: () => _edit(context, user),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Modifier le profil'),
                        ),
                    ],
                  ),
                ),
                // Bouton retour
                Positioned(
                  top: 34,
                  left: 8,
                  child: IconButton(
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _item(Icons.email_outlined, 'Email', user?.email ?? '',
                      AppColors.primary,
                      onTap: user == null ? null : () => _edit(context, user)),
                  _item(Icons.phone_outlined, 'Téléphone',
                      user?.telephone ?? '', AppColors.accent,
                      onTap: user == null ? null : () => _edit(context, user)),
                  _item(
                    Icons.sync,
                    'Synchroniser',
                    pending == 0
                        ? 'Tout est synchronisé'
                        : '$pending modification(s) en attente',
                    AppColors.success,
                    onTap: () => _sync(context),
                  ),
                  _item(
                    Icons.settings_outlined,
                    'Paramètres',
                    'Langue, thème, notifications',
                    AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      await context.read<AuthCubit>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.danger),
                          SizedBox(width: 14),
                          Text(
                            'Déconnexion',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _item(IconData icon, String title, String subtitle, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(onTap == null ? Icons.chevron_right : Icons.edit_outlined,
                color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Formulaire de modification du profil (nom, email, telephone).
class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _nom = TextEditingController(text: widget.user.nom);
  late final _email = TextEditingController(text: widget.user.email);
  late final _tel = TextEditingController(text: widget.user.telephone);
  String? _errNom, _errEmail, _errTel;
  bool _saving = false;

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nom.text.trim(), email = _email.text.trim(), tel = _tel.text.trim();
    setState(() {
      _errNom = nom.isEmpty ? 'Le nom est obligatoire' : null;
      _errEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
          ? null
          : 'Email invalide';
      _errTel = tel.isEmpty || RegExp(r'^[0-9+() .-]{6,20}$').hasMatch(tel)
          ? null
          : 'Numéro invalide';
    });
    if (_errNom != null || _errEmail != null || _errTel != null) return;

    setState(() => _saving = true);
    final cubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);
    await cubit.updateProfile(nom: nom, email: email, telephone: tel);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil mis à jour ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier le profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _nom,
              decoration: InputDecoration(
                  labelText: 'Nom complet', errorText: _errNom),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  InputDecoration(labelText: 'Email', errorText: _errEmail),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: 'Téléphone', errorText: _errTel),
            ),
            const SizedBox(height: 6),
            Text(
              'Rôle et matricule : ${widget.user.role} · ${widget.user.matricule} (non modifiables)',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSoft),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '...' : 'Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
