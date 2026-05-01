import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/token_storage.dart';
import '../../data/queue_models.dart';
import '../../data/queue_service.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  static const String routeName = '/queue';

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage>
    with WidgetsBindingObserver {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);
  static const Duration _pollInterval = Duration(seconds: 10);

  final QueueService _queueService = QueueService();
  final TokenStorage _tokenStorage = SecureTokenStorage();

  Timer? _pollTimer;
  List<ActiveBooking> _bookings = [];
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(initial: true);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  Future<void> _refresh({bool initial = false}) async {
    if (!mounted) return;
    if (initial) {
      setState(() => _isInitialLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }
      final bookings = await _queueService.getActiveBookings(token);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _errorMessage = null;
        _isInitialLoading = false;
        _isRefreshing = false;
        _lastUpdatedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isInitialLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'My Queue',
          style: TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh now',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: _blue),
            onPressed: _isRefreshing ? null : () => _refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _bookings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Could not load queue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => _refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_bookings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.inbox_rounded, size: 56, color: Color(0xFF98A2B3)),
          SizedBox(height: 12),
          Text(
            'No active queue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            "You're not currently in any station queue.\nPick a station and pay to join.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _grey, height: 1.4),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _bookings.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == _bookings.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            child: Center(
              child: Text(
                _lastUpdatedAt != null
                    ? 'Updated ${_formatTime(_lastUpdatedAt!)} • auto-refresh every 10s'
                    : 'Auto-refresh every 10s',
                style: const TextStyle(fontSize: 11, color: _grey),
              ),
            ),
          );
        }
        return _bookingCard(_bookings[index]);
      },
    );
  }

  Widget _bookingCard(ActiveBooking booking) {
    final stationName =
        booking.station?.name ?? 'Station #${booking.stationId}';
    final fuelType = booking.payment?.fuelType ?? '';
    final liters = booking.payment?.litersRequested ?? '0';
    final amount = booking.payment?.amount ?? '0';
    final currency = booking.payment?.currency ?? 'ETB';
    final plate = booking.vehicle?.plateNumber ?? '';
    final position = booking.queuePosition;
    final ahead = booking.positionAhead;

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stationName,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.status,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Booked ${_formatDateTime(booking.bookedAt)}',
            style: const TextStyle(fontSize: 11.5, color: _grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'YOUR POSITION',
                  value: '#$position',
                  hint: ahead == 0 ? 'You are next' : '$ahead ahead',
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox(
                  label: 'CARS AHEAD',
                  value: ahead.toString(),
                  hint: 'In line',
                  color: const Color(0xFF0E9F6E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Vehicle', plate.isEmpty ? '—' : plate),
                const SizedBox(height: 6),
                _detailRow('Fuel type', fuelType.isEmpty ? '—' : fuelType),
                const SizedBox(height: 6),
                _detailRow('Liters', '$liters L'),
                const SizedBox(height: 6),
                _detailRow('Paid', '$amount $currency'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _verifyTokenBox(booking.verifyToken),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required String hint,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(fontSize: 10.5, color: _grey)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            color: _dark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _verifyTokenBox(String token) {
    final shortened = token.length > 12
        ? '${token.substring(0, 6)}…${token.substring(token.length - 6)}'
        : token;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1621),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'SHOW TO STATION WORKER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            shortened,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'The worker scans this token to verify and complete your transaction.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy verify token',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: token));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verify token copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
