/// Contrat profil et présence agent.
abstract class AgentProfileRepository {
  Future<bool> updateStatus({required bool isOnline});

  Future<Map<String, dynamic>> getProfile();

  Future<Map<String, dynamic>> updateProfile(dynamic data);

  /// Notifications compte agent (regroupées profil Sprint 0).
  Future<List<Map<String, dynamic>>> getNotifications();

  Future<bool> markNotificationAsRead(String notificationId);

  Future<bool> deleteNotification(String notificationId);

  Future<bool> markAllNotificationsAsRead();

  /// Boost visibilité agent.
  Future<bool> purchaseBoost(
    String boostType,
    double amount, {
    String paymentMethod = 'wallet',
    String? transactionId,
  });

  Future<List<Map<String, dynamic>>> getBoostPlans();

  Future<Map<String, dynamic>?> getActiveBoost();
}
