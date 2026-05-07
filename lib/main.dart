import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/missions/screens/create_mission_screen.dart';
import 'features/missions/mission_detail_screen.dart';
import 'features/missions/widgets/step_5_tracking_view.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/profile/screens/language_screen.dart';
import 'features/profile/screens/notifications_settings_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/profile/screens/security_settings_screen.dart';
import 'widgets/main_wrapper.dart';
void main() {
  runApp(const FonacoApp());
}

class FonacoApp extends StatelessWidget {
  const FonacoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FONACO',
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const GettingScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.mainShell: (context) => const MainWrapper(),
        AppRoutes.createMission: (context) => const CreateMissionScreen(),
        AppRoutes.profilePersonalInfo: (context) => const PersonalInfoScreen(),
        AppRoutes.profileNotifications: (context) => const NotificationsSettingsScreen(),
        AppRoutes.profileSecurity: (context) => const SecuritySettingsScreen(),
        AppRoutes.profileLanguage: (context) => const LanguageScreen(),
        AppRoutes.profileHelp: (context) => const HelpCenterScreen(),
        AppRoutes.chat: (context) => const ChatScreen(),
        AppRoutes.missionDetail: (context) => const MissionDetailScreen(),
      },
    );
  }
}
