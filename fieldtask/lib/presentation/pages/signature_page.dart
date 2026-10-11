import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/intervention_repository.dart';

class SignaturePage extends StatefulWidget {
  final String interventionId;
  const SignaturePage({super.key, required this.interventionId});
  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final _padKey = GlobalKey();
  final _points = <List<Offset>>[];
  List<Offset>? _current;

  /// Dessine la signature sur fond blanc et la renvoie en PNG base64.
  Future<String> _toPngBase64() async {
    final size = _padKey.currentContext?.size ?? const Size(300, 200);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _SignaturePainter(points: _points).paint(canvas, size);
    final img = await recorder
        .endRecording()
        .toImage(size.width.round(), size.height.round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return base64Encode(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Signature du client')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipRRect(
                  key: _padKey,
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      if (_points.isEmpty)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.draw,
                                size: 60,
                                color: AppColors.muted,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Signez ici',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onPanStart: (d) {
                          setState(() => _current = [d.localPosition]);
                        },
                        onPanUpdate: (d) {
                          setState(() => _current?.add(d.localPosition));
                        },
                        onPanEnd: (_) {
                          if (_current != null) {
                            _points.add(_current!);
                            _current = null;
                          }
                        },
                        child: CustomPaint(
                          painter: _SignaturePainter(
                            points: _points,
                            current: _current,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSoft,
                    ),
                    onPressed: () => setState(() {
                      _points.clear();
                      _current = null;
                    }),
                    child: const Text('Effacer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_points.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez signer')),
                        );
                        return;
                      }
                      final png = await _toPngBase64();
                      await InterventionRepository()
                          .saveSignature(widget.interventionId, png);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signature enregistrée ✅'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Valider',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> points;
  final List<Offset>? current;
  _SignaturePainter({required this.points, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in points) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
    if (current != null && current!.length > 1) {
      for (int i = 0; i < current!.length - 1; i++) {
        canvas.drawLine(current![i], current![i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
