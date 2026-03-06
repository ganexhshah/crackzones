import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

class FonepayPaymentScreen extends StatefulWidget {
  final int amount;

  const FonepayPaymentScreen({super.key, required this.amount});

  @override
  State<FonepayPaymentScreen> createState() => _FonepayPaymentScreenState();
}

class _FonepayPaymentScreenState extends State<FonepayPaymentScreen> {
  bool _isBusy = true;
  bool _isPolling = false;
  String? _error;
  String _statusText = 'Preparing Fonepay session...';
  String? _transactionId;
  String? _prn;
  String? _paymentUrl;
  Timer? _pollTimer;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isBusy = true;
      _isPolling = false;
      _error = null;
      _statusText = 'Creating payment session...';
    });

    final sessionRes = await ApiService.createFonepaySession(
      amount: widget.amount.toDouble(),
    );
    if (!mounted) return;
    if (sessionRes['error'] != null) {
      setState(() {
        _isBusy = false;
        _error = sessionRes['error'].toString();
      });
      return;
    }

    final session = sessionRes['session'];
    if (session is! Map) {
      setState(() {
        _isBusy = false;
        _error = 'Invalid payment session response.';
      });
      return;
    }

    final data = Map<String, dynamic>.from(session);
    final txId = (data['transactionId'] ?? '').toString();
    final prn = (data['prn'] ?? '').toString();
    final paymentUrl = (data['paymentUrl'] ?? '').toString();

    if (txId.isEmpty || prn.isEmpty || paymentUrl.isEmpty) {
      setState(() {
        _isBusy = false;
        _error = 'Incomplete session data from server.';
      });
      return;
    }

    _transactionId = txId;
    _prn = prn;
    _paymentUrl = paymentUrl;

    setState(() {
      _statusText = 'Opening Fonepay payment page...';
    });

    final opened = await launchUrl(
      Uri.parse(paymentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;

    if (!opened) {
      await _markFailed('Unable to open Fonepay payment page.');
      return;
    }

    _startStatusPolling();
  }

  Future<void> _markFailed(String message) async {
    final txId = _transactionId;
    if (txId != null && txId.isNotEmpty) {
      await ApiService.confirmFonepayPayment(
        transactionId: txId,
        paymentResult: {'PRN': _prn ?? '', 'RC': 'failed', 'PS': 'cancelled'},
      );
    }
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _isPolling = false;
      _error = message;
    });
  }

  void _startStatusPolling() {
    _pollTimer?.cancel();
    _deadline = DateTime.now().add(const Duration(minutes: 10));
    setState(() {
      _isBusy = false;
      _isPolling = true;
      _statusText =
          'Waiting for payment confirmation.\nAfter paying in Fonepay, return to app.';
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      if (_deadline != null && DateTime.now().isAfter(_deadline!)) {
        _pollTimer?.cancel();
        setState(() {
          _isPolling = false;
          _error = 'Payment session expired. No money was added.';
        });
        return;
      }
      await _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final txId = _transactionId;
    if (txId == null || txId.isEmpty) return;

    final statusRes = await ApiService.getFonepayStatus(transactionId: txId);
    if (!mounted || statusRes['error'] != null) return;
    final tx = statusRes['transaction'];
    if (tx is! Map) return;
    final status = (tx['status'] ?? '').toString().toLowerCase();
    if (status == 'completed') {
      _pollTimer?.cancel();
      await _handleSuccess();
      return;
    }
    if (status == 'rejected') {
      _pollTimer?.cancel();
      setState(() {
        _isPolling = false;
        _error = 'Payment failed. Wallet was not credited.';
      });
    }
  }

  Future<void> _handleSuccess() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await Future.wait([
      walletProvider.loadBalance(),
      walletProvider.loadTransactions(),
    ]);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _isPolling = false;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful. Wallet credited automatically.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final showLoader = _isBusy || _isPolling;
    return Scaffold(
      appBar: AppBar(title: const Text('Fonepay Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pay Rs ${widget.amount}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              if (showLoader) const CircularProgressIndicator(),
              if (showLoader) const SizedBox(height: 16),
              Text(
                _error ?? _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error != null ? Colors.red[700] : Colors.grey[800],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              if (_paymentUrl != null && _error == null)
                OutlinedButton(
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse(_paymentUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text('Open Fonepay Again'),
                ),
              if (_paymentUrl != null && _error == null)
                TextButton(
                  onPressed: () => _markFailed('Payment cancelled by user.'),
                  child: const Text('Cancel Payment'),
                ),
              if (_error != null)
                ElevatedButton(
                  onPressed: _startPayment,
                  child: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
