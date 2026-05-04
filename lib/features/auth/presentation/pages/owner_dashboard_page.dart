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
import '../../../vehicles/presentation/pages/vehicle_detail_page.dart';

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

  double get _totalRemainingQuota =>
      _vehicles.fold(0, (sum, v) => sum + (v.remainingLiters ?? 0));
  double get _totalQuotaLimit =>
      _vehicles.fold(0, (sum, v) => sum + (v.litersLimit ?? 0));
  bool get _isEligibleToJoin =>
      _vehicles.any((v) => (v.remainingLiters ?? 0) > 0);

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
                      _buildVehiclesList(),
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

  String _allowanceRemainingFooter(Vehicle v) {
    final rem = v.remainingLiters;
    final lim = v.litersLimit;
    if (rem == null || lim == null || lim <= 0) {
      return 'Allowance data unavailable';
    }
    final pct = ((rem / lim) * 100).clamp(0.0, 100.0).round();
    return '$pct% of your current allowance remaining';
  }

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
      children: _vehicles.map(_vehicleCard).toList(),
    );
  }

  Widget _vehicleCard(Vehicle v) {
    final accent = v.progressColor;

    void openDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleDetailPage(
            vehicleId: v.id,
            previewPlate: v.plateNumber,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_taxi_rounded,
                            color: _blue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.plateNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: _dark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.displayTitle,
                                style: const TextStyle(
                                  color: _grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: openDetails,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: Icon(
                            Icons.info_outline_rounded,
                            color: _grey.withOpacity(0.85),
                            size: 22,
                          ),
                          tooltip: 'Vehicle details',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: v.statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: v.statusColor),
                          const SizedBox(width: 6),
                          Text(
                            v.statusText,
                            style: TextStyle(
                              color: v.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fuel allowance',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 15,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: v.remainingLiters?.toStringAsFixed(2) ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text:
                                ' / ${v.litersLimit?.toStringAsFixed(2) ?? '—'} L',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quota period: ${v.period ?? '—'}',
                      style: const TextStyle(
                        color: _grey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: v.progressValue,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _allowanceRemainingFooter(v),
                      style: TextStyle(
                        color: _grey.withOpacity(0.95),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: openDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: const BorderSide(
                            color: Color(0xFF77AEE9),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
