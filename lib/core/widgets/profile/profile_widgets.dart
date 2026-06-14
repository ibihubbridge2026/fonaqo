import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';

/// Élément de menu profil (design V1 partagé Client / Agent).
class ProfileParamItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLogout;

  const ProfileParamItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? Colors.red : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

/// En-tête profil avec avatar et accès édition.
class ProfileHeader extends StatelessWidget {
  final String editRoute;

  const ProfileHeader({
    super.key,
    this.editRoute = AppRoutes.profilePersonalInfo,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Chargement du profil...',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }

    final displayName = user.djangoUsername?.isNotEmpty == true
        ? user.djangoUsername!
        : user.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xFFFFD400),
                child: CircleAvatar(
                  key: ValueKey(user.avatarUrl),
                  radius: 52,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(
                          '${user.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                        )
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, editRoute),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFFFFD400),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
