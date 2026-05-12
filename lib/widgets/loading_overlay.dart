import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool showLogo;

  const LoadingOverlay({
    super.key,
    this.message,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassDecoration(
            color: Colors.white,
            borderRadius: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLogo) ...[
                // Logo FONACO animé
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'FQ',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Spinner animé personnalisé
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),

              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingOverlayController {
  static OverlayEntry? _overlay;

  static void show(BuildContext context,
      {String? message, bool showLogo = true}) {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => LoadingOverlay(
        message: message,
        showLogo: showLogo,
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    if (_overlay != null) {
      _overlay?.remove();
      _overlay = null;
    }
  }
}

// Extension pour faciliter l'utilisation
extension LoadingOverlayExtension on BuildContext {
  void showLoading({String? message, bool showLogo = true}) {
    LoadingOverlayController.show(this, message: message, showLogo: showLogo);
  }

  void hideLoading() {
    LoadingOverlayController.hide();
  }
}
