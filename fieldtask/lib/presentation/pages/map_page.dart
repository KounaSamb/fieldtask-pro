import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/intervention.dart';
import '../blocs/intervention_cubit.dart';
import 'intervention_detail_page.dart';

/// Carte reelle (OpenStreetMap) : marqueurs des interventions + position GPS.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _controller = MapController();
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _locate({bool center = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _msg('Localisation désactivée sur cet appareil');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _msg('Permission de localisation refusée');
        return;
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _me = LatLng(pos.latitude, pos.longitude));
      if (center) _controller.move(_me!, 14);
    } catch (_) {
      _msg('Position GPS indisponible');
    }
  }

  void _showQuickCard(Intervention item) {
    final km = _me == null
        ? null
        : const Distance().as(
            LengthUnit.Kilometer, _me!, LatLng(item.latitude, item.longitude));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.id,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSoft)),
            const SizedBox(height: 4),
            Text(item.client,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(item.adresse),
            const SizedBox(height: 6),
            Text('${item.statut.label}'
                '${km == null ? '' : '  •  ${km.toStringAsFixed(1)} km de vous'}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InterventionDetailPage(intervention: item),
                    ),
                  );
                },
                child: const Text('Ouvrir la fiche'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Carte des interventions')),
      body: BlocBuilder<InterventionCubit, InterventionState>(
        builder: (context, state) {
          final list =
              state is InterventionLoaded ? state.all : <Intervention>[];
          final points =
              list.map((e) => LatLng(e.latitude, e.longitude)).toList();
          return Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter:
                      points.isEmpty ? const LatLng(14.7, -17.2) : points.first,
                  initialZoom: 10,
                  initialCameraFit: points.length > 1
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(70),
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.techfix.fieldtask_pro',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_me != null)
                        Marker(
                          point: _me!,
                          width: 24,
                          height: 24,
                          child: const _UserPosition(),
                        ),
                      for (final item in list)
                        Marker(
                          point: LatLng(item.latitude, item.longitude),
                          width: 70,
                          height: 66,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _showQuickCard(item),
                            child: _MapPin(status: item.statut, label: item.id),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© contributeurs OpenStreetMap'),
                    ],
                  ),
                ],
              ),
              // Bouton "ma position"
              Positioned(
                right: 16,
                bottom: 96,
                child: FloatingActionButton.small(
                  heroTag: 'locate',
                  backgroundColor: Colors.white,
                  onPressed: () => _locate(center: true),
                  child:
                      const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
              // Resume en bas
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${list.length} interventions'
                          '${_me == null ? '' : '  •  position GPS active'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserPosition extends StatelessWidget {
  const _UserPosition();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final InterventionStatus status;
  final String label;
  const _MapPin({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case InterventionStatus.enCours:
        color = AppColors.warning;
        break;
      case InterventionStatus.terminee:
        color = AppColors.success;
        break;
      case InterventionStatus.enAttente:
        color = AppColors.muted;
        break;
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.room, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
