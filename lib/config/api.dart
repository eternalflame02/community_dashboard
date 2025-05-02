// lib/config/api.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://192.168.79.64:3000'; // your LAN IP for mobile/desktop
  }
}