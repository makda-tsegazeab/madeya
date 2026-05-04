import 'package:flutter/material.dart';

import '../../data/auth_session_restore.dart';
import '../../data/token_storage.dart';
import 'login_page.dart';
import 'owner_dashboard_page.dart';
import 'station_worker_dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const String routeName = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final TokenStorage _tokenStorage = SecureTokenStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final session = await restoreAuthSession(_tokenStorage);
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }

    switch (session.user.role) {
      case 'VEHICLE_OWNER':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OwnerDashboardPage(profile: session.user),
          ),
        );
        return;
      case 'STATION_WORKER':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                StationWorkerDashboardPage(profile: session.user),
          ),
        );
        return;
      default:
        await _tokenStorage.clearAccessToken();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
