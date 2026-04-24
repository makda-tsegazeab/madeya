import 'package:flutter/material.dart';
import 'role_selection_page.dart';

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  static const String routeName = '/hero';
  static const Color _pageBg = Color(0xFFF2F4F7);
  static const Color _primaryBlue = Color(0xFF0E5AA7);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF344054);
  static const Color _divider = Color(0xFFD8DEE6);
  static const String _logoPath = 'assets/images/madeya_logo.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 680;
            final double horizontalPadding = isSmall ? 16 : 32;
            final double headingSize = isSmall ? 32 : 40;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          12,
                        ),
                        child: _buildTopBar(context, isSmall),
                      ),
                      const Divider(height: 1, color: _divider),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          16,
                        ),
                        child: _buildHeroBanner(isSmall),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: _buildMainCopy(
                          headingSize: headingSize,
                          small: isSmall,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          12,
                        ),
                        child: SizedBox(
                          height: isSmall ? 44 : 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                RoleSelectionPage.routeName,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Get Started  ->',
                              style: TextStyle(
                                fontSize: isSmall ? 15 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: _buildFeatureRow(isSmall),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: const Divider(height: 1, color: _divider),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          20,
                        ),
                        child: _buildFooter(isSmall),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool small) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                _logoPath,
                width: small ? 24 : 28,
                height: small ? 24 : 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Madeya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryBlue,
                    fontSize: small ? 20 : 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: small ? 38 : 42,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                RoleSelectionPage.routeName,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Get Started',
              style: TextStyle(
                fontSize: small ? 12 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(bool small) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(small ? 12 : 14),
      ),
      child: Container(
        height: small ? 110 : 160,
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FB),
          borderRadius: BorderRadius.circular(small ? 10 : 12),
        ),
        child: Center(
          child: Image.asset(
            _logoPath,
            height: small ? 90 : 130,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCopy({required double headingSize, required bool small}) {
    final TextStyle titleStyle = TextStyle(
      color: _textDark,
      fontSize: headingSize,
      fontWeight: FontWeight.w800,
      height: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Controlled Fuel', style: titleStyle),
        Text('Distribution', style: titleStyle.copyWith(color: _primaryBlue)),
        Text('for Mekelle', style: titleStyle.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: small ? 8 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Text(
            'The digital backbone for energy access.\n'
            'Manage your fuel quota, join virtual queues,\n'
            'and verify transactions with total transparency.',
            style: TextStyle(
              color: _textMuted,
              fontSize: small ? 14 : 16,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(bool small) {
    final TextStyle labelStyle = TextStyle(
      color: const Color(0xFF283043),
      fontSize: small ? 11 : 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );

    Widget item({required IconData icon, required String label}) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: _primaryBlue, size: small ? 24 : 28),
            SizedBox(height: small ? 6 : 8),
            Text(label, textAlign: TextAlign.center, style: labelStyle),
          ],
        ),
      );
    }

    Widget divider() {
      return Container(
        width: 1,
        height: small ? 50 : 70,
        color: _divider,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 12 : 16),
      child: Row(
        children: [
          item(icon: Icons.shield_rounded, label: 'SECURE QUOTA'),
          divider(),
          item(icon: Icons.query_stats_rounded, label: 'REAL-TIME DATA'),
          divider(),
          item(icon: Icons.verified_user_rounded, label: 'VERIFIED ACCESS'),
        ],
      ),
    );
  }

  Widget _buildFooter(bool small) {
    final double titleSize = small ? 16 : 24;
    final double bodySize = small ? 10 : 12;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              _logoPath,
              width: small ? 18 : 24,
              height: small ? 18 : 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Madeya Fuel Tracker',
              style: TextStyle(
                color: _primaryBlue,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 MADEYA. ALL RIGHTS RESERVED.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textDark,
            fontSize: bodySize,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
