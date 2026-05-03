import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/token_storage.dart';
import '../../../stations/data/station_model.dart';
import '../../../vehicles/data/vehicle_model.dart';
import '../../../vehicles/data/vehicle_service.dart';
import '../../data/payment_service.dart';
import '../../data/queue_models.dart';
import 'chapa_checkout_page.dart';
import 'queue_status_page.dart';

class ConfigureBookingPage extends StatefulWidget {
  const ConfigureBookingPage({
    super.key,
    required this.station,
    this.initialVehicleId,
  });

  final Station station;
  /// When set (e.g. from owner home vehicle card), this vehicle is selected first.
  final int? initialVehicleId;

  @override
  State<ConfigureBookingPage> createState() => _ConfigureBookingPageState();
}

class _ConfigureBookingPageState extends State<ConfigureBookingPage> {
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _greyText = Color(0xFF6B7280);

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final VehicleService _vehicleService = VehicleService();
  final PaymentService _paymentService = PaymentService();

  final TextEditingController _litersController = TextEditingController(
    text: '10',
  );
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  String? _loadError;

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  QuotaResponse? _quota;
  bool _isLoadingQuota = false;
  String? _quotaError;

  List<FuelPrice> _fuelPrices = [];
  FuelPrice? _selectedFuelPrice;

  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }
      final results = await Future.wait([
        _vehicleService.getVehicles(token),
        _paymentService.listFuelPrices(token),
      ]);
      final vehicles = results[0] as List<Vehicle>;
      final prices = (results[1] as List<FuelPrice>)
          .where((p) => p.isActive)
          .toList();

      Vehicle? pickInitial() {
        final preId = widget.initialVehicleId;
        if (preId != null) {
          for (final v in vehicles) {
            if (v.id == preId && v.isActive) return v;
          }
        }
        for (final v in vehicles) {
          if (v.isActive) return v;
        }
        return vehicles.isNotEmpty ? vehicles.first : null;
      }

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _fuelPrices = prices;
        _selectedVehicle = pickInitial();
        _selectedFuelPrice = prices.isNotEmpty ? prices.first : null;
        _isLoading = false;
      });

      if (_selectedVehicle != null) {
        await _loadQuota(_selectedVehicle!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuota(Vehicle vehicle) async {
    setState(() {
      _isLoadingQuota = true;
      _quotaError = null;
      _quota = null;
    });
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }
      final quota = await _vehicleService.getVehicleQuota(vehicle.id, token);
      if (!mounted) return;
      setState(() {
        _quota = quota;
        _isLoadingQuota = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quotaError = e.toString();
        _isLoadingQuota = false;
      });
    }
  }

  double get _maxQuota => _quota?.remainingLiters ?? 0;
  double get _unitPrice => _selectedFuelPrice?.pricePerLiter ?? 0;
  double get _litersValue =>
      double.tryParse(_litersController.text.trim()) ?? 0.0;
  double get _grossAmount => _litersValue * _unitPrice;
  double get _subsidyPct =>
      _selectedVehicle?.category?.fuelSubsidyPercentage ?? 0.0;
  double get _subsidyAmount => _grossAmount * (_subsidyPct / 100.0);
  double get _amountDue => _grossAmount - _subsidyAmount;

  bool get _canSubmit =>
      !_isLoading &&
      !_isSubmitting &&
      _selectedVehicle != null &&
      _selectedFuelPrice != null &&
      _quota != null &&
      _litersValue > 0 &&
      _litersValue <= _maxQuota &&
      _phoneController.text.trim().length >= 9 &&
      widget.station.acceptsQueueJoins;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }
      final init = await _paymentService.initiatePayment(
        token: token,
        vehicleId: _selectedVehicle!.id,
        stationId: widget.station.id,
        fuelType: _selectedFuelPrice!.fuelType,
        litersRequested: _litersValue,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;
      final result = await Navigator.of(context).push<ChapaResult>(
        MaterialPageRoute(
          builder: (_) => ChapaCheckoutPage(
            checkoutUrl: init.checkoutUrl,
            txRef: init.txRef,
          ),
        ),
      );

      if (result == null || !result.completed) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _submissionError = result?.cancelledByUser == true
                ? 'Payment cancelled. You were not added to the queue.'
                : null;
          });
        }
        return;
      }

      // Verify and join.
      await _paymentService.verifyPayment(token: token, txRef: init.txRef);
      await _paymentService.joinQueue(token: token, paymentId: init.paymentId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have joined the queue')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QueueStatusPage()),
      );
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _submissionError = e.message;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submissionError = e.toString();
        _isSubmitting = false;
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
          'Configure Booking',
          style: TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _errorState(_loadError!, _loadInitial)
          : _vehicles.isEmpty
          ? _emptyVehiclesState()
          : _fuelPrices.isEmpty
          ? _noFuelPricesState()
          : _buildForm(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: const Color(0xFF9CA3AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pay & Join Queue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message, Future<void> Function() onRetry) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
        const SizedBox(height: 12),
        const Text(
          'Could not load booking info',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _greyText),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
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

  Widget _emptyVehiclesState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.directions_car, size: 56, color: Color(0xFF98A2B3)),
        SizedBox(height: 12),
        Text(
          'No vehicles registered',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Please contact the government administrator to add a vehicle to your account before booking.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: _greyText, height: 1.4),
        ),
      ],
    );
  }

  Widget _noFuelPricesState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.local_gas_station, size: 56, color: Color(0xFF98A2B3)),
        SizedBox(height: 12),
        Text(
          'No fuel prices available',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'The administrator has not configured fuel prices yet. Please try again later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: _greyText, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stationCard(),
            const SizedBox(height: 16),
            _label('Vehicle'),
            const SizedBox(height: 6),
            _vehicleDropdown(),
            const SizedBox(height: 12),
            _quotaSummary(),
            const SizedBox(height: 16),
            _label('Fuel Type'),
            const SizedBox(height: 6),
            _fuelDropdown(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Liters Requested'),
                Text(
                  'Max: ${_maxQuota.toStringAsFixed(2)} L',
                  style: const TextStyle(
                    color: _greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _litersField(),
            const SizedBox(height: 16),
            _label('Mobile number for Chapa'),
            const SizedBox(height: 6),
            _phoneField(),
            const SizedBox(height: 20),
            _summaryCard(),
            if (_submissionError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFB91C1C),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _submissionError!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: _dark,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _stationCard() {
    final intakeOk = widget.station.acceptsQueueJoins;
    final badgeText = !widget.station.isActive
        ? 'CLOSED'
        : widget.station.queueIntakePaused
        ? 'INTAKE PAUSED'
        : 'OPEN';
    final badgeColor = intakeOk
        ? const Color(0xFF1E40AF)
        : const Color(0xFF991B1B);
    final badgeBg = intakeOk
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'STATION',
                style: TextStyle(
                  color: _greyText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.station.name,
            style: const TextStyle(
              color: _blue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.queue, size: 14, color: _greyText),
              const SizedBox(width: 4),
              Text(
                '${widget.station.activeQueueLength} in line now',
                style: const TextStyle(fontSize: 12, color: _greyText),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.local_gas_station, size: 14, color: _greyText),
              const SizedBox(width: 4),
              Text(
                widget.station.fuelStatusLabel,
                style: const TextStyle(fontSize: 12, color: _greyText),
              ),
            ],
          ),
          if (!intakeOk) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'This station is not currently accepting new queue entries.',
                style: TextStyle(color: Color(0xFF991B1B), fontSize: 11.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vehicleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vehicle>(
          value: _selectedVehicle,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _greyText,
            size: 20,
          ),
          style: const TextStyle(
            color: _dark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: _vehicles
              .map(
                (v) => DropdownMenuItem<Vehicle>(
                  value: v,
                  child: Text(
                    '${v.plateNumber} • ${v.displayTitle}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() => _selectedVehicle = v);
                  _loadQuota(v);
                },
        ),
      ),
    );
  }

  Widget _quotaSummary() {
    if (_isLoadingQuota) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading quota...',
              style: TextStyle(fontSize: 12, color: _greyText),
            ),
          ],
        ),
      );
    }
    if (_quotaError != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _quotaError!,
          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11.5),
        ),
      );
    }
    final quota = _quota;
    if (quota == null) return const SizedBox.shrink();
    final periodNames = quota.periods.map((p) => p.period).join(' • ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF047857), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Remaining: ${quota.remainingLiters.toStringAsFixed(2)} L of ${quota.litersLimit.toStringAsFixed(2)} L${periodNames.isEmpty ? '' : ' ($periodNames)'}',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FuelPrice>(
          value: _selectedFuelPrice,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _greyText,
            size: 20,
          ),
          style: const TextStyle(
            color: _dark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: _fuelPrices
              .map(
                (p) => DropdownMenuItem<FuelPrice>(
                  value: p,
                  child: Text(
                    '${p.fuelType} (${p.pricePerLiter.toStringAsFixed(2)} ETB / L)',
                  ),
                ),
              )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (p) {
                  if (p == null) return;
                  setState(() => _selectedFuelPrice = p);
                },
        ),
      ),
    );
  }

  Widget _litersField() {
    return TextFormField(
      controller: _litersController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (_) => setState(() {}),
      validator: (raw) {
        final v = double.tryParse((raw ?? '').trim());
        if (v == null || v <= 0) return 'Enter a valid liters value';
        if (_quota != null && v > _maxQuota) {
          return 'Exceeds remaining quota (${_maxQuota.toStringAsFixed(2)} L)';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        suffixText: 'LTR',
        suffixStyle: const TextStyle(
          color: _blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: _dark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      onChanged: (_) => setState(() {}),
      validator: (raw) {
        final v = (raw ?? '').trim();
        if (v.length < 9) return 'Enter your mobile number';
        return null;
      },
      decoration: InputDecoration(
        hintText: '+251911234567',
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        prefixIcon: const Icon(Icons.phone, color: _greyText, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: _dark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _summaryCard() {
    final showSubsidy = _subsidyPct > 0 && _grossAmount > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT SUMMARY',
            style: TextStyle(
              color: _greyText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow('Liters', '${_litersValue.toStringAsFixed(2)} L'),
          _summaryRow('Unit price', '${_unitPrice.toStringAsFixed(2)} ETB / L'),
          if (showSubsidy)
            _summaryRow(
              'Gross amount',
              '${_grossAmount.toStringAsFixed(2)} ETB',
            ),
          if (showSubsidy)
            _summaryRow(
              'Subsidy (${_subsidyPct.toStringAsFixed(0)}%)',
              '- ${_subsidyAmount.toStringAsFixed(2)} ETB',
              valueColor: const Color(0xFF047857),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Text(
                'You pay',
                style: TextStyle(
                  color: _dark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_amountDue.toStringAsFixed(2)} ETB',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _greyText)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _dark,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
