import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChapaResult {
  const ChapaResult({required this.completed, this.cancelledByUser = false});

  /// True when Chapa redirected to a known success URL.
  final bool completed;

  /// True when the user pressed back / closed the WebView before payment.
  final bool cancelledByUser;
}

/// Hosts the Chapa hosted-checkout URL inside an in-app WebView and resolves
/// when Chapa navigates to the configured `return_url` (success). Chapa hosted
/// checkouts always redirect to the merchant's return URL after a successful
/// payment, regardless of host (e.g. https://chapa.co/checkout/return/...).
///
/// We treat any navigation away from `chapa.co` to a non-Chapa origin, OR a
/// navigation that contains the well-known success markers (`status=success`,
/// `state=success`), as a successful completion.
class ChapaCheckoutPage extends StatefulWidget {
  const ChapaCheckoutPage({
    super.key,
    required this.checkoutUrl,
    required this.txRef,
  });

  final String checkoutUrl;
  final String txRef;

  @override
  State<ChapaCheckoutPage> createState() => _ChapaCheckoutPageState();
}

class _ChapaCheckoutPageState extends State<ChapaCheckoutPage> {
  static const Color _blue = Color(0xFF0B4D8B);

  late final WebViewController _controller;
  bool _resolved = false;
  bool _isLoading = true;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final isSuccess = _isSuccessUrl(request.url);
            if (isSuccess) {
              _resolveSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isSuccessUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return false;

    final query = parsed.queryParameters;
    final lower = parsed.toString().toLowerCase();

    final markedSuccess =
        (query['status']?.toLowerCase() == 'success') ||
        (query['state']?.toLowerCase() == 'success') ||
        lower.contains('payment-success') ||
        lower.contains('payment_success') ||
        lower.contains('status=success');
    final hasOurTxRef =
        query['tx_ref'] == widget.txRef ||
        query['trx_ref'] == widget.txRef ||
        url.contains(widget.txRef);

    return markedSuccess || hasOurTxRef;
  }

  void _resolveSuccess() {
    if (_resolved) return;
    _resolved = true;
    Navigator.of(context).pop(const ChapaResult(completed: true));
  }

  Future<bool> _confirmCancel() async {
    if (_resolved) return true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text(
          'You will exit the Chapa checkout. If you have already paid, you can verify the payment from your queue screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFD92D20)),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _confirmCancel();
        if (shouldExit && !_resolved && mounted) {
          _resolved = true;
          Navigator.of(
            context,
          ).pop(const ChapaResult(completed: false, cancelledByUser: true));
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: _blue),
            onPressed: () async {
              final shouldExit = await _confirmCancel();
              if (shouldExit && !_resolved && mounted) {
                _resolved = true;
                Navigator.of(context).pop(
                  const ChapaResult(completed: false, cancelledByUser: true),
                );
              }
            },
          ),
          title: const Text(
            'Chapa Checkout',
            style: TextStyle(
              color: _blue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadProgress > 0 ? _loadProgress / 100.0 : null,
                minHeight: 3,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(_blue),
              ),
          ],
        ),
      ),
    );
  }
}
