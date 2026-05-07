import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.role ?? "Requester";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      appBar: AppBar(
        title: Text("Dashboard - $role"),
      ),

      body: Center(
        child: Text(
          role == "Agent"
              ? "Dashboard Agent (Waiter)"
              : "Dashboard Requester (Client)",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}