import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: ThemeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeProvider.backgroundColor,
        elevation: 0,
        title: Text(
          "Paramètres",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ThemeProvider.primaryTextColor,
          ),
        ),
        iconTheme: IconThemeData(color: ThemeProvider.primaryTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Général"),
            const SizedBox(height: 16),
            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.person_outline,
                  title: "Compte",
                  subtitle: "Informations personnelles",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: "Sécurité",
                  subtitle: "Mot de passe et protection",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.tune,
                  title: "Préférences",
                  subtitle: "Personnalisation de l'application",
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Application"),
            const SizedBox(height: 16),
            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  subtitle: "Gestion des alertes",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.language,
                  title: "Langue",
                  subtitle: "Français",
                  onTap: () {},
                ),
                _buildDivider(),

                // Mode sombre switch avec ThemeProvider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode 
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFFFF8D9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          themeProvider.isDarkMode 
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: themeProvider.isDarkMode 
                              ? ThemeProvider.accentColor
                              : ThemeProvider.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mode sombre",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ThemeProvider.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              themeProvider.isDarkMode
                                  ? "Thème sombre activé"
                                  : "Activer le thème sombre",
                              style: TextStyle(
                                fontSize: 13,
                                color: ThemeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        activeColor: ThemeProvider.accentColor,
                        activeTrackColor: ThemeProvider.successColor,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Support"),
            const SizedBox(height: 16),
            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Confidentialité",
                  subtitle: "Permissions et données",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.help_outline,
                  title: "Aide & Support",
                  subtitle: "FAQ et assistance",
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.errorColor.withOpacity( 0.1),
                  foregroundColor: ThemeProvider.errorColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Déconnexion",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // Version info
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeProvider.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ThemeProvider.primaryTextColor,
      ),
    );
  }

  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ThemeProvider.cardBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ThemeProvider.accentColor.withOpacity( 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: ThemeProvider.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeProvider.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ThemeProvider.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: ThemeProvider.cardBorderColor,
      height: 24,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeProvider.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Déconnexion",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ThemeProvider.primaryTextColor,
          ),
        ),
        content: Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(
            fontSize: 15,
            color: ThemeProvider.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Annuler",
              style: TextStyle(
                color: ThemeProvider.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la déconnexion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Déconnexion en cours..."),
                  backgroundColor: ThemeProvider.accentColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeProvider.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );
  }
}
