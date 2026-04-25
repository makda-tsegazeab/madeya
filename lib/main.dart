import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/hero_page.dart';
import 'features/auth/presentation/pages/role_selection_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/station_worker_login_page.dart';
import 'features/auth/presentation/pages/vehicle_owner_login_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/verify_reset_code_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/announcements/presentation/pages/announcements_page.dart';

void main() {
  runApp(const MadeyaApp());
}

class MadeyaApp extends StatelessWidget {
  const MadeyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madeya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      initialRoute: SplashPage.routeName,
      routes: {
        SplashPage.routeName: (_) => const SplashPage(),
        HeroPage.routeName: (_) => const HeroPage(),
        RoleSelectionPage.routeName: (_) => const RoleSelectionPage(),
        VehicleOwnerLoginPage.routeName: (_) => const VehicleOwnerLoginPage(),
        StationWorkerLoginPage.routeName: (_) =>
            const StationWorkerLoginPage(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
        VerifyResetCodePage.routeName: (_) => const VerifyResetCodePage(),
        ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
        ChangePasswordPage.routeName: (_) => const ChangePasswordPage(),
        AnnouncementsPage.routeName: (_) => const AnnouncementsPage(),
      },
    );
  }
}
