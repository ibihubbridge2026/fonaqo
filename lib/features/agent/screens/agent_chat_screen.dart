import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

/// Redirige vers l'écran de chat unifié.
class AgentChatScreen extends StatelessWidget {
  final String missionId;
  final String userName;

  const AgentChatScreen({
    super.key,
    required this.missionId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.chatDetail,
        arguments: {
          'missionId': missionId,
          'userName': userName,
        },
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
