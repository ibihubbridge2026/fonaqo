import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/widgets.dart';

class SplashConfig {
  static void initializeSplash(WidgetsBinding widgetsBinding) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  static Future<void> removeSplash() async {
    FlutterNativeSplash.remove();
  }
}
