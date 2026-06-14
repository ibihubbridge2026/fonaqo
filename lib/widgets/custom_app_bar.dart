import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/notification_provider.dart';
import 'main_wrapper.dart';

/// Variante d'en-tête : logo marque pour l’accueil shell, titre d’onglet, ou pile détail avec retour.
enum CustomAppBarVariant {
  /// Accueil shell : avatar à gauche, notifications + assistance à droite.
  mainShellHome,

  /// Titre uniquement pour les autres onglets du shell (sans logo ni retour système plein cadre).
  mainShellSection,

  /// Écran empilé (ex. chat) : bouton retour personnalisé + titre facultatif sous forme de [Widget].
  detailStack,
}

/// Barre d’application commune : logo pour l’accueil ou flèche de retour pour les pages empilées.
///
/// Pour [variant] == [CustomAppBarVariant.mainShellHome], aucun titre texte : le logo est affiché.
///
/// Pour [CustomAppBarVariant.mainShellSection], [sectionTitle] est affiché centré (obligatoire).
///
/// Pour [CustomAppBarVariant.detailStack], [leadingOnBackPressed] définit la navigation lors du tap sur retour ;
/// si null, utilise [Navigator.maybePop]. [detailTitleWidget] remplace tout le titre (ex. rangée avatar + nom).
/// [detailTrailingActions] surcharge les boutons à droite (sinon espacement léger pour l’alignement uniquement).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Comportement visuel principal du bandeau.
  final CustomAppBarVariant variant;

  /// Index onglet profil dans le shell (client: 4, agent: 4).
  final int profileTabIndex;

  /// Titre centré lorsque `variant == mainShellSection`.
  final String? sectionTitle;

  /// Rubrique titre optionnel pour l’empilement (chat, détail mission, etc.).
  final Widget? detailTitleWidget;

  /// Boutons à droite en mode pile (ex. téléphone et menu du chat).
  final List<Widget>? detailTrailingActions;

  /// Déclenchée à la pression du bouton retour en mode pile ; défaut si null : pop.
  final VoidCallback? leadingOnBackPressed;

  /// Rappels optionnels pour remplacer le comportement par défaut.
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onSupportPressed;

  const CustomAppBar.mainShellHome({
    super.key,
    this.profileTabIndex = 4,
    this.onNotificationsPressed,
    this.onSupportPressed,
  })  : variant = CustomAppBarVariant.mainShellHome,
        sectionTitle = null,
        detailTitleWidget = null,
        detailTrailingActions = null,
        leadingOnBackPressed = null;

  const CustomAppBar.mainShellSection({
    super.key,
    required String this.sectionTitle,
    this.profileTabIndex = 4,
  })  : variant = CustomAppBarVariant.mainShellSection,
        detailTitleWidget = null,
        detailTrailingActions = null,
        leadingOnBackPressed = null,
        onNotificationsPressed = null,
        onSupportPressed = null;

  const CustomAppBar.detailStack({
    super.key,
    this.profileTabIndex = 4,
    this.detailTitleWidget,
    this.leadingOnBackPressed,
    this.detailTrailingActions,
    required String title,
  })  : variant = CustomAppBarVariant.detailStack,
        sectionTitle = null,
        onNotificationsPressed = null,
        onSupportPressed = null;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight + 12,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.mainShellHome:
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                final avatarUrl = user?.avatarUrl;
                final imageUrl = avatarUrl != null
                    ? "${avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}"
                    : null;

                return InkWell(
                  onTap: () {
                    final shell = MainShellScope.maybeOf(context);
                    if (shell != null) {
                      shell.setIndex(profileTabIndex);
                    }
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: CircleAvatar(
                    key: ValueKey(avatarUrl), // Force rebuild when URL changes
                    radius: 20,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl) as ImageProvider
                        : const AssetImage('assets/images/avatar/user.png'),
                    backgroundColor: Colors.grey[200],
                  ),
                );
              },
            ),
          ),
        );

      case CustomAppBarVariant.mainShellSection:
        return const SizedBox(width: 56);

      case CustomAppBarVariant.detailStack:
        return IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed:
              leadingOnBackPressed ?? () => Navigator.of(context).maybePop(),
        );
    }
  }

  Widget? _buildTitle(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.mainShellHome:
        return const SizedBox.shrink();

      case CustomAppBarVariant.mainShellSection:
        final title = sectionTitle ?? '';
        return Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        );

      case CustomAppBarVariant.detailStack:
        return DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.black),
          textAlign: TextAlign.start,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: detailTitleWidget ?? const SizedBox.shrink(),
          ),
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.mainShellHome:
        final bell = onNotificationsPressed ??
            () => Navigator.pushNamed(context, AppRoutes.notifications);
        final support = onSupportPressed ??
            () => Navigator.pushNamed(context, AppRoutes.aiAssistant);

        final notificationProvider = Provider.of<NotificationProvider>(context);

        return [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: bell,
              ),
              if (notificationProvider.unreadNotifications > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationProvider.unreadNotifications > 9
                          ? '9+'
                          : notificationProvider.unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.support_agent,
              color: Colors.black,
              size: 28,
            ),
            tooltip: 'Assistance',
            onPressed: support,
          ),
          const SizedBox(width: 8),
        ];

      case CustomAppBarVariant.mainShellSection:
        return const [SizedBox(width: 48), SizedBox(width: 48)];

      case CustomAppBarVariant.detailStack:
        final extra = detailTrailingActions;
        if (extra != null && extra.isNotEmpty) {
          return extra;
        }
        return const [SizedBox(width: kToolbarHeight)];
    }
  }
}
