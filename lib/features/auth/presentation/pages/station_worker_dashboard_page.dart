import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../data/auth_service.dart';
import '../../data/token_storage.dart';
import '../../../queue/data/worker_queue_service.dart';
import '../../../queue/presentation/pages/worker_qr_scanner_page.dart';
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
  final WorkerQueueService _workerQueueService = WorkerQueueService();
  final TextEditingController _verifyTokenController = TextEditingController();
  final TextEditingController _receiptRefController = TextEditingController();

  Map<String, dynamic>? _stationData;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isVerifying = false;
  Map<String, dynamic>? _verifiedPayload;
  String? _verifyError;

  bool _isCompleting = false;
  Map<String, dynamic>? _completePayload;
  String? _completeError;

  @override
  void initState() {
    super.initState();
    _loadStationInfo();
  }

  @override
  void dispose() {
    _verifyTokenController.dispose();
    _receiptRefController.dispose();
    super.dispose();
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

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/queue/worker/station'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final payload = _tryDecodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (payload is! Map<String, dynamic> || payload['success'] != true) {
          throw Exception(_extractMessage(payload) ?? 'Failed to load station info');
        }

        setState(() {
          _stationData = payload['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        final message =
            _extractMessage(payload) ?? 'Failed to load station info (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Object? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _extractMessage(Object? payload) {
    if (payload is! Map<String, dynamic>) return null;
    final m = payload['message'];
    if (m is String && m.trim().isNotEmpty) return m;
    return null;
  }

  Future<void> _scanQr() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final code = await nav.push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const WorkerQrScannerPage(),
      ),
    );
    if (!mounted) return;
    if (code == null || code.trim().isEmpty) return;
    setState(() {
      _verifyTokenController.text = code.trim();
      _verifyError = null;
      _verifiedPayload = null;
    });
  }

  Future<void> _verifyToken() async {
    final verifyToken = _verifyTokenController.text.trim();
    if (verifyToken.length < 16) {
      setState(() {
        _verifyError = 'Please enter a valid token.';
        _verifiedPayload = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifyError = null;
      _verifiedPayload = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }

      final data = await _workerQueueService.verifyBooking(
        accessToken: token,
        verifyToken: verifyToken,
      );
      if (!mounted) return;
      setState(() {
        _verifiedPayload = data;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyError = e.toString();
        _isVerifying = false;
      });
    }
  }

  Future<void> _completeBooking() async {
    final verifyToken = _verifyTokenController.text.trim();
    if (verifyToken.length < 16) {
      setState(() {
        _completeError = 'Please enter a valid token.';
      });
      return;
    }

    setState(() {
      _isCompleting = true;
      _completeError = null;
      _completePayload = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }

      final data = await _workerQueueService.completeBooking(
        accessToken: token,
        verifyToken: verifyToken,
        receiptRef: _receiptRefController.text,
      );

      if (!mounted) return;
      setState(() {
        _completePayload = data;
        _isCompleting = false;
      });

      // Refresh details so UI reflects SERVED state.
      await _verifyToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking completed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _completeError = e.toString();
        _isCompleting = false;
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
                    _buildVerifySection(),
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

  Widget _buildVerifySection() {
    final hasVerified = _verifiedPayload != null;

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
          const Text(
            'Verify Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111317),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan the customer QR or paste the verify token.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verifyTokenController,
            decoration: InputDecoration(
              hintText: 'Verify token',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyToken(),
          ),
          if (_verifyError != null) ...[
            const SizedBox(height: 10),
            Text(
              _verifyError!,
              style: const TextStyle(
                color: Color(0xFFD92D20),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isVerifying ? null : _scanQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: BorderSide(color: _blue.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyToken,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasVerified) ...[
            const SizedBox(height: 14),
            _buildVerifiedDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedDetails() {
    final payload = _verifiedPayload ?? const <String, dynamic>{};
    final booking = payload['booking'] as Map<String, dynamic>? ?? {};
    final vehicle = payload['vehicle'] as Map<String, dynamic>? ?? {};
    final owner = payload['owner'] as Map<String, dynamic>? ?? {};
    final payment = payload['payment'] as Map<String, dynamic>? ?? {};
    final txn = payload['transaction'] as Map<String, dynamic>?;
    final canComplete = txn == null;

    final ownerName =
        '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim();
    final plate = (vehicle['plateNumber'] ?? '').toString();
    final fuelType = (payment['fuelType'] ?? '').toString();
    final liters = (payment['litersRequested'] ?? '').toString();
    final amount = (payment['amount'] ?? '').toString();
    final currency = (payment['currency'] ?? 'ETB').toString();
    final status = (booking['status'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: _blue, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Booking details',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111317),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.isEmpty ? '—' : status,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Plate', plate.isEmpty ? '—' : plate),
          const SizedBox(height: 6),
          _kv('Owner', ownerName.isEmpty ? '—' : ownerName),
          const SizedBox(height: 6),
          _kv('Fuel', fuelType.isEmpty ? '—' : fuelType),
          const SizedBox(height: 6),
          _kv('Liters', liters.isEmpty ? '—' : '$liters L'),
          const SizedBox(height: 6),
          _kv('Paid', amount.isEmpty ? '—' : '$amount $currency'),
          if (!canComplete) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _kv('Already served', 'Yes (txn #${txn['id'] ?? ''})'),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            TextField(
              controller: _receiptRefController,
              decoration: InputDecoration(
                hintText: 'Receipt ref (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_completeError != null) ...[
              const SizedBox(height: 10),
              Text(
                _completeError!,
                style: const TextStyle(
                  color: Color(0xFFD92D20),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCompleting ? null : _completeBooking,
                icon: _isCompleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isCompleting ? 'Completing...' : 'Complete Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E9F6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_completePayload != null) ...[
              const SizedBox(height: 10),
              Text(
                (_completePayload?['created'] == true)
                    ? 'Transaction created (#${_completePayload?['transactionId'] ?? ''})'
                    : 'Transaction already exists (#${_completePayload?['transactionId'] ?? ''})',
                style: const TextStyle(
                  color: Color(0xFF0B4D8B),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF111317),
            fontWeight: FontWeight.w800,
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

    final stationName = (_stationData!['name'] ?? 'Assigned station').toString();
    final phone = _stationData!['phone']?.toString();
    final isActive = _stationData!['isActive'] == true;
    final queueIntakePaused = _stationData!['queueIntakePaused'] == true;
    final latitude = _stationData!['latitude']?.toString();
    final longitude = _stationData!['longitude']?.toString();

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
                      [
                        if (phone != null && phone.trim().isNotEmpty) phone.trim(),
                        if (latitude != null &&
                            longitude != null &&
                            latitude.trim().isNotEmpty &&
                            longitude.trim().isNotEmpty)
                          '${latitude.trim()}, ${longitude.trim()}',
                      ].join(' • '),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
              _statusChip(
                label: isActive ? 'OPEN' : 'CLOSED',
                bg: isActive ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2),
                fg: isActive ? const Color(0xFF1E40AF) : const Color(0xFF991B1B),
                icon: isActive ? Icons.check_circle_outline : Icons.block,
              ),
              const SizedBox(width: 8),
              _statusChip(
                label: queueIntakePaused ? 'INTAKE PAUSED' : 'INTAKE ACTIVE',
                bg: queueIntakePaused
                    ? const Color(0xFFFFEDD5)
                    : const Color(0xFFDCFCE7),
                fg: queueIntakePaused
                    ? const Color(0xFF9A3412)
                    : const Color(0xFF166534),
                icon: queueIntakePaused
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
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
