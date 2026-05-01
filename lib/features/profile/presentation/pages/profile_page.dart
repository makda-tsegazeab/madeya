import 'package:flutter/material.dart';

import '../../../auth/data/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.profile});

  static const String routeName = '/profile';

  final AuthUserProfile profile;

  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final fullName = '${profile.firstName} ${profile.lastName}'.trim();
    final initials =
        ((profile.firstName.isNotEmpty ? profile.firstName[0] : '') +
                (profile.lastName.isNotEmpty ? profile.lastName[0] : ''))
            .toUpperCase();
    final roleText = profile.role.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Account',
          style: TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileHeader(initials, fullName, roleText),
            const SizedBox(height: 16),
            _infoCard(
              children: [
                _infoRow(
                  icon: Icons.alternate_email,
                  label: 'Email',
                  value: profile.email,
                ),
                _infoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: roleText,
                ),
                _infoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Status',
                  value: profile.isActive ? 'Active' : 'Inactive',
                  valueColor: profile.isActive
                      ? const Color(0xFF17B26A)
                      : const Color(0xFFD92D20),
                ),
                _infoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member since',
                  value: _formatDate(profile.createdAt),
                ),
                _infoRow(
                  icon: Icons.update,
                  label: 'Last updated',
                  value: _formatDate(profile.updatedAt),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _blue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Profile editing is managed by the government administrator. To change your account information, please contact your admin.',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(String initials, String fullName, String roleText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0F1621),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Vehicle Owner' : fullName,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleText,
                  style: const TextStyle(
                    color: _grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _blue, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? _dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 44),
              child: Divider(height: 1),
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
