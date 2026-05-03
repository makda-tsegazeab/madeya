import 'package:flutter/material.dart';

import '../../../auth/data/token_storage.dart';
import '../../data/vehicle_model.dart';
import '../../data/vehicle_service.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({
    super.key,
    required this.vehicleId,
    this.previewPlate,
  });

  final int vehicleId;
  final String? previewPlate;

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);

  static const List<String> _periodOrder = ['DAILY', 'WEEKLY', 'MONTHLY'];

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final VehicleService _vehicleService = VehicleService();

  Vehicle? _vehicle;
  QuotaResponse? _quota;
  String? _quotaError;
  bool _loading = true;
  String? _vehicleError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _vehicleError = null;
      _quotaError = null;
    });
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please sign in again.');
      }

      final vehicle = await _vehicleService.getVehicle(widget.vehicleId, token);

      QuotaResponse? quota;
      String? quotaErr;
      try {
        quota = await _vehicleService.getVehicleQuota(widget.vehicleId, token);
      } catch (e) {
        quotaErr = e.toString().replaceFirst('Exception: ', '');
      }

      if (!mounted) return;
      setState(() {
        _vehicle = vehicle;
        _quota = quota;
        _quotaError = quotaErr;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehicleError = e.toString().replaceFirst('Exception: ', '');
        _vehicle = null;
        _quota = null;
        _loading = false;
      });
    }
  }

  int _periodRank(String period) {
    final i = _periodOrder.indexOf(period.toUpperCase());
    return i < 0 ? 99 : i;
  }

  String _periodTitle(String period) {
    switch (period.toUpperCase()) {
      case 'DAILY':
        return 'Daily limit';
      case 'WEEKLY':
        return 'Weekly limit';
      case 'MONTHLY':
        return 'Monthly limit';
      default:
        return period;
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final title = _vehicle?.plateNumber ?? widget.previewPlate ?? 'Vehicle';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _blue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _vehicleError != null
            ? _errorBody(_vehicleError!)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_vehicle != null) _vehicleCard(_vehicle!),
                    const SizedBox(height: 14),
                    _quotaSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorBody(String message) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.error_outline, size: 48, color: Color(0xFFD92D20)),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _vehicleCard(Vehicle v) {
    final cat = v.category;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE',
            style: TextStyle(
              color: _grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            v.plateNumber,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(v.displayTitle, style: const TextStyle(color: _grey, fontSize: 15)),
          if (cat != null) ...[
            const SizedBox(height: 10),
            Text(
              'Category: ${cat.name}',
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w600),
            ),
            Text(
              'Subsidy: ${cat.fuelSubsidyPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(color: _grey, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: v.statusColor),
              const SizedBox(width: 6),
              Text(
                v.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: v.isActive ? const Color(0xFF17B26A) : _grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Registered: ${_formatDate(v.createdAt)} · Updated: ${_formatDate(v.updatedAt)}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ],
      ),
    );
  }

  Widget _quotaSection() {
    final v = _vehicle;
    if (v != null && !v.isActive) {
      return _infoPill(
        'Quota is not available while this vehicle is inactive.',
      );
    }

    if (_quotaError != null) {
      return _infoPill(
        'Could not load quota. ${_quotaError!.replaceFirst('Exception: ', '')}',
      );
    }

    final quota = _quota;
    if (quota == null) {
      return _infoPill('No quota data.');
    }

    final periods = [...quota.periods]
      ..sort((a, b) => _periodRank(a.period).compareTo(_periodRank(b.period)));

    if (periods.isEmpty) {
      return _infoPill(
        'No active quota periods for this vehicle. An administrator can configure quota rules.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FUEL QUOTA',
          style: TextStyle(
            color: _blue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        ...periods.map(_periodTile),
      ],
    );
  }

  Widget _infoPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _dark, fontSize: 13, height: 1.45),
      ),
    );
  }

  Widget _periodTile(QuotaPeriod p) {
    final limit = p.litersLimit;
    final remaining = p.remainingLiters;
    final progress = limit > 0 ? (remaining / limit).clamp(0.0, 1.0) : 0.0;
    final barColor = remaining <= 0
        ? const Color(0xFF98A2B3)
        : remaining <= 5
        ? const Color(0xFFD92D20)
        : remaining <= 10
        ? const Color(0xFFE67E22)
        : _blue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodTitle(p.period),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${remaining.toStringAsFixed(2)} / ${limit.toStringAsFixed(2)} L remaining',
            style: const TextStyle(
              color: _grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
