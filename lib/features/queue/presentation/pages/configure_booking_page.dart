import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/token_storage.dart';
import '../../../auth/data/auth_service.dart';
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
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _primary = Color(0xFF3B82F6);
  static const Color _primaryDark = Color(0xFF2563EB);
  static const Color _accent = Color(0xFF10B981);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _greyText = Color(0xFF6B7280);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _inputBg = Color(0xFFF9FAFB);

  final TokenStorage _tokenStorage = SecureTokenStorage();
  late final AuthService _authService;
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
  
  AuthUserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _authService = AuthServiceImpl(tokenStorage: _tokenStorage);
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
      
      // Fetch user profile
      final session = await _authService.restoreSession();
      _currentUser = session?.user;
      
      // Pre-fill phone number if available
      if (_currentUser?.phoneNumber != null) {
        _phoneController.text = _currentUser!.phoneNumber!;
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
        backgroundColor: _cardBg,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primary, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        title: const Text(
          'Configure Booking',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
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
                backgroundColor: _primary,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: _primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
              backgroundColor: _primary,
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
        : widget.station.distanceFromUser != null
        ? widget.station.distanceText
        : 'OPEN';
    final badgeColor = intakeOk
        ? Colors.orange
        : const Color(0xFFEF4444);
    final badgeBg = intakeOk
        ? Colors.orange.withOpacity(0.1)
        : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'STATION',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
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
              color: _dark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.queue, size: 14, color: _primary),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.station.activeQueueLength} in line now',
                style: const TextStyle(fontSize: 13, color: _greyText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_gas_station, size: 14, color: _accent),
              ),
              const SizedBox(width: 8),
              Text(
                widget.station.fuelStatusLabel,
                style: const TextStyle(fontSize: 13, color: _greyText, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vehicle>(
          value: _selectedVehicle,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _primary,
              size: 20,
            ),
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
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.12), _accent.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Fuel Quota',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quota.remainingLiters.toStringAsFixed(1)} L available',
                      style: const TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...quota.periods.map((period) => _buildQuotaPeriod(period)),
        ],
      ),
    );
  }

  Widget _buildQuotaPeriod(QuotaPeriod period) {
    final limit = period.litersLimit;
    final remaining = period.remainingLiters;
    final used = limit - remaining;
    final percentage = limit > 0 ? (remaining / limit) * 100 : 0;
    
    Color getProgressColor() {
      if (percentage > 50) return Colors.green;
      if (percentage > 20) return Colors.orange;
      return Colors.red;
    }
    
    final progressColor = getProgressColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Period label and percentage
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.period.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: _dark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progressColor.withOpacity(0.9),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [progressColor.withOpacity(0.8), progressColor],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${used.toStringAsFixed(1)} L used',
                  style: const TextStyle(
                    color: _greyText,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Liters info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${remaining.toStringAsFixed(1)} L',
                style: const TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'of ${limit.toStringAsFixed(1)} L',
                style: const TextStyle(
                  color: _greyText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FuelPrice>(
          value: _selectedFuelPrice,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _primary,
              size: 20,
            ),
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
        fillColor: _inputBg,
        suffixText: 'LTR',
        suffixStyle: const TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primary, width: 2),
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
        hintText: '+251914******',
        filled: true,
        fillColor: _inputBg,
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.phone, color: _primary, size: 18),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primary, width: 2),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardBg, _cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PAYMENT SUMMARY',
              style: TextStyle(
                color: _primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
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
                  color: _primary,
                  fontSize: 24,
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
