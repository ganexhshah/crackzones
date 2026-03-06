import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _profile;
  double _walletBalance = 0.0;
  List<dynamic> _gameIds = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  
  Map<String, dynamic>? get profile => _profile;
  double get walletBalance => _walletBalance;
  List<dynamic> get gameIds => _gameIds;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await ApiService.getProfile();
      if (result['user'] != null) {
        _profile = result['user'];
        _walletBalance = (result['user']['walletBalance'] ?? 0).toDouble();
        _gameIds = result['user']['gameIds'] ?? [];
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadWalletBalance() async {
    try {
      final result = await ApiService.getWalletBalance();
      if (result['balance'] != null) {
        _walletBalance = (result['balance']).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load balance error: $e');
    }
  }
  
  Future<void> loadGameIds() async {
    try {
      final result = await ApiService.getGameIds();
      if (result['gameIds'] != null) {
        _gameIds = result['gameIds'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load game IDs error: $e');
    }
  }
  
  Future<bool> saveGameId(String gameName, String gameId) async {
    try {
      final result = await ApiService.saveGameId(
        gameName: gameName,
        gameId: gameId,
      );
      
      if (result['error'] == null) {
        await loadGameIds();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Save game ID error: $e');
      return false;
    }
  }
  
  Future<bool> deleteGameId(String id) async {
    try {
      final result = await ApiService.deleteGameId(id);
      if (result['success'] == true) {
        await loadGameIds();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete game ID error: $e');
      return false;
    }
  }
  
  Future<bool> updateProfile({String? name, String? phone}) async {
    try {
      final result = await ApiService.updateProfile(
        name: name,
        phone: phone,
      );
      
      if (result['user'] != null) {
        _profile = result['user'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }
  
  Future<void> loadStats() async {
    try {
      final result = await ApiService.getUserStats();
      if (result['error'] != null) {
        debugPrint('Load stats error from API: ${result['error']}');
        // Don't throw, just log and continue
        return;
      }
      if (result['stats'] != null) {
        _stats = result['stats'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load stats exception: $e');
      // Don't rethrow, just log
    }
  }
}


