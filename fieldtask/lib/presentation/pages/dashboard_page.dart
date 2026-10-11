import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/toast.dart';
import '../../data/local/local_storage.dart';
import '../../domain/entities/intervention.dart';
import '../blocs/intervention_cubit.dart';
import '../widgets/network_banner.dart';
import '../widgets/reminders_dialog.dart';
import 'intervention_detail_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filter = 'all';
  String _search = '';

  // Ordre de tri : priorité haute (H), puis moyenne (M), puis basse (B)
  static const _ordrePriorite = {'H': 0, 'M': 1, 'B': 2};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<InterventionCubit, InterventionState>(
          builder: (context, state) {
            if (state is InterventionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is InterventionError) {
              return Center(child: Text(state.message));
            }

            final list =
                state is InterventionLoaded ? state.all : <Intervention>[];

            final filtered = list.where((i) {
              final okF = _filter == 'all' || i.statut.value == _filter;
              final q = _search.toLowerCase();
              final okS = q.isEmpty ||
                  i.id.toLowerCase().contains(q) ||
                  i.client.toLowerCase().contains(q) ||
                  i.adresse.toLowerCase().contains(q);
              return okF && okS;
            }).toList();

            // Tri par priorité, puis par heure de rendez-vous la plus proche
            filtered.sort((a, b) {
              final p = (_ordrePriorite[a.priorite] ?? 3)
                  .compareTo(_ordrePriorite[b.priorite] ?? 3);
              return p != 0 ? p : a.dateRdv.compareTo(b.dateRdv);
            });

            final counts = {
              'all': list.length,
              'en_attente': list
                  .where((e) => e.statut == InterventionStatus.enAttente)
                  .length,
              'en_cours': list
                  .where((e) => e.statut == InterventionStatus.enCours)
                  .length,
              'terminee': list
                  .where((e) => e.statut == InterventionStatus.terminee)
                  .length,
            };

            return Column(
              children: [
                _header(),
                const NetworkBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une intervention...',
                      prefixIcon: Icon(Icons.search, color: AppColors.muted),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _chips(counts),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Triées par priorité',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<InterventionCubit>().load(),
                    child: filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: AppColors.muted,
                              ),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Aucune intervention',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _InterventionCard(
                              item: filtered[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InterventionDetailPage(
                                      intervention: filtered[i],
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  context.read<InterventionCubit>().load();
                                }
                              },
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    // Utilisateur connecte (champ "nom" de db.json, enregistre dans la session)
    final user = LocalStorage.instance.getUser();
    final nom = ((user?['nom'] as String?) ?? '').trim();
    final nomAffiche = nom.isEmpty ? 'Technicien' : nom;
    final initiales = nomAffiche
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $nomAffiche',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Vos interventions du jour',
                  style: TextStyle(fontSize: 12, color: AppColors.textSoft),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                final s = context.read<InterventionCubit>().state;
                showRemindersDialog(
                    context, s is InterventionLoaded ? s.all : const []);
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(Map<String, int> counts) {
    final entries = [
      ('all', 'Toutes'),
      ('en_attente', 'En attente'),
      ('en_cours', 'En cours'),
      ('terminee', 'Terminées'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = entries[i];
          final active = _filter == key;
          return GestureDetector(
            onTap: () => setState(() => _filter = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '$label (${counts[key] ?? 0})',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : AppColors.textSoft,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPage()),
            );
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ---------- INTERVENTION CARD ----------
class _InterventionCard extends StatelessWidget {
  final Intervention item;
  final VoidCallback onTap;
  const _InterventionCard({required this.item, required this.onTap});

  // Couleur selon le statut
  Color get _statusColor {
    switch (item.statut) {
      case InterventionStatus.enCours:
        return AppColors.warning;
      case InterventionStatus.terminee:
        return AppColors.success;
      case InterventionStatus.enAttente:
        return AppColors.muted;
    }
  }

  String _heure() =>
      '${item.dateRdv.hour.toString().padLeft(2, '0')}h${item.dateRdv.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ✅ Bordure colorée autour de la carte selon le statut
          border: Border.all(color: color, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1 : ID + Statut
              Row(
                children: [
                  Text(item.id,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.text)),
                  const Spacer(),
                  _statusBadge(item.statut),
                ],
              ),
              const SizedBox(height: 8),

              // Ligne 2 : Client
              Text(item.client,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),

              const SizedBox(height: 8),

              // Ligne 3 : Adresse + Heure + Priorité
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textSoft),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item.adresse,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSoft),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.access_time,
                      size: 13, color: AppColors.textSoft),
                  const SizedBox(width: 3),
                  Text(_heure(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSoft)),
                  const SizedBox(width: 8),
                  _priorityBadge(item.priorite),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(InterventionStatus s) {
    Color bg, fg;
    switch (s) {
      case InterventionStatus.enAttente:
        bg = AppColors.muted.withOpacity(0.15);
        fg = AppColors.muted;
        break;
      case InterventionStatus.enCours:
        bg = AppColors.warning.withOpacity(0.18);
        fg = const Color(0xFFA17900);
        break;
      case InterventionStatus.terminee:
        bg = AppColors.success.withOpacity(0.15);
        fg = const Color(0xFF1F7A45);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.label.toUpperCase(),
          style: TextStyle(
              color: fg,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    );
  }

  Widget _priorityBadge(String p) {
    Color color;
    switch (p) {
      case 'H':
        color = AppColors.danger;
        break;
      case 'B':
        color = AppColors.success;
        break;
      default:
        color = const Color(0xFFA17900);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('⚡$p',
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}