import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Service de gestion des animations Lottie
/// Permet d'afficher des animations premium pour les succès, erreurs, chargements, etc.
class LottieAnimationService {
  static final LottieAnimationService _instance =
      LottieAnimationService._internal();
  factory LottieAnimationService() => _instance;
  LottieAnimationService._internal();

  bool _isInitialized = false;

  /// Initialisation du service
  void init() {
    _isInitialized = true;
  }

  /// Affiche une animation de succès (checkmark vert)
  Widget buildSuccessAnimation({double width = 200, double height = 200}) {
    return _buildLottie(
      'success',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/success.json',
    );
  }

  /// Affiche une animation d'erreur (croix rouge)
  Widget buildErrorAnimation({double width = 200, double height = 200}) {
    return _buildLottie(
      'error',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/error.json',
    );
  }

  /// Affiche une animation de chargement (spinner)
  Widget buildLoadingAnimation({double width = 150, double height = 150}) {
    return _buildLottie(
      'loading',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/loading.json',
    );
  }

  /// Affiche une animation de paiement réussi
  Widget buildPaymentSuccessAnimation({
    double width = 250,
    double height = 250,
  }) {
    return _buildLottie(
      'payment_success',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/payment_success.json',
    );
  }

  /// Affiche une animation de mission complétée
  Widget buildMissionCompleteAnimation({
    double width = 250,
    double height = 250,
  }) {
    return _buildLottie(
      'mission_complete',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/mission_complete.json',
    );
  }

  /// Affiche une animation de bienvenue
  Widget buildWelcomeAnimation({double width = 300, double height = 300}) {
    return _buildLottie(
      'welcome',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/welcome.json',
    );
  }

  /// Affiche une animation de recherche IA
  Widget buildAiSearchAnimation({double width = 180, double height = 180}) {
    return _buildLottie(
      'ai_search',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/ai_search.json',
    );
  }

  /// Affiche une animation de notification
  Widget buildNotificationAnimation({double width = 100, double height = 100}) {
    return _buildLottie(
      'notification',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/notification.json',
    );
  }

  /// Affiche une animation de boost activé
  Widget buildBoostAnimation({double width = 200, double height = 200}) {
    return _buildLottie(
      'boost',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/boost.json',
    );
  }

  /// Affiche une animation vide (empty state)
  Widget buildEmptyStateAnimation({
    String type = 'default',
    double width = 200,
    double height = 200,
  }) {
    return _buildLottie(
      'empty_$type',
      width: width,
      height: height,
      fallbackAsset: 'assets/animations/empty_state.json',
    );
  }

  /// Méthode interne pour construire l'animation Lottie
  Widget _buildLottie(
    String name, {
    required double width,
    required double height,
    required String fallbackAsset,
  }) {
    // Essayer de charger depuis le réseau (URL CDN) ou depuis les assets locaux
    // Pour la production, vous pouvez héberger les animations sur un CDN
    
    try {
      // Option 1: Depuis les assets locaux (recommandé pour la performance)
      return Lottie.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        repeat: name == 'loading' || name == 'ai_search',
        animate: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Erreur chargement Lottie $name: $error');
          // Fallback: afficher une icône si l'animation échoue
          return _buildFallbackIcon(name, width: width, height: height);
        },
      );
    } catch (e) {
      debugPrint('❌ Exception Lottie $name: $e');
      return _buildFallbackIcon(name, width: width, height: height);
    }
  }

  /// Widget de fallback si Lottie n'est pas disponible
  Widget _buildFallbackIcon(String name,
      {required double width, required double height}) {
    IconData icon;
    Color color;

    switch (name) {
      case 'success':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'error':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case 'loading':
        return SizedBox(
          width: width,
          height: height,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        );
      case 'payment_success':
      case 'mission_complete':
        icon = Icons.celebration;
        color = Color(0xFFFFD400);
        break;
      case 'welcome':
        icon = Icons.waving_hand;
        color = Color(0xFFFFD400);
        break;
      case 'ai_search':
        icon = Icons.auto_awesome;
        color = Colors.blue;
        break;
      case 'notification':
        icon = Icons.notifications_active;
        color = Colors.orange;
        break;
      case 'boost':
        icon = Icons.trending_up;
        color = Color(0xFFFFD400);
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Icon(
      icon,
      size: width * 0.6,
      color: color,
    );
  }

  /// Affiche un dialog avec une animation de succès
  Future<void> showSuccessDialog({
    required BuildContext context,
    String title = "Succès !",
    String message = "L'action a été réalisée avec succès.",
    Function()? onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSuccessAnimation(width: 150, height: 150),
                SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD400),
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "CONTINUER",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche un dialog avec une animation de paiement réussi
  Future<void> showPaymentSuccessDialog({
    required BuildContext context,
    double amount = 0.0,
    String currency = "FCFA",
    Function()? onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildPaymentSuccessAnimation(width: 200, height: 200),
                SizedBox(height: 24),
                Text(
                  "Paiement Réussi !",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Vous avez reçu $amount $currency",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Le montant a été ajouté à votre solde.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD400),
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "VOIR MON SOLDE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche un dialog avec une animation de mission terminée
  Future<void> showMissionCompleteDialog({
    required BuildContext context,
    String missionTitle = "Mission",
    double earnings = 0.0,
    Function()? onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildMissionCompleteAnimation(width: 200, height: 200),
                SizedBox(height: 24),
                Text(
                  "Mission Terminée !",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  missionTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "+$earnings FCFA gagnés",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD400),
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "RETOUR AU DASHBOARD",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
