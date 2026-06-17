import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/services/referral_storage_service.dart';
import 'package:fonaco/features/agent/presentation/dashboard/screens/agent_dashboard_screen.dart';
import 'package:fonaco/features/agent/presentation/dashboard/screens/agent_mission_tracking_screen.dart';
import 'package:fonaco/features/agent/presentation/kyc/agent_kyc_submit_screen.dart';
import 'package:fonaco/features/agent/presentation/kyc/kyc_lock_screen.dart';
import 'package:fonaco/features/agent/presentation/profile/screens/agent_personal_info_screen.dart';
import 'package:fonaco/features/agent/screens/agent_boost_screen.dart';
import 'package:fonaco/features/agent/screens/agent_mission_detail_screen.dart';
import 'package:fonaco/features/ai/screens/ai_assistant_screen.dart';
import 'package:fonaco/features/auth/complete_profile_screen.dart';
import 'package:fonaco/features/auth/forgot_password_screen.dart';
import 'package:fonaco/features/auth/login_screen.dart';
import 'package:fonaco/features/auth/register_screen.dart';
import 'package:fonaco/features/chat/screens/chat_detail_screen.dart';
import 'package:fonaco/features/chat/screens/chat_list_screen.dart';
import 'package:fonaco/features/client/missions/mission_detail_screen.dart';
import 'package:fonaco/features/client/missions/missions_screen.dart';
import 'package:fonaco/features/client/missions/screens/mission_tracking_screen.dart';
import 'package:fonaco/features/client/notifications/notifications_screen.dart';
import 'package:fonaco/features/client/profile/screens/help_center_screen.dart';
import 'package:fonaco/features/client/profile/screens/language_screen.dart';
import 'package:fonaco/features/client/profile/screens/location_settings_screen.dart';
import 'package:fonaco/features/client/profile/screens/notifications_settings_screen.dart';
import 'package:fonaco/features/client/profile/screens/personal_info_screen.dart';
import 'package:fonaco/features/client/profile/screens/security_settings_screen.dart';
import 'package:fonaco/features/client/screens/client_agent_profile_screen.dart';
import 'package:fonaco/features/client/screens/favorite_agents_screen.dart';
import 'package:fonaco/features/client/wallet/client_wallet_screen.dart';
import 'package:fonaco/features/litiges/litige_screen.dart';
import 'package:fonaco/features/onboarding/onboarding_screen.dart';
import 'package:fonaco/features/rating/rating_screen.dart';
import 'package:fonaco/widgets/auth_guard.dart';
import 'package:fonaco/widgets/main_wrapper.dart';

/// Navigation typée via GoRouter (remplace progressivement `pushNamed`).
GoRouter createAppRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  required bool isFirstTime,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => AuthGuard(isFirstTime: isFirstTime),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.referralJoin,
        redirect: (context, state) async {
          final code = state.pathParameters['code'];
          if (code != null && code.trim().isNotEmpty) {
            await ReferralStorageService.instance.save(code);
          }
          return AppRoutes.register;
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.mainShell,
        builder: (_, __) => const MainWrapper(),
      ),
      GoRoute(
        path: AppRoutes.missionDetail,
        builder: (context, state) {
          final args = _extraMap(state);
          return MissionDetailScreen(
            missionId: args['missionId']?.toString(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.favoriteAgents,
        builder: (_, __) => const FavoriteAgentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.litige,
        builder: (_, __) => const LitigeScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, __) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, __) => const ClientWalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (_, __) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications,
        builder: (_, __) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileLanguage,
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentProfilePersonalInfo,
        builder: (_, __) => const AgentPersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentMissionTracking,
        builder: (context, state) {
          final args = _extraMap(state);
          final mission = args['mission'];
          if (mission is MissionModel) {
            return AgentMissionTrackingScreen(mission: mission);
          }
          return const Scaffold(
            body: Center(child: Text('Mission introuvable')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.securitySettings,
        builder: (_, __) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileLocation,
        builder: (_, __) => const LocationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.missionTracking,
        builder: (context, state) {
          final args = _extraMap(state);
          return MissionTrackingScreen(
            missionId: args['missionId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.rating,
        builder: (context, state) {
          final args = _extraMap(state);
          return RatingScreen(
            missionId: args['missionId']?.toString(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentMissionsExplorer,
        builder: (_, __) => const AgentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentMissionDetail,
        builder: (context, state) {
          final args = _extraMap(state);
          final mission = args['mission'];
          if (mission is MissionModel) {
            return AgentMissionDetailScreen(mission: mission);
          }
          return const Scaffold(
            body: Center(child: Text('Mission introuvable')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.agentDashboard,
        builder: (_, __) => const AgentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentKycLock,
        builder: (_, __) => const KycLockScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentKycSubmit,
        builder: (_, __) => const AgentKycSubmitScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentBoost,
        builder: (_, __) => const AgentBoostScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) {
          final args = _extraMap(state);
          return ChatDetailScreen(
            chatId: args['conversationId']?.toString() ??
                args['chatId']?.toString() ??
                '',
            userName: args['userName']?.toString() ?? 'Utilisateur',
            missionId: args['missionId']?.toString(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.missionsAvailable,
        builder: (_, __) => MissionsScreen(
          showCreateMissionListenable: ValueNotifier(false),
        ),
      ),
      GoRoute(
        path: AppRoutes.agentProfile,
        builder: (context, state) {
          final args = state.extra;
          return ClientAgentProfileScreen.fromRouteArguments(
            args is Map<String, dynamic> ? args : null,
          );
        },
      ),
    ],
  );
}

Map<String, dynamic> _extraMap(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map<String, dynamic>) return extra;
  return <String, dynamic>{};
}

/// Extension pour navigation typée depuis n'importe quel [BuildContext].
extension FonacoGoRouter on BuildContext {
  void goRoute(String path, {Object? extra}) => go(path, extra: extra);

  void pushRoute(String path, {Object? extra}) => push(path, extra: extra);
}
