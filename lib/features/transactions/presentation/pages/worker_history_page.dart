import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/data/token_storage.dart';
import '../../data/worker_transaction_service.dart';
import '../../data/transaction_model.dart';

class WorkerHistoryPage extends StatefulWidget {
  const WorkerHistoryPage({super.key});

  static const String routeName = '/worker-history';

  @override
  State<WorkerHistoryPage> createState() => _WorkerHistoryPageState();
}

class _WorkerHistoryPageState extends State<WorkerHistoryPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);

  final TokenStorage _tokenStorage = SecureTokenStorage();
  final WorkerTransactionService _transactionService = WorkerTransactionService();

  List<OwnerTransaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      final transactions = await _transactionService.getWorkerTransactions(
        token,
        from: _fromDate,
        to: _toDate,
      );

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadTransactions();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: _blue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: _blue),
            onPressed: _selectDateRange,
          ),
          if (_fromDate != null || _toDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: _blue),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_fromDate != null || _toDate != null) _buildFilterChip(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _transactions.isEmpty
                        ? _buildEmptyWidget()
                        : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, color: _blue, size: 16),
          const SizedBox(width: 6),
          Text(
            _fromDate != null && _toDate != null
                ? '${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)}'
                : _fromDate != null
                    ? 'From ${_formatDate(_fromDate!)}'
                    : 'Until ${_formatDate(_toDate!)}',
            style: const TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load transactions',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD92D20),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF304B66),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _fromDate != null || _toDate != null
                  ? 'Try adjusting the date filters'
                  : 'Completed transactions will appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(OwnerTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2540),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to transaction detail page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction details coming soon!')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_gas_station,
                      color: _blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction #${transaction.transactionId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111317),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(transaction.servedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildTransactionDetail('Vehicle', transaction.vehicle?.plateNumber ?? '—'),
              const SizedBox(height: 8),
              _buildTransactionDetail('Fuel', '${transaction.payment?.fuelType ?? '—'} • ${transaction.litersDispensed} L'),
              const SizedBox(height: 8),
              _buildTransactionDetail(
                'Amount',
                '${transaction.payment?.amount ?? '—'} ${transaction.payment?.currency ?? 'ETB'}',
              ),
              if (transaction.receiptRef != null && transaction.receiptRef!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTransactionDetail('Receipt', transaction.receiptRef!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111317),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
