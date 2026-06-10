import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use 10.0.2.2 for Emulator, but use your computer's IP (e.g., 192.168.x.x) for physical device
      return 'http://10.0.2.2:3000';
    }
    if (Platform.isIOS) return 'http://localhost:3000';
    return 'http://localhost:3000';
  }
}
