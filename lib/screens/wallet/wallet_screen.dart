import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/wallet_card.dart';
import '../../widgets/custom_navbar.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import 'add_money_screen.dart';
import 'transactions_screen.dart';
import 'wallet_reports_screen.dart';

class WalletScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const WalletScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _currentIndex = 3;
  bool _showAddMoney = false;
  bool _showWithdraw = false;
  bool _showPayment = false;
  bool _showRecentTransactions = true;
  bool _hasPaymentProof = false;
  final _amountController = TextEditingController();
  final _withdrawAmountController = TextEditingController();
  final _withdrawAccountController = TextEditingController();
  final _withdrawNameController = TextEditingController();
  String? _selectedPayment;
  String? _selectedWithdrawMethod;
  int _selectedAmount = 0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'esewa', 'image': 'assets/esewa.webp', 'displayName': 'eSewa'},
    {'name': 'khalti', 'image': 'assets/khalti.png', 'displayName': 'Khalti'},
  ];

  final List<int> _quickAmounts = [100, 250, 500, 1000, 2000, 5000];
  final List<int> _quickWithdrawAmounts = [100, 250, 500, 1000, 1500];
  int _minDepositAmount = 100;
  int _minWithdrawalAmount = 100;

  int get _parsedAmount => int.tryParse(_amountController.text.trim()) ?? 0;
  int get _parsedWithdrawAmount =>
      int.tryParse(_withdrawAmountController.text.trim()) ?? 0;

  double get _walletBalanceValue =>
      Provider.of<UserProvider>(context, listen: false).walletBalance;

  double get _rawWinningBalance {
    final txs = Provider.of<WalletProvider>(
      context,
      listen: false,
    ).transactions;
    double wins = 0;
    double usedWithdrawals = 0;

    for (final tx in txs) {
      if (tx is! Map) continue;
      final type = (tx['type'] ?? '').toString();
      final status = (tx['status'] ?? '').toString();
      final amount = ((tx['amount'] ?? 0) as num).toDouble();

      if ((type == 'tournament_win' || type == 'custom_match_win') &&
          status == 'completed') {
        wins += amount;
      }
      if ((type == 'withdrawal' || type == 'gift_sent_withdrawable') &&
          (status == 'completed' || status == 'pending')) {
        usedWithdrawals += amount;
      }
    }

    final winningLeft = wins - usedWithdrawals;
    return winningLeft > 0 ? winningLeft : 0;
  }

  double get _withdrawableWinningBalance {
    final winning = _rawWinningBalance;
    final wallet = _walletBalanceValue;
    return winning < wallet ? winning : wallet;
  }

  int get _availableBalance => _withdrawableWinningBalance.floor();

  bool get _canContinueAddMoney =>
      _selectedPayment != null && _amountController.text.trim().isNotEmpty;
  bool get _canSubmitWithdraw =>
      _selectedWithdrawMethod != null &&
      _withdrawAmountController.text.trim().isNotEmpty &&
      _withdrawAccountController.text.trim().isNotEmpty &&
      _withdrawNameController.text.trim().isNotEmpty;

  String get _selectedPaymentLabel {
    if (_selectedPayment == null) return '';
    final match = _paymentMethods.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?['name'] == _selectedPayment,
      orElse: () => null,
    );
    return (match?['displayName'] ?? _selectedPayment).toString();
  }

  String get _selectedWithdrawMethodLabel {
    if (_selectedWithdrawMethod == null) return '';
    final match = _paymentMethods.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?['name'] == _selectedWithdrawMethod,
      orElse: () => null,
    );
    return (match?['displayName'] ?? _selectedWithdrawMethod).toString();
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_handleAmountChanged);
    _withdrawAmountController.addListener(_handleAmountChanged);
    _withdrawAccountController.addListener(_handleAmountChanged);
    _withdrawNameController.addListener(_handleAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final settingsResult = await ApiService.getSystemSettings();
    final settings = (settingsResult['settings'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(settingsResult['settings'])
        : <String, dynamic>{};
    final minDeposit = (settings['minDepositAmount'] is num)
        ? (settings['minDepositAmount'] as num).toInt()
        : 100;
    final minWithdraw = (settings['minWithdrawalAmount'] is num)
        ? (settings['minWithdrawalAmount'] as num).toInt()
        : 100;
    if (mounted) {
      setState(() {
        _minDepositAmount = minDeposit > 0 ? minDeposit : 100;
        _minWithdrawalAmount = minWithdraw > 0 ? minWithdraw : 100;
      });
    }
    await Future.wait([
      walletProvider.loadTransactions(),
      userProvider.loadWalletBalance(),
    ]);
  }

  @override
  void dispose() {
    _amountController.removeListener(_handleAmountChanged);
    _withdrawAmountController.removeListener(_handleAmountChanged);
    _withdrawAccountController.removeListener(_handleAmountChanged);
    _withdrawNameController.removeListener(_handleAmountChanged);
    _amountController.dispose();
    _withdrawAmountController.dispose();
    _withdrawAccountController.dispose();
    _withdrawNameController.dispose();
    super.dispose();
  }

  void _handleAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _continueToPayment() {
    final amount = _parsedAmount;
    if (amount >= _minDepositAmount) {
      FocusScope.of(context).unfocus();
      setState(() {
        _selectedAmount = amount;
        _showPayment = true;
        _showAddMoney = false;
        _hasPaymentProof = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum amount is Rs $_minDepositAmount')),
      );
    }
  }

  Future<void> _submitWithdrawRequest() async {
    final amount = _parsedWithdrawAmount;
    final availableWinning = _withdrawableWinningBalance;
    if (amount < _minWithdrawalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal is Rs $_minWithdrawalAmount'),
        ),
      );
      return;
    }
    if (amount > availableWinning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can withdraw only winning balance. Available winning: Rs ${availableWinning.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    FocusScope.of(context).unfocus();

    final success = await walletProvider.submitWithdrawal(
      amount: amount.toDouble(),
      method: _selectedWithdrawMethod ?? '',
      accountName: _withdrawNameController.text.trim(),
      accountNumber: _withdrawAccountController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            walletProvider.error ?? 'Failed to submit withdrawal request',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Provider.of<UserProvider>(context, listen: false).loadWalletBalance();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Withdrawal request of Rs $amount submitted for $_selectedWithdrawMethod',
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _showWithdraw = false;
      _withdrawAmountController.clear();
      _withdrawAccountController.clear();
      _withdrawNameController.clear();
      _selectedWithdrawMethod = null;
    });
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
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _showPayment
                        ? _buildPaymentSection()
                        : _showAddMoney
                        ? _buildAddMoneySection()
                        : _showWithdraw
                        ? _buildWithdrawSection()
                        : _buildWalletSection(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index != 2) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      height: kToolbarHeight,
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          if (_showAddMoney || _showPayment || _showWithdraw)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: () {
                setState(() {
                  if (_showPayment) {
                    _showPayment = false;
                    _showAddMoney = true;
                  } else if (_showWithdraw) {
                    _showWithdraw = false;
                  } else {
                    _showAddMoney = false;
                  }
                });
              },
            )
          else if (widget.showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (!widget.showBackButton &&
              !(_showAddMoney || _showPayment || _showWithdraw))
            const SizedBox(width: 48),
          SizedBox(width: 8),
          Text(
            _showPayment
                ? 'Payment'
                : _showAddMoney
                ? 'Add Money'
                : _showWithdraw
                ? 'Withdraw'
                : 'My Wallet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          Spacer(),
          if (!_showAddMoney && !_showPayment && !_showWithdraw) ...[
            IconButton(
              icon: Icon(
                _showRecentTransactions
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _showRecentTransactions
                    ? Colors.yellow[700]
                    : Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _showRecentTransactions = !_showRecentTransactions;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.history, color: Colors.grey[600]),
              onPressed: () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WalletCard(
          winningAmount: _withdrawableWinningBalance,
          onAddMoney: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => const AddMoneyScreen()),
            );

            if (result == true && mounted) {
              await _loadData();
            }
          },
          onWithdraw: () {
            setState(() {
              _showWithdraw = true;
              _showAddMoney = false;
              _showPayment = false;
            });
          },
        ),
        SizedBox(height: 30),
        if (_showRecentTransactions) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionsScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTransactionList(),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'Recent transactions are hidden by filter.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoneySection() {
    final amount = _parsedAmount;
    final isAmountValid = amount >= _minDepositAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.yellow[50]!, Colors.orange[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Secure Deposit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Top up wallet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Add funds to join matches faster',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an amount, select your payment app, and continue to upload payment proof.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.timer_outlined, 'Fast approval'),
                  _buildInfoChip(Icons.qr_code_2_outlined, 'QR supported'),
                  _buildInfoChip(Icons.receipt_long_outlined, 'Proof upload'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum deposit: Rs $_minDepositAmount',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  hintText: '$_minDepositAmount',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.yellow[700]!,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Quick amounts',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map(_buildQuickAmountChip).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select where you will pay from',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              ..._paymentMethods.map((method) => _buildPaymentOption(method)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deposit Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedPayment == null
                              ? 'Select a payment method to continue'
                              : "Pay via ${_paymentMethods.firstWhere((m) => m['name'] == _selectedPayment)['displayName']}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount > 0 ? 'Rs $amount' : 'Rs 0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
              if (_amountController.text.isNotEmpty && !isAmountValid) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Minimum deposit amount is Rs $_minDepositAmount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canContinueAddMoney ? _continueToPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    final isSelected = _parsedAmount == amount;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _amountController.text = amount.toString();
        FocusScope.of(context).unfocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[200]!,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          'Rs $amount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.orange[800] : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawSection() {
    final withdrawAmount = _parsedWithdrawAmount;
    final isMinValid = withdrawAmount >= _minWithdrawalAmount;
    final hasSufficientBalance = withdrawAmount <= _availableBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Withdraw Request',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Winning balance: Rs $_availableBalance',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Withdraw wallet balance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter amount, choose payout method, and provide account details to submit your withdrawal request.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.schedule_outlined, 'Manual approval'),
                  _buildInfoChip(Icons.verified_user_outlined, 'Account check'),
                  _buildInfoChip(Icons.payments_outlined, 'Payout transfer'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Withdrawal Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum: Rs $_minWithdrawalAmount | Winning balance: Rs $_availableBalance',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _withdrawAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  hintText: '$_minWithdrawalAmount',
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickWithdrawAmounts
                    .map(_buildWithdrawQuickAmountChip)
                    .toList(),
              ),
              if (_withdrawAmountController.text.isNotEmpty &&
                  (!isMinValid || !hasSufficientBalance)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Text(
                    !isMinValid
                        ? 'Minimum withdrawal is Rs $_minWithdrawalAmount'
                        : 'Only winning balance can be withdrawn. Available winning: Rs $_availableBalance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payout Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select where you want to receive the withdrawal',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              ..._paymentMethods.map((m) => _buildWithdrawMethodOption(m)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payout Account Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter details exactly as registered in your payout app',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _withdrawNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Account Holder Name',
                  hintText: 'Enter full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _withdrawAccountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: InputDecoration(
                  labelText: _selectedWithdrawMethodLabel.isEmpty
                      ? 'Account Number / ID'
                      : '$_selectedWithdrawMethodLabel Number / ID',
                  hintText: 'Enter payout account ID',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildWithdrawPreviewCard(),
      ],
    );
  }

  Widget _buildWithdrawQuickAmountChip(int amount) {
    final isSelected = _parsedWithdrawAmount == amount;
    final isDisabled = amount > _availableBalance;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isDisabled
          ? null
          : () {
              _withdrawAmountController.text = amount.toString();
              FocusScope.of(context).unfocus();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[100]
              : isSelected
              ? Colors.green[50]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[200]!
                : isSelected
                ? Colors.green[600]!
                : Colors.grey[200]!,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          'Rs $amount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDisabled
                ? Colors.grey[500]
                : isSelected
                ? Colors.green[800]
                : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawMethodOption(Map<String, dynamic> method) {
    final isSelected = _selectedWithdrawMethod == method['name'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedWithdrawMethod = method['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.green[600]! : Colors.grey[200]!,
                width: isSelected ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 42,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Image.asset(
                    method['image'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.grey[400],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['displayName'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Withdraw directly to this account',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.green[600] : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Colors.green[600]!
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawPreviewCard() {
    final amount = _parsedWithdrawAmount;
    final isValidAmount =
        amount >= _minWithdrawalAmount && amount <= _availableBalance;
    final canSubmit = _canSubmitWithdraw && isValidAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.south_west, color: Colors.green[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedWithdrawMethodLabel.isEmpty
                          ? 'Select payout method and enter account details'
                          : 'Transfer via $_selectedWithdrawMethodLabel',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                amount > 0 ? 'Rs $amount' : 'Rs 0',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Winning Balance', 'Rs $_availableBalance'),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Withdrawal Amount',
                  amount > 0 ? 'Rs $amount' : 'Rs 0',
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Payout Method',
                  _selectedWithdrawMethodLabel.isEmpty
                      ? 'Not selected'
                      : _selectedWithdrawMethodLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canSubmit ? _submitWithdrawRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Submit Withdrawal Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Withdrawals are reviewed before payout. Processing time may vary.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[100]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.yellow[200]!, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pay the exact amount before uploading proof',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rs $_selectedAmount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.yellow[100]!),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Amount', 'Rs $_selectedAmount'),
                const SizedBox(height: 10),
                Divider(color: Colors.yellow[200], height: 1),
                const SizedBox(height: 10),
                _buildSummaryRow('Payment Method', _selectedPaymentLabel),
                const SizedBox(height: 10),
                Divider(color: Colors.yellow[200], height: 1),
                const SizedBox(height: 10),
                _buildSummaryRow('Status', 'Awaiting payment'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentQrCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.qr_code_2, color: Colors.blue[700], size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1: Scan and Pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Use $_selectedPaymentLabel to pay Rs $_selectedAmount',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Icon(
                      Icons.qr_code,
                      size: 110,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Scan QR to pay Rs $_selectedAmount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              children: [
                _buildInstructionRow(
                  'Open $_selectedPaymentLabel and scan the QR',
                ),
                const SizedBox(height: 8),
                _buildInstructionRow(
                  'Complete payment for Rs $_selectedAmount',
                ),
                const SizedBox(height: 8),
                _buildInstructionRow(
                  'Take a screenshot of the successful transaction',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.yellow[700],
                    side: BorderSide(color: Colors.yellow[700]!, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Amount'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[800],
                    side: BorderSide(color: Colors.grey[300]!, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.upload_file_outlined,
                  color: Colors.green[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 2: Upload Payment Screenshot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Required to verify and approve the deposit',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _hasPaymentProof = !_hasPaymentProof;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hasPaymentProof ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasPaymentProof
                        ? Colors.green[300]!
                        : Colors.grey[300]!,
                    width: _hasPaymentProof ? 1.8 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasPaymentProof
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 44,
                      color: _hasPaymentProof
                          ? Colors.green[700]
                          : Colors.grey[500],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hasPaymentProof
                          ? 'Screenshot attached'
                          : 'Tap to upload screenshot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasPaymentProof
                          ? 'Tap again to replace the screenshot'
                          : 'PNG / JPG (Max 5MB)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use the successful payment confirmation screen from your payment app. Make sure amount and transaction status are clearly visible.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!, Colors.yellow[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Payment Step',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedPaymentLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Complete your wallet top-up',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan the QR, pay the exact amount, then upload your payment screenshot for verification.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.qr_code_2_outlined, 'Scan & pay'),
                  _buildInfoChip(Icons.upload_file_outlined, 'Upload proof'),
                  _buildInfoChip(Icons.verified_outlined, 'Manual review'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPaymentSummaryCard(),
        const SizedBox(height: 20),
        _buildPaymentQrCard(),
        const SizedBox(height: 20),
        _buildPaymentProofCard(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _hasPaymentProof
                        ? Icons.check_circle
                        : Icons.pending_actions_outlined,
                    size: 18,
                    color: _hasPaymentProof
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasPaymentProof
                          ? 'Payment proof attached. Submit for verification.'
                          : 'Attach payment screenshot before submitting.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showPayment = false;
                          _showAddMoney = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _hasPaymentProof
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Payment submitted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _showPayment = false;
                                _showAddMoney = false;
                                _amountController.clear();
                                _selectedPayment = null;
                                _hasPaymentProof = false;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Submit for Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedPayment == method['name'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedPayment = method['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.yellow[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.yellow[700]! : Colors.grey[200]!,
                width: isSelected ? 2 : 1.3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 42,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Image.asset(
                    method['image'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.payment, color: Colors.grey[400]);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['displayName'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Scan QR and upload screenshot',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.yellow[700] : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Colors.yellow[700]!
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        if (walletProvider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (walletProvider.transactions.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your transaction history will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Show only the 5 most recent transactions
        final recentTransactions = walletProvider.transactions.take(5).toList();

        return Column(
          children: recentTransactions.map((transaction) {
            final type = transaction['type'] ?? '';
            final amount = (transaction['amount'] ?? 0).toDouble();
            final status = transaction['status'] ?? 'pending';
            final method = transaction['method'] ?? '';
            final createdAt = DateTime.parse(transaction['createdAt']);
            final timeAgo = _getTimeAgo(createdAt);
            final screenshotUrl = transaction['screenshot']?.toString();
            final referenceNote = transaction['reference']?.toString();
            final reasonNote = referenceNote?.trim().isNotEmpty == true
                ? referenceNote
                : null;

            // Determine transaction display properties
            String title;
            String subtitle;
            IconData icon;
            Color color;
            bool isCredit;

            if (type == 'deposit') {
              if (status == 'rejected') {
                title = 'Payment Rejected';
                subtitle = 'Tap to view reject reason';
                icon = Icons.cancel_outlined;
                color = Colors.red;
              } else if (status == 'pending') {
                title = 'Deposit Pending';
                subtitle = 'Verification Pending';
                icon = Icons.account_balance;
                color = Colors.orange;
              } else {
                title = 'Money Added';
                subtitle = method;
                icon = Icons.account_balance;
                color = Colors.green;
              }
              isCredit = true;
            } else if (type == 'withdrawal') {
              title = 'Withdrawal';
              subtitle = status == 'pending' ? 'Processing' : method;
              icon = Icons.arrow_upward;
              color = Colors.red;
              isCredit = false;
            } else if (type == 'tournament_entry') {
              title = 'Entry Fee';
              subtitle = method;
              icon = Icons.sports_esports;
              color = Colors.red;
              isCredit = false;
            } else if (type == 'tournament_win') {
              title = 'Match Win';
              subtitle = method;
              icon = Icons.emoji_events;
              color = Colors.green;
              isCredit = true;
            } else if (type == 'custom_match_entry_fee') {
              title = 'Custom Match Entry Fee';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : method;
              icon = Icons.sports_martial_arts_outlined;
              color = Colors.red;
              isCredit = false;
            } else if (type == 'custom_match_refund') {
              title = 'Custom Match Refund';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : 'Match cancelled refund';
              icon = Icons.replay_circle_filled_outlined;
              color = Colors.green;
              isCredit = true;
            } else if (type == 'custom_match_win') {
              title = 'Custom Match Winnings';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : method;
              icon = Icons.workspace_premium_outlined;
              color = Colors.green;
              isCredit = true;
            } else if (type == 'gift_sent' ||
                type == 'gift_sent_withdrawable') {
              title = 'Gift Sent';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : 'Gift sent to user';
              icon = Icons.redeem_outlined;
              color = Colors.deepOrange;
              isCredit = false;
            } else if (type == 'gift_received') {
              title = 'Gift Received';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : 'Gift received from user';
              icon = Icons.card_giftcard_outlined;
              color = Colors.green;
              isCredit = true;
            } else if (type == 'reward_coin_withdrawal') {
              title = 'Coins Withdrawn';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? referenceNote!
                  : 'Coins converted to wallet balance';
              icon = Icons.swap_horiz;
              color = Colors.teal;
              isCredit = true;
            } else if (type == 'admin_credit') {
              title = 'Admin Added Money';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? 'Reason: $referenceNote'
                  : 'Admin wallet adjustment';
              icon = Icons.add_circle_outline;
              color = Colors.green;
              isCredit = true;
            } else if (type == 'admin_debit') {
              title = 'Admin Deducted Money';
              subtitle = referenceNote?.trim().isNotEmpty == true
                  ? 'Reason: $referenceNote'
                  : 'Admin wallet adjustment';
              icon = Icons.remove_circle_outline;
              color = Colors.red;
              isCredit = false;
            } else {
              title = type;
              subtitle = method;
              icon = Icons.receipt;
              color = Colors.grey;
              isCredit = amount > 0;
            }

            final amountStr =
                '${isCredit ? '+' : '-'} Rs ${amount.abs().toStringAsFixed(2)}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionItem(
                (transaction['id'] ?? '').toString(),
                title,
                subtitle,
                amountStr,
                icon,
                color,
                timeAgo,
                isCredit,
                status: status,
                screenshotUrl: screenshotUrl,
                reasonNote:
                    (status == 'rejected' ||
                        type == 'admin_credit' ||
                        type == 'admin_debit')
                    ? reasonNote
                    : null,
                onResubmit: (type == 'deposit' && status == 'rejected')
                    ? () {
                        final normalizedMethod = method
                            .toString()
                            .trim()
                            .toLowerCase();
                        setState(() {
                          _showPayment = false;
                          _showWithdraw = false;
                          _showAddMoney = true;
                          _selectedPayment = normalizedMethod.isEmpty
                              ? null
                              : normalizedMethod;
                          _amountController.text = amount.toInt().toString();
                        });
                      }
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showTransactionDetails({
    required String transactionId,
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color color,
    required String time,
    required bool isCredit,
    String status = 'completed',
    String? screenshotUrl,
    String? reasonNote,
    VoidCallback? onResubmit,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Status',
                        status == 'pending'
                            ? 'Pending'
                            : status == 'rejected'
                            ? 'Rejected'
                            : 'Completed',
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Time', time),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Type', isCredit ? 'Credit' : 'Debit'),
                    ],
                  ),
                ),
                if (reasonNote != null && reasonNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reasonNote,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[900],
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (screenshotUrl != null &&
                    screenshotUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Payment Screenshot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 420),
                      color: Colors.grey[100],
                      child: Image.network(
                        screenshotUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey[500],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unable to load screenshot',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (status == 'rejected' && onResubmit != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onResubmit();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resubmit Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _reportWalletTransaction(transactionId);
                        },
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[200]!),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportWalletTransaction(String transactionId) async {
    final reasons = <String>[
      'Payment not reflected',
      'Wrong amount credited/debited',
      'Unauthorized transaction',
      'Suspicious activity',
      'Other wallet issue',
    ];
    String? selectedReason;

    final picked = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report this wallet transaction',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...reasons.map(
                    (item) => RadioListTile<String>(
                      dense: true,
                      value: item,
                      groupValue: selectedReason,
                      onChanged: (v) => setSheetState(() => selectedReason = v),
                      title: Text(item),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedReason == null
                          ? null
                          : () => Navigator.of(sheetContext).pop(true),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked != true || selectedReason == null) return;

    final detailsCtrl = TextEditingController();
    final more = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text("Want to tell us more? It's optional"),
        content: TextField(
          controller: detailsCtrl,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add details...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (more == null) return;

    final res = await ApiService.createV1WalletReport(
      transactionId: transactionId,
      reason: selectedReason!,
      details: detailsCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res['error'] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['error'].toString())));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Thanks for helping our community'),
        content: const Text(
          'Your report helps us protect the community from harmful content.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletReportsScreen()),
    );
  }

  Widget _buildTransactionItem(
    String transactionId,
    String title,
    String subtitle,
    String amount,
    IconData icon,
    Color color,
    String time,
    bool isCredit, {
    String status = 'completed',
    String? screenshotUrl,
    String? reasonNote,
    VoidCallback? onResubmit,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showTransactionDetails(
          transactionId: transactionId,
          title: title,
          subtitle: subtitle,
          amount: amount,
          icon: icon,
          color: color,
          time: time,
          isCredit: isCredit,
          status: status,
          screenshotUrl: screenshotUrl,
          reasonNote: reasonNote,
          onResubmit: onResubmit,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (status == 'pending') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
