import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/token_storage.dart';
import '../../data/transaction_model.dart';
import '../../data/transaction_service.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    this.initial,
  });

  final int transactionId;
  final OwnerTransaction? initial;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);

  final TransactionService _service = TransactionService();
  final TokenStorage _tokenStorage = SecureTokenStorage();

  OwnerTransaction? _tx;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tx = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null)
        throw Exception('Session expired. Please login again.');
      final tx = await _service.getTransaction(token, widget.transactionId);
      if (!mounted) return;
      setState(() {
        _tx = tx;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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
          'Receipt',
          style: TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _tx == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _tx == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _load,
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

    final tx = _tx!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_receiptCard(tx)],
    );
  }

  Widget _receiptCard(OwnerTransaction tx) {
    final station = tx.station?.name ?? 'Station #—';
    final stationPhone = tx.station?.phone;
    final plate = tx.vehicle?.plateNumber ?? '—';
    final vehicleLabel = tx.vehicle?.label;
    final fuel = tx.payment?.fuelType ?? '—';
    final liters = tx.litersDispensed;
    final pricePerLiter = tx.payment?.pricePerLiter ?? '—';
    final amount = tx.payment?.amount ?? '—';
    final currency = tx.payment?.currency ?? 'ETB';
    final paidAt = tx.payment?.paidAt;
    final txRef = tx.payment?.txRef;
    final receiptRef = tx.receiptRef;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FUEL RECEIPT',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${tx.transactionId}',
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$amount $currency',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _row('Served at', _formatDateTime(tx.servedAt)),
          if (paidAt != null && paidAt.isNotEmpty)
            _row('Paid at', _formatDateTimeIso(paidAt)),
          const SizedBox(height: 8),
          _row('Station', station),
          if (stationPhone != null && stationPhone.isNotEmpty)
            _row('Station phone', stationPhone),
          const SizedBox(height: 8),
          _row('Vehicle plate', plate),
          if (vehicleLabel != null && vehicleLabel.isNotEmpty)
            _row('Vehicle label', vehicleLabel),
          const SizedBox(height: 8),
          _row('Fuel type', fuel),
          _row('Liters dispensed', '$liters L'),
          _row('Unit price', '$pricePerLiter $currency'),
          const SizedBox(height: 8),
          _row('Queue booking', '#${tx.queueBookingId}'),
          if (receiptRef != null && receiptRef.isNotEmpty)
            _row('Receipt ref', receiptRef),
          if (txRef != null && txRef.isNotEmpty) ...[
            const SizedBox(height: 8),
            _txRefRow(txRef),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: _grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _dark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txRefRow(String txRef) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Transaction ref',
              style: TextStyle(
                color: _grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              txRef,
              style: const TextStyle(
                color: _dark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: _blue),
            tooltip: 'Copy reference',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: txRef));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
  }

  String _formatDateTimeIso(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return _formatDateTime(parsed);
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
