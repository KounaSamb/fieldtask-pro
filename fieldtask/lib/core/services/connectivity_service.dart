import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _update(result);
      _connectivity.onConnectivityChanged.listen(_update);
    } catch (_) {}
  }

  void _update(List<ConnectivityResult> result) {
    final online = !result.contains(ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
  }
}
