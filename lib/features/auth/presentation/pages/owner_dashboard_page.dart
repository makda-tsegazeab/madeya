import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/token_storage.dart';
import '../../../vehicles/data/vehicle_model.dart';
import '../../../vehicles/data/vehicle_service.dart';
import '../../../stations/presentation/pages/stations_page.dart';

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

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final VehicleService _vehicleService = VehicleService();

  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  int get _registeredVehiclesCount => _vehicles.length;
  int get _activeQuotasCount =>
      _vehicles.where((v) => (v.remainingLiters ?? 0) > 0).length;
  double get _totalRemainingQuota =>
      _vehicles.fold(0, (sum, v) => sum + (v.remainingLiters ?? 0));
  double get _totalQuotaLimit =>
      _vehicles.fold(0, (sum, v) => sum + (v.litersLimit ?? 0));
  bool get _isEligibleToJoin =>
      _vehicles.any((v) => (v.remainingLiters ?? 0) > 0);

  @override
  void initState() {
    super.initState();
    _loadVehiclesAndQuota();
  }

  Future<void> _loadVehiclesAndQuota() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final vehicles = await _vehicleService.getVehiclesWithQuota(token);

      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadVehiclesAndQuota();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.profile.firstName} ${widget.profile.lastName}'.trim();
    final roleText = widget.profile.role.replaceAll('_', ' ');
    final statusText = widget.profile.isActive ? 'Verified Identity' : 'Account Inactive';
    final statusColor = widget.profile.isActive ? const Color(0xFF17B26A) : const Color(0xFFD92D20);

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(fullName),
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
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load vehicles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
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

    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(Icons.directions_car, size: 48, color: Color(0xFF98A2B3)),
            SizedBox(height: 12),
            Text(
              'No vehicles registered',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact admin to register vehicles',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _vehicles.asMap().entries.map((entry) {
        final index = entry.key;
        final vehicle = entry.value;
        return Column(
          children: [
            _vehicleCard(
              title: '${vehicle.vehicleTitle.toUpperCase()} • ${_getYearFromDate(vehicle.createdAt)}',
              number: vehicle.plateNumber,
              badge: vehicle.period?.toUpperCase() ?? 'DAILY',
              fuelType: vehicle.fuelType,
              status: vehicle.statusText,
              statusColor: vehicle.statusColor,
              remaining: '${vehicle.remainingLiters?.toStringAsFixed(1) ?? '0'}L',
              total: '${vehicle.litersLimit?.toStringAsFixed(1) ?? '0'}L',
              progress: vehicle.progressValue,
              progressColor: vehicle.progressColor,
            ),
            if (index < _vehicles.length - 1) const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getYearFromDate(DateTime date) {
    return date.year.toString();
  }

  Widget _topBar(String fullName) {
    final initials = (widget.profile.firstName.isNotEmpty ? widget.profile.firstName[0] : '') +
        (widget.profile.lastName.isNotEmpty ? widget.profile.lastName[0] : '');
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, color: _blue, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Madeya',
            style: TextStyle(color: _blue, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const Icon(Icons.notifications, size: 17, color: Color(0xFF2E4156)),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'change_password') {
                Navigator.pushNamed(context, '/change-password');
              } else if (value == 'logout') {
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
                            Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
                          }
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: _blue, size: 20),
                    SizedBox(width: 10),
                    Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFD92D20), size: 20),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Color(0xFFD92D20), fontWeight: FontWeight.w600, fontSize: 14)),
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
                  initials.isEmpty ? 'U' : initials.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String statusText, Color statusColor, String roleText) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFD),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
                style: TextStyle(color: Color(0xFF1D4268), letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE8F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.profile.isActive ? Icons.verified : Icons.info_outline,
                  color: _blue,
                  size: 22,
                ),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Role: $roleText',
            style: const TextStyle(fontSize: 12, color: Color(0xFF4C6076), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Registered\nVehicles', '$_registeredVehiclesCount'.padLeft(2, '0'))),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Active\nQuotas', '$_activeQuotasCount'.padLeft(2, '0'))),
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
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF4C6076), fontWeight: FontWeight.w500, height: 1.2),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 20, height: 1, color: _blue, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _quotaCard() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFDFF5EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBAEAD4), width: 1),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAEAD4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7EEDF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF0E9F6E), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quota Alert',
                style: TextStyle(color: Color(0xFF083225), fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quota liters: ${_totalRemainingQuota.toStringAsFixed(0)}/${_totalQuotaLimit.toStringAsFixed(0)}L\nQueue readiness: ${_isEligibleToJoin ? "Ready to join" : "No quota remaining"}\nStation summary: ${_vehicles.length} vehicle${_vehicles.length != 1 ? 's' : ''} registered',
            style: const TextStyle(color: Color(0xFF17624D), fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'ELIGIBILITY STATUS',
                style: TextStyle(color: Color(0xFF0E9165), letterSpacing: 1.2, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: _isEligibleToJoin ? const Color(0xFF0E9F6E) : const Color(0xFF98A2B3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isEligibleToJoin ? 'ELIGIBLE' : 'NOT ELIGIBLE',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _joinQueueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isEligibleToJoin && !_isLoading
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Queue feature coming soon!')),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: const Color(0xFF98A2B3),
        ),
        icon: const Icon(Icons.groups_2_rounded, size: 18),
        label: const Text('Join Queue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _vehiclesHeader() {
    return const Row(
      children: [
        Text(
          'Registered Vehicles',
          style: TextStyle(color: _blue, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        Spacer(),
        Text(
          'View All ->',
          style: TextStyle(color: Color(0xFF123A70), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _vehicleCard({
    required String title,
    required String number,
    required String badge,
    required String fuelType,
    required String status,
    required Color statusColor,
    required String remaining,
    required String total,
    required double progress,
    required Color progressColor,
  }) {
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
              Text(
                title,
                style: const TextStyle(color: Color(0xFF44586F), fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBDD3F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Color(0xFF3E5A84), fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1.0, color: Color(0xFF11151C), letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.local_gas_station, size: 17),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FUEL TYPE',
                          style: TextStyle(color: Color(0xFF5D7189), fontSize: 9.5, letterSpacing: 0.8, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          fuelType,
                          style: const TextStyle(color: Color(0xFF151E29), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 16),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUS',
                          style: TextStyle(color: Color(0xFF5D7189), fontSize: 9.5, letterSpacing: 0.8, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Text(
                'Remaining Quota',
                style: TextStyle(color: Color(0xFF1F2A37), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$remaining / $total',
                style: TextStyle(color: progressColor, fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFD9DDE3),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Period: $badge',
            style: const TextStyle(color: Color(0xFF5D7189), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: Color(0xFF8E4A14), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_rounded, size: 17, color: Color(0xFF7B3F15)),
              SizedBox(width: 8),
              Text(
                'GOVERNMENT NOTICE',
                style: TextStyle(color: Color(0xFF11151C), fontSize: 13, letterSpacing: 1.1, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Starting Monday, fuel distribution at major stations in Addis Ababa will follow the new quota schedule. Please ensure your digital ID is updated in the profile section.',
            style: TextStyle(color: Color(0xFF2E3644), fontSize: 11.5, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Read More', style: TextStyle(color: Color(0xFF11151C), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              const Text('Dismiss', style: TextStyle(color: Color(0xFF0D3B74), fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    Widget item({required IconData icon, required String label, bool active = false, VoidCallback? onTap}) {
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
                child: Icon(icon, size: 22, color: active ? _blue : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10.5, letterSpacing: 1.2, color: active ? _blue : const Color(0xFF8F9DB1), fontWeight: FontWeight.w700),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StationsPage()),
              );
            },
          ),
          item(icon: Icons.groups_rounded, label: 'QUEUE'),
          item(icon: Icons.history_rounded, label: 'HISTORY'),
        ],
      ),
    );
  }
}
