import 'package:flutter/material.dart';

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.person_outline,
                  title: "Compte",
                  subtitle: "Informations personnelles",
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: "Sécurité",
                  subtitle: "Mot de passe et protection",
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.tune,
                  title: "Préférences",
                  subtitle: "Personnalisation de l'application",
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  subtitle: "Gestion des alertes",
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.language,
                  title: "Langue",
                  subtitle: "Français",
                ),
                _buildDivider(),

                // Mode sombre switch
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dark_mode_outlined,
                          color: Color(0xFFFFD400),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mode sombre",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Activer le thème sombre",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        activeColor: const Color(0xFFFFD400),
                        onChanged: (value) {
                          setState(() {
                            isDarkMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildSectionCard(
              children: [
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Confidentialité",
                  subtitle: "Permissions et données",
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.help_outline,
                  title: "Aide & Support",
                  subtitle: "FAQ et assistance",
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
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
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFFD400),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 20,
    );
  }
}
