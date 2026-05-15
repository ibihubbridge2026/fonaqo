import 'package:flutter/material.dart';

/// Mixin pour centraliser la gestion d'état commun à tous les écrans
/// Réduit la duplication de code pour _isLoading, _error et les widgets associés
mixin BaseScreenState<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // Setters protégés
  @protected
  void setLoading(bool value, {String? message}) {
    if (mounted) {
      setState(() {
        _isLoading = value;
        if (message != null && value) {
          _successMessage = message;
        } else if (!value) {
          _successMessage = null;
        }
      });
    }
  }

  @protected
  void setError(String? error) {
    if (mounted) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @protected
  void setSuccess(String? message) {
    if (mounted) {
      setState(() {
        _successMessage = message;
        _error = null;
        _isLoading = false;
      });
    }
  }

  @protected
  void clearError() {
    if (mounted) {
      setState(() {
        _error = null;
      });
    }
  }

  @protected
  void clearSuccess() {
    if (mounted) {
      setState(() {
        _successMessage = null;
      });
    }
  }

  @protected
  void clearAll() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = null;
        _successMessage = null;
      });
    }
  }

  // Widgets utilitaires
  Widget buildLoadingIndicator({
    double? size,
    Color? color,
    double? strokeWidth,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: SizedBox(
          width: size ?? 24,
          height: size ?? 24,
          child: CircularProgressIndicator(
            color: color ?? Theme.of(context).primaryColor,
            strokeWidth: strokeWidth ?? 2.0,
          ),
        ),
      ),
    );
  }

  Widget buildErrorWidget({
    VoidCallback? onRetry,
    String? customMessage,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSuccessWidget({
    VoidCallback? onDismiss,
    String? customMessage,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.check_circle,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customMessage ?? _successMessage ?? 'Opération réussie',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: Colors.green[600], size: 20),
            ),
        ],
      ),
    );
  }

  // Méthode utilitaire pour exécuter une opération avec gestion automatique du loading
  @protected
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? errorMessage,
    String? successMessage,
    bool showErrorDialog = false,
  }) async {
    try {
      setLoading(true, message: loadingMessage);
      clearError();
      clearSuccess();

      final result = await operation();

      if (successMessage != null) {
        setSuccess(successMessage);
      }

      return result;
    } catch (e) {
      final errorMsg = errorMessage ?? e.toString();
      
      if (showErrorDialog) {
        _showErrorDialog(errorMsg);
      } else {
        setError(errorMsg);
      }
      
      return null;
    } finally {
      setLoading(false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Builder conditionnel pour le contenu principal
  Widget buildConditionalContent({
    required Widget Function() contentBuilder,
    Widget Function()? loadingBuilder,
    Widget Function()? errorBuilder,
    Widget Function()? successBuilder,
    VoidCallback? onRetry,
  }) {
    if (_isLoading) {
      return loadingBuilder?.call() ?? buildLoadingIndicator();
    }

    if (_error != null) {
      return errorBuilder?.call() ?? buildErrorWidget(onRetry: onRetry);
    }

    if (_successMessage != null && successBuilder != null) {
      return successBuilder!.call();
    }

    return contentBuilder();
  }
}
