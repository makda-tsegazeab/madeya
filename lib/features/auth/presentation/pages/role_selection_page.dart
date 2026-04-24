import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const String routeName = '/role-selection';

  static const Color _bg = Color(0xFFEEF2F6);
  static const Color _primary = Color(0xFF0E4F90);
  static const Color _textDark = Color(0xFF111317);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildIntro(),
              const SizedBox(height: 10),
              const _RoleCard(
                icon: Icons.directions_car_filled_rounded,
                title: 'Vehicle Owner',
                description:
                    'Manage your fuel quota, track usage history, and view\nreal-time station availability across the city.',
                action: 'Continue as Owner',
                actionColor: _primary,
                routeName: '/owner-login',
              ),
              const SizedBox(height: 10),
              const _RoleCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Station Worker',
                description:
                    'Scan vehicle QR codes, verify transactions in real-time,\nand manage station fuel inventory and reports.',
                action: 'Continue as Worker',
                actionColor: Color(0xFF2A5B88),
                routeName: '/worker-login',
              ),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/madeya_logo.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_gas_station_rounded,
              size: 32,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'MADEYA',
          style: TextStyle(
            fontSize: 32,
            height: 1.0,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: _primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return const Column(
      children: [
        Text(
          'Choose how you want to\ncontinue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: _textDark,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'DIGITAL INFRASTRUCTURE OF ETHIOPIA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF727A88),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.actionColor,
    required this.routeName,
  });

  final IconData icon;
  final String title;
  final String description;
  final String action;
  final Color actionColor;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).pushNamed(routeName),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140A2540),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -12,
                right: -12,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F6FA),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: actionColor, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111317),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D3542),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        action,
                        style: TextStyle(
                          color: actionColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: actionColor, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
