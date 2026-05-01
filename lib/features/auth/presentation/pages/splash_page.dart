import 'package:flutter/material.dart';

import 'login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
