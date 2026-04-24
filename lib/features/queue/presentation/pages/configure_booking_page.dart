import 'package:flutter/material.dart';
import '../../../stations/data/station_model.dart';

class ConfigureBookingPage extends StatefulWidget {
  final Station station;

  const ConfigureBookingPage({super.key, required this.station});

  @override
  State<ConfigureBookingPage> createState() => _ConfigureBookingPageState();
}

class _ConfigureBookingPageState extends State<ConfigureBookingPage> {
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _greyText = Color(0xFF6B7280);

  String _selectedFuelType = 'Benzene';
  final TextEditingController _litersController = TextEditingController(text: '45');
  final double _unitPrice = 76.50;
  final double _maxQuota = 100.0; // Mocked quota
  bool _hasQuotaError = false;

  double get _totalAmount {
    final liters = double.tryParse(_litersController.text) ?? 0.0;
    return liters * _unitPrice;
  }

  @override
  void initState() {
    super.initState();
    _litersController.addListener(() {
      final liters = double.tryParse(_litersController.text) ?? 0.0;
      setState(() {
        _hasQuotaError = liters > _maxQuota;
      });
    });
  }

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fuel Type',
              style: TextStyle(
                color: _dark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFuelType,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _greyText, size: 20),
                  isExpanded: true,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFuelType = newValue;
                      });
                    }
                  },
                  items: <String>['Benzene', 'Naphtha']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Liters Requested',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Max: ${_maxQuota.toStringAsFixed(1)} LTR',
                  style: const TextStyle(
                    color: _greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _hasQuotaError ? const Color(0xFFFEE2E2) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
                border: _hasQuotaError ? Border.all(color: const Color(0xFFEF4444), width: 1.5) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _litersController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Text(
                    'LTR',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (_hasQuotaError)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Amount exceeds your available quota limit.',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CURRENT STATION',
                        style: TextStyle(
                          color: _greyText,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE PUMP',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.station.name,
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, color: _greyText, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Vehicle',
                        style: TextStyle(
                          color: _greyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Toyota Hilux (AA-12345)',
                        style: TextStyle(
                          color: _dark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: _greyText, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Unit Price',
                        style: TextStyle(
                          color: _greyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_unitPrice.toStringAsFixed(2)} ETB',
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Amount Due',
                          style: TextStyle(
                            color: _greyText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _totalAmount.toStringAsFixed(2).replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},'),
                              style: const TextStyle(
                                color: _blue,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'ETB',
                              style: TextStyle(
                                color: _blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: _bg,
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _hasQuotaError ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: const Color(0xFF9CA3AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
}
