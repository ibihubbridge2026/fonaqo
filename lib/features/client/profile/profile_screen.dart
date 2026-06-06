import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // --- SECTION HEADER PROFIL ---
          const ProfileHeader(),
          const SizedBox(height: 30),

          // --- SECTION PARAMÈTRES ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileParamItem(
                  icon: Icons.person_outline,
                  title: "Informations personnelles",
                  subtitle: "Modifier nom, email...",
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.profilePersonalInfo,
                  ),
                ),
                ProfileParamItem(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  subtitle: "Gérer vos alertes",
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.profileNotifications,
                  ),
                ),
                ProfileParamItem(
                  icon: Icons.security,
                  title: "Sécurité",
                  subtitle: "Mot de passe, biométrie",
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileSecurity),
                ),
                ProfileParamItem(
                  icon: Icons.location_on_outlined,
                  title: "Ma Localisation",
                  subtitle: "Position actuelle et adresses",
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.profileLocation);
                  },
                ),
                ProfileParamItem(
                  icon: Icons.language,
                  title: "Langue",
                  subtitle: "Français (FR)",
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileLanguage),
                ),
                ProfileParamItem(
                  icon: Icons.help_outline,
                  title: "Centre d'aide",
                  subtitle: "FAQ et support",
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileHelp),
                ),
                const SizedBox(height: 20),
                ProfileParamItem(
                  icon: Icons.logout,
                  title: "Déconnexion",
                  subtitle: "Quitter l'application",
                  isLogout: true,
                  onTap: () async {
                    // Afficher une confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Déconnexion'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // Appeler la méthode logout du AuthProvider
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();

                      // Rediriger vers l'écran de login
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// Élément de menu dans Profil.
///
/// [icon], [title], [subtitle] définissent la ligne principale.
/// [onTap] est appelée au tap (navigation vers l’écran associé).
/// [isLogout] change la couleur en rouge pour la sortie.
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
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    // Gestion utilisateur null
    if (user == null) {
      return const Center(
        child: Text(
          'Chargement du profil...',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar et nom
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
                          "${user.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}")
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.profilePersonalInfo),
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
          // Nom dynamique
          Text(
            user.username,
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD400), size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
