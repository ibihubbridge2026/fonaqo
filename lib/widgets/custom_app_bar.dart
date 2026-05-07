import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';

/// Variante d'en-tête : logo marque pour l’accueil shell, titre d’onglet, ou pile détail avec retour.
enum CustomAppBarVariant {
  /// Logo FONACO centré, avatar à gauche, actions notifications + chat (onglet principal).
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

  /// Titre centré lorsque `variant == mainShellSection`.
  final String? sectionTitle;

  /// Rubrique titre optionnel pour l’empilement (chat, détail mission, etc.).
  final Widget? detailTitleWidget;

  /// Boutons à droite en mode pile (ex. téléphone et menu du chat).
  final List<Widget>? detailTrailingActions;

  /// Déclenchée à la pression du bouton retour en mode pile ; défaut si null : pop.
  final VoidCallback? leadingOnBackPressed;

  /// Rappels optionnels pour remplacer le comportement par défaut vers [AppRoutes.chat].
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onChatPressed;

  const CustomAppBar.mainShellHome({
    super.key,
    this.onNotificationsPressed,
    this.onChatPressed,
  })  : variant = CustomAppBarVariant.mainShellHome,
        sectionTitle = null,
        detailTitleWidget = null,
        detailTrailingActions = null,
        leadingOnBackPressed = null;

  const CustomAppBar.mainShellSection({
    super.key,
    required String this.sectionTitle,
  })  : variant = CustomAppBarVariant.mainShellSection,
        detailTitleWidget = null,
        detailTrailingActions = null,
        leadingOnBackPressed = null,
        onNotificationsPressed = null,
        onChatPressed = null;

  const CustomAppBar.detailStack({
    super.key,
    this.detailTitleWidget,
    this.leadingOnBackPressed,
    this.detailTrailingActions,
  })  : variant = CustomAppBarVariant.detailStack,
        sectionTitle = null,
        onNotificationsPressed = null,
        onChatPressed = null;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const Color _accent = Color(0xFFFFD400);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      automaticallyImplyLeading: false,
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
            child: CircleAvatar(
              radius: 20,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/avatar/user.png',
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, _, _) {
                    return const Icon(Icons.person, color: Colors.black54);
                  },
                ),
              ),
            ),
          ),
        );

      case CustomAppBarVariant.mainShellSection:
        return const SizedBox(width: 56);

      case CustomAppBarVariant.detailStack:
        return IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: leadingOnBackPressed ?? () => Navigator.of(context).maybePop(),
        );
    }
  }

  Widget? _buildTitle(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.mainShellHome:
        return Image.asset(
          'assets/icon/fonaco.png',
          height: 32,
          errorBuilder: (_, _, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/favicon.png',
                  width: 22,
                  errorBuilder: (_, _, _) => const Icon(Icons.bolt, color: _accent, size: 22),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FONAQO',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        );

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
        final chat = onChatPressed ?? () => Navigator.pushNamed(context, AppRoutes.chat);
        final bell = onNotificationsPressed ?? () {};
        return [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54),
            onPressed: bell,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black54),
            onPressed: chat,
          ),
        ];

      case CustomAppBarVariant.mainShellSection:
        return const [
          SizedBox(width: 48),
          SizedBox(width: 48),
        ];

      case CustomAppBarVariant.detailStack:
        final extra = detailTrailingActions;
        if (extra != null && extra.isNotEmpty) {
          return extra;
        }
        return const [SizedBox(width: kToolbarHeight)];
    }
  }
}
