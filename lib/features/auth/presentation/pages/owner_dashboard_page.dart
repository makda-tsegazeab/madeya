import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/auth_service.dart';
import '../../data/token_storage.dart';
import '../../../announcements/data/announcement_model.dart';
import '../../../announcements/data/announcement_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../queue/presentation/pages/queue_status_page.dart';
import '../../../stations/presentation/pages/stations_page.dart';
import '../../../transactions/presentation/pages/history_page.dart';
import '../../../vehicles/data/vehicle_model.dart';
import '../../../vehicles/data/vehicle_service.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key, required this.profile});

  static const String routeName = '/owner-dashboard';

  final AuthUserProfile profile;

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final VehicleService _vehicleService = VehicleService();
  final AnnouncementService _announcementService = AnnouncementService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Vehicle> _vehicles = [];
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadNotifications = 0;

  int get _registeredVehiclesCount => _vehicles.length;
  int get _activeQuotasCount =>
      _vehicles.where((v) => (v.remainingLiters ?? 0) > 0).length;
  double get _totalRemainingQuota =>
      _vehicles.fold(0, (sum, v) => sum + (v.remainingLiters ?? 0));
  double get _totalQuotaLimit =>
      _vehicles.fold(0, (sum, v) => sum + (v.litersLimit ?? 0));
  bool get _isEligibleToJoin =>
      _vehicles.any((v) => (v.remainingLiters ?? 0) > 0);

  Announcement? get _latestAnnouncement {
    if (_announcements.isEmpty) return null;
    final list = [..._announcements];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Load data with graceful error handling
      final vehicles = await _vehicleService.getVehiclesWithQuota(token);
      final announcements = await _announcementService.getAnnouncements(token);
      final lastReadStr = await _storage.read(
        key: 'last_read_announcement_time',
      );
      final lastReadTime = lastReadStr != null
          ? DateTime.tryParse(lastReadStr)
          : null;
      final unread = lastReadTime == null
          ? announcements.length
          : announcements
                .where((a) => a.createdAt.isAfter(lastReadTime))
                .length;

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _announcements = announcements;
        _unreadNotifications = unread;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load data. Please check your internet connection and try again.\n\nIf the problem persists, the server may be temporarily unavailable.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.profile.firstName} ${widget.profile.lastName}'
        .trim();
    final roleText = widget.profile.role.replaceAll('_', ' ');
    final statusText = widget.profile.isActive
        ? 'Verified Identity'
        : 'Account Inactive';
    final statusColor = widget.profile.isActive
        ? const Color(0xFF17B26A)
        : const Color(0xFFD92D20);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(),
                      const SizedBox(height: 10),
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
                          color: _blue,
                          fontSize: 32,
                          height: 0.95,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _summaryCard(statusText, statusColor, roleText),
                      const SizedBox(height: 14),
                      _quotaCard(),
                      const SizedBox(height: 14),
                      _joinQueueButton(),
                      const SizedBox(height: 14),
                      _vehiclesHeader(),
                      const SizedBox(height: 10),
                      _buildVehiclesList(),
                      const SizedBox(height: 12),
                      _noticeCard(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final initials =
        (widget.profile.firstName.isNotEmpty
            ? widget.profile.firstName[0]
            : '') +
        (widget.profile.lastName.isNotEmpty ? widget.profile.lastName[0] : '');

    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, color: _blue, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Mekelle Fuel Tracker',
            style: TextStyle(
              color: _blue,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/announcements');
              _refreshData();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications,
                  size: 22,
                  color: Color(0xFF2E4156),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD92D20),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(profile: widget.profile),
                  ),
                );
              } else if (value == 'change_password') {
                Navigator.pushNamed(context, '/change-password');
              } else if (value == 'logout') {
                await _tokenStorage.clearAccessToken();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'profile', child: Text('My Account')),
              PopupMenuItem(
                value: 'change_password',
                child: Text('Change Password'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: Color(0xFFD92D20)),
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
                  initials.isEmpty ? 'U' : initials.toUpperCase(),
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

  Widget _summaryCard(String statusText, Color statusColor, String roleText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ACCOUNT SUMMARY',
                style: TextStyle(
                  color: Color(0xFF1D4268),
                  letterSpacing: 2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                widget.profile.isActive ? Icons.verified : Icons.info_outline,
                color: _blue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Role: $roleText',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Registered\nVehicles',
                  '$_registeredVehiclesCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat('Active\nQuotas', '$_activeQuotasCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: _blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quotaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAEAD4), width: 1),
      ),
      child: Text(
        'Quota liters: ${_totalRemainingQuota.toStringAsFixed(2)}/${_totalQuotaLimit.toStringAsFixed(2)} L\nQueue readiness: ${_isEligibleToJoin ? "Ready to join" : "No quota remaining"}',
        style: const TextStyle(
          color: Color(0xFF17624D),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _joinQueueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StationsPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.groups_2_rounded, size: 18),
        label: const Text(
          'Join Queue',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _vehiclesHeader() => const Text(
    'Registered Vehicles',
    style: TextStyle(color: _blue, fontSize: 21, fontWeight: FontWeight.w800),
  );

  Widget _buildVehiclesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(color: Color(0xFFD92D20)),
      );
    }
    if (_vehicles.isEmpty) {
      return const Text(
        'No vehicles registered',
        style: TextStyle(color: _grey),
      );
    }
    return Column(
      children: _vehicles.map((v) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.plateNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(v.displayTitle, style: const TextStyle(color: _grey)),
              const SizedBox(height: 8),
              Text(
                'Remaining ${v.remainingLiters?.toStringAsFixed(2) ?? '—'} / ${v.litersLimit?.toStringAsFixed(2) ?? '—'} L',
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: v.progressValue,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(v.progressColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _noticeCard() {
    final latest = _latestAnnouncement;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          left: BorderSide(color: Color(0xFF8E4A14), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_rounded, size: 17, color: Color(0xFF7B3F15)),
              SizedBox(width: 8),
              Text(
                'LATEST ANNOUNCEMENT',
                style: TextStyle(
                  color: _dark,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            latest?.title ?? 'No announcement available',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            latest?.body ?? 'Announcements from admins will appear here.',
            style: const TextStyle(
              color: Color(0xFF2E3644),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    Widget item({
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

    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          item(icon: Icons.home_filled, label: 'HOME', active: true),
          item(
            icon: Icons.local_gas_station_rounded,
            label: 'STATIONS',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StationsPage()),
            ),
          ),
          item(
            icon: Icons.groups_rounded,
            label: 'QUEUE',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QueueStatusPage()),
            ),
          ),
          item(
            icon: Icons.history_rounded,
            label: 'HISTORY',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
        ],
      ),
    );
  }
}
