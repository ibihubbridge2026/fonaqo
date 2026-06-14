import 'package:flutter/material.dart';

/// Configuration globale de l'application (valeurs par défaut, surchargeables via API admin).
class AppConfiguration {
  AppConfiguration._();

  static final AppConfiguration instance = AppConfiguration._();

  /// E-mail support client.
  String clientSupportEmail = 'support@fonaqo.bj';

  /// E-mail support agent.
  String agentSupportEmail = 'support@fonaqo.bj';

  /// Numéro service client.
  String clientServicePhone = '+229 01 50 08 82 10';

  /// Plans boost par défaut si l'API ne renvoie rien.
  List<Map<String, dynamic>> defaultBoostPlans = [
    {
      'id': 'day',
      'name': 'Journée',
      'price': 200,
      'duration_hours': 24,
      'visibility_multiplier': '1.5',
    },
    {
      'id': 'week',
      'name': 'Semaine',
      'price': 1000,
      'duration_hours': 168,
      'visibility_multiplier': '2.0',
    },
    {
      'id': 'month',
      'name': 'Mois',
      'price': 2000,
      'duration_hours': 720,
      'visibility_multiplier': '2.5',
    },
  ];

  /// Charge la configuration depuis l'API (future intégration super-admin).
  Future<void> loadFromApi() async {
    // Point d'extension : GET admin/settings/ ou équivalent.
  }

  /// Met à jour la configuration à chaud (ex. après fetch API).
  void applyRemote(Map<String, dynamic> data) {
    final clientMail = data['client_support_email'];
    if (clientMail is String && clientMail.isNotEmpty) {
      clientSupportEmail = clientMail;
    }
    final agentMail = data['agent_support_email'];
    if (agentMail is String && agentMail.isNotEmpty) {
      agentSupportEmail = agentMail;
    }
    final phone = data['client_service_phone'];
    if (phone is String && phone.isNotEmpty) {
      clientServicePhone = phone;
    }
    final plans = data['boost_plans'];
    if (plans is List && plans.isNotEmpty) {
      defaultBoostPlans = List<Map<String, dynamic>>.from(
        plans.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
  }
}

/// Couleur vert success pour les commutateurs agent.
const kAgentSuccessGreen = Color(0xFF2EC4B6);
