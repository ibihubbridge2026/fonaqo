import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Widget? customIllustration;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          color: Colors.white,
          borderRadius: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration ou icône
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 50,
                  color: AppTheme.errorColor,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Réessayer
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widgets prédéfinis pour les erreurs communes
class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Erreur de connexion',
      message: 'Vérifiez votre connexion internet et réessayez.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }
}

class ServerErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Erreur serveur',
      message: 'Nos services sont temporairement indisponibles. Réessayez plus tard.',
      onRetry: onRetry,
      icon: Icons.cloud_off,
    );
  }
}

class LocationErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const LocationErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Localisation indisponible',
      message: 'Activez votre GPS ou autorisez l\'accès à votre position.',
      onRetry: onRetry,
      icon: Icons.location_off,
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          color: Colors.white,
          borderRadius: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
