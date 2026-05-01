import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../data/auth_service.dart';
import '../../data/token_storage.dart';
// // import 'change_password_page.dart'; // Not needed - using named routes

class StationWorkerDashboardPage extends StatefulWidget {
  const StationWorkerDashboardPage({super.key, required this.profile});

  static const String routeName = '/station-worker-dashboard';

  final AuthUserProfile profile;

  @override
  State<StationWorkerDashboardPage> createState() =>
      _StationWorkerDashboardPageState();
}

class _StationWorkerDashboardPageState
    extends State<StationWorkerDashboardPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);

  final TokenStorage _tokenStorage = SecureTokenStorage();

  Map<String, dynamic>? _stationData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStationInfo();
  }

  Future<void> _loadStationInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      if (widget.profile.stationId == null) {
        setState(() {
          _errorMessage = 'No station assigned to this worker.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/station-manager/stations/${widget.profile.stationId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _stationData = jsonData['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load station info');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _tokenStorage.clearAccessToken();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.profile.firstName} ${widget.profile.lastName}'
        .trim();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(fullName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStationInfo,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    _buildGreeting(fullName),
                    const SizedBox(height: 14),
                    _buildStationCard(),
                    const SizedBox(height: 14),
                    _buildComingSoonCard(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar(String fullName) {
    final initials =
        (widget.profile.firstName.isNotEmpty
            ? widget.profile.firstName[0]
            : '') +
        (widget.profile.lastName.isNotEmpty ? widget.profile.lastName[0] : '');
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, color: Color(0xFF0B4D8B), size: 20),
          const SizedBox(width: 10),
          const Text(
            'Mekelle Fuel Tracker',
            style: TextStyle(
              color: Color(0xFF0B4D8B),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'change_password') {
                Navigator.pushNamed(context, '/change-password');
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Color(0xFF0B4D8B),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFD92D20), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFD92D20),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF77AEE9), width: 1.3),
                color: const Color(0xFF0F1621),
              ),
              child: Center(
                child: Text(
                  initials.isEmpty ? 'W' : initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String fullName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning,',
          style: TextStyle(
            color: Color(0xFF304B66),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hello, $fullName',
          style: const TextStyle(
            color: Color(0xFF0B4D8B),
            fontSize: 32,
            height: 0.95,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Station Worker',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _stationData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load station info',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStationInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stationName = _stationData!['name'] ?? 'Unknown Station';
    final address = _stationData!['address'] ?? '';
    final city = _stationData!['city'] ?? '';
    final fuelStatus = _stationData!['fuelStatus'] ?? 'UNKNOWN';
    final remainingFuel = _stationData!['remainingFuel']?.toString() ?? '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2540),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EFF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  color: Color(0xFF0B4D8B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111317),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$address, $city',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Fuel Status', fuelStatus)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoItem('Remaining', '$remainingFuel L')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111317),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE4CD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: Color(0xFFC2410C),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'COMING SOON',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9A3412),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Station Worker features are coming soon.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF78350F),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'We\'re preparing queue management tools for you.',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          _navItem(
            icon: Icons.home_filled,
            label: 'HOME',
            active: true,
            onTap: () {},
          ),
          _navItem(
            icon: Icons.local_gas_station_rounded,
            label: 'STATIONS',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Station features coming soon!')),
              );
            },
          ),
          _navItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'QUEUE',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Queue management coming soon!')),
              );
            },
          ),
          _navItem(
            icon: Icons.history_rounded,
            label: 'HISTORY',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 40,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFD9E5F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? _blue : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.2,
                color: active ? _blue : const Color(0xFF8F9DB1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
