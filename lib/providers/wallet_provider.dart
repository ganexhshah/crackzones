import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletProvider with ChangeNotifier {
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadBalance() async {
    try {
      final result = await ApiService.getWalletBalance();
      if (result['balance'] != null) {
        _balance = (result['balance']).toDouble();
        notifyListeners();
      }
    } catch (e) {
      print('Load balance error: $e');
    }
  }
  
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load both old transactions and new wallet ledger
      final transactionsResult = await ApiService.getTransactions();
      final ledgerResult = await ApiService.getWalletLedger(limit: 100);
      
      List<dynamic> allTransactions = [];
      
      // Add old transactions
      if (transactionsResult['transactions'] != null) {
        allTransactions.addAll(transactionsResult['transactions']);
      }
      
      // Convert and add wallet ledger entries
      if (ledgerResult['ledger'] != null) {
        final ledgerEntries = ledgerResult['ledger'] as List;
        for (var entry in ledgerEntries) {
          final type = (entry['type'] ?? '').toString();
          final amount = double.tryParse(entry['amount']?.toString() ?? '0') ?? 0.0;
          final matchInfo = entry['match'] as Map<String, dynamic>?;
          
          String transactionType;
          String method = matchInfo?['gameName']?.toString() ?? 'Custom Match';
          String? reference;
          
          switch (type) {
            case 'LOCK':
              transactionType = 'custom_match_entry_fee';
              reference = 'Match Entry Fee Locked';
              break;
            case 'UNLOCK':
              transactionType = 'custom_match_refund';
              reference = 'Match Entry Fee Unlocked';
              break;
            case 'REFUND':
              transactionType = 'custom_match_refund';
              reference = 'Match Cancelled - Refund';
              break;
            case 'WIN':
              transactionType = 'custom_match_win';
              reference = 'Match Win Prize';
              break;
            case 'FEE':
              continue; // Skip fee entries as they're included in WIN
            default:
              transactionType = type.toLowerCase();
              reference = type;
          }
          
          allTransactions.add({
            'id': entry['id'],
            'type': transactionType,
            'amount': amount.abs(),
            'status': 'completed',
            'method': method,
            'reference': reference,
            'createdAt': entry['createdAt'],
            'matchId': entry['matchId'],
          });
        }
      }
      
      // Sort by date (newest first)
      allTransactions.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      _transactions = allTransactions;
    } catch (e) {
      _error = e.toString();
      print('Load transactions error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> submitDeposit({
    required double amount,
    required String method,
    required String screenshotPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await ApiService.submitDeposit(
        amount: amount,
        method: method,
        screenshotPath: screenshotPath,
      );
      
      if (result['error'] != null) {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Reload transactions
      await loadTransactions();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitWithdrawal({
    required double amount,
    required String method,
    required String accountName,
    required String accountNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.submitWithdrawal(
        amount: amount,
        method: method,
        accountName: accountName,
        accountNumber: accountNumber,
      );

      if (result['error'] != null) {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await loadTransactions();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
