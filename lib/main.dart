import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/verify_reset_code_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/announcements/presentation/pages/announcements_page.dart';
import 'features/queue/presentation/pages/queue_status_page.dart';
import 'features/transactions/presentation/pages/history_page.dart';

void main() {
  runApp(const MadeyaApp());
}

class MadeyaApp extends StatelessWidget {
  const MadeyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekelle Fuel Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      initialRoute: SplashPage.routeName,
      routes: {
        SplashPage.routeName: (_) => const SplashPage(),
        LoginPage.routeName: (_) => const LoginPage(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
        VerifyResetCodePage.routeName: (_) => const VerifyResetCodePage(),
        ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
        ChangePasswordPage.routeName: (_) => const ChangePasswordPage(),
        AnnouncementsPage.routeName: (_) => const AnnouncementsPage(),
        QueueStatusPage.routeName: (_) => const QueueStatusPage(),
        HistoryPage.routeName: (_) => const HistoryPage(),
      },
    );
  }
}
