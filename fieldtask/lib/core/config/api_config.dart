import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Telephone reel : mettez l'IP du PC, ex. 'http://192.168.1.20:3000'
  static const String hostOverride = '';

  /// Emulateur Android -> 10.0.2.2 ; Windows / autres -> localhost
  static String get baseUrl {
    if (hostOverride.isNotEmpty) return hostOverride;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
