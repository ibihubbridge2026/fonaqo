/// Résultat d'une tentative de rafraîchissement JWT.
enum TokenRefreshResult {
  success,
  networkError,
  sessionRevoked,
  failed,
}
