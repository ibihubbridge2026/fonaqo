import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/widgets/profile/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const ProfileHeader(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileParamItem(
                  icon: Icons.person_outline,
                  title: 'Informations personnelles',
                  subtitle: 'Modifier nom, email...',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.profilePersonalInfo,
                  ),
                ),
                ProfileParamItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Mon Portefeuille',
                  subtitle: 'Solde et historique des transactions',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
                ),
                ProfileParamItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Gérer vos alertes',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.profileNotifications,
                  ),
                ),
                ProfileParamItem(
                  icon: Icons.security,
                  title: 'Sécurité',
                  subtitle: 'Mot de passe, biométrie',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileSecurity),
                ),
                ProfileParamItem(
                  icon: Icons.location_on_outlined,
                  title: 'Ma Localisation',
                  subtitle: 'Position actuelle et adresses',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.profileLocation);
                  },
                ),
                ProfileParamItem(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: 'Français (FR)',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileLanguage),
                ),
                ProfileParamItem(
                  icon: Icons.help_outline,
                  title: 'Centre d\'aide',
                  subtitle: 'FAQ et support',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileHelp),
                ),
                const SizedBox(height: 20),
                ProfileParamItem(
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  subtitle: 'Quitter l\'application',
                  isLogout: true,
                  onTap: () async {
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

                    if (confirm == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
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
