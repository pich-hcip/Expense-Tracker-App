import 'package:flutter/foundation.dart';

class ApiConstants {
  // true  = Local Spring Boot API
  // false = AWS deployed API
  static const bool useLocal = false;

  // =========================================================
  // IF USING WI-FI: Change this to your computer's IPv4 address
  // (Run 'ipconfig' in terminal to find it, e.g., 192.168.1.10)
  // =========================================================
  static const String computerIp = '192.168.1.10'; 

  static String get baseUrl {
    if (useLocal) {
      if (kIsWeb) {
        // Web browser
        return 'http://localhost:8080/api';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        
        // =======================================================
        // CHOOSE ONE OF THESE TWO LINES FOR YOUR PHYSICAL PHONE:
        // =======================================================
        
        // 1. USB Connection (You must run: adb reverse tcp:8080 tcp:8080)
        return 'http://localhost:8080/api'; 
        
        // 2. Wi-Fi Connection (Comment out the line above, uncomment this one)
        // return 'http://$computerIp:8080/api';
        
      } else {
        // iOS Simulator or macOS
        return 'http://localhost:8080/api';
      }
    } else {
      return 'http://52.86.162.15/api';
    }
  }
}