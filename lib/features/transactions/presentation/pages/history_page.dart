import 'package:flutter/material.dart';

import '../../../auth/data/token_storage.dart';
import '../../data/transaction_model.dart';
import '../../data/transaction_service.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static const String routeName = '/history';

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final TransactionService _service = TransactionService();

  List<OwnerTransaction> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTimeRange? _filterRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('Session expired. Please login again.');
      }
      final list = await _service.listTransactions(
        token,
        from: _filterRange?.start,
        to: _filterRange?.end,
      );
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _filterRange,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _filterRange = picked);
      await _load();
    }
  }

  void _clearRange() {
    setState(() => _filterRange = null);
    _load();
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
          'History',
          style: TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            icon: const Icon(Icons.calendar_today_outlined, color: _blue),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_filterRange != null) _filterChip(),
            Expanded(
              child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip() {
    final start = _filterRange!.start;
    final end = _filterRange!.end;
    final label = '${_formatDate(start)} → ${_formatDate(end)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text(label),
          backgroundColor: const Color(0xFFDBEAFE),
          labelStyle: const TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          deleteIconColor: const Color(0xFF1E40AF),
          onDeleted: _clearRange,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Could not load history',
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
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF98A2B3)),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Once a station worker completes your fueling, the receipt will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _grey, height: 1.4),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _historyTile(_items[index]),
    );
  }

  Widget _historyTile(OwnerTransaction tx) {
    final station = tx.station?.name ?? 'Station #—';
    final fuel = tx.payment?.fuelType ?? '';
    final amount = tx.payment?.amount ?? '0';
    final currency = tx.payment?.currency ?? 'ETB';
    final plate = tx.vehicle?.plateNumber ?? '—';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailPage(
              transactionId: tx.transactionId,
              initial: tx,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      station,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$amount $currency',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 14, color: _grey),
                  const SizedBox(width: 4),
                  Text(
                    plate,
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.local_gas_station, size: 14, color: _grey),
                  const SizedBox(width: 4),
                  Text(
                    fuel.isEmpty ? '—' : fuel,
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: _grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(tx.servedAt),
                    style: const TextStyle(fontSize: 11.5, color: _grey),
                  ),
                  const Spacer(),
                  Text(
                    '${tx.litersDispensed} L',
                    style: const TextStyle(
                      color: _dark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
