import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'payment_screen.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountController = TextEditingController();
  String? _selectedPayment;
  int _minDepositAmount = 100;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'esewa', 'image': 'assets/esewa.webp', 'displayName': 'eSewa'},
    {'name': 'khalti', 'image': 'assets/khalti.png', 'displayName': 'Khalti'},
  ];

  bool get _canContinue {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    return _selectedPayment != null && amount >= _minDepositAmount;
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await ApiService.getSystemSettings();
    if (!mounted) return;
    final settings = (result['settings'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(result['settings'])
        : <String, dynamic>{};
    final minDeposit = (settings['minDepositAmount'] is num)
        ? (settings['minDepositAmount'] as num).toInt()
        : 100;
    setState(() {
      _minDepositAmount = minDeposit > 0 ? minDeposit : 100;
    });
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Money',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose amount and payment method',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Enter Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'Rs ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          hintText: '$_minDepositAmount',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.yellow[700]!,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum deposit: Rs $_minDepositAmount',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._paymentMethods.map((method) => _buildPaymentOption(method)),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Add Money',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedPayment == method['name'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayment = method['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                method['image'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.payment, color: Colors.grey[400]);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method['displayName'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: Colors.yellow[700], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _canContinue
                ? () async {
                    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
                    if (amount >= _minDepositAmount) {
                      final submitted = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            amount: amount,
                            paymentMethod: _selectedPayment!,
                          ),
                        ),
                      );

                      if (submitted == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Minimum amount is Rs $_minDepositAmount'),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Continue to Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
