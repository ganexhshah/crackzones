import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  List<dynamic> _tournaments = [];
  bool _isLoading = false;
  String? _error;
  
  List<dynamic> get tournaments => _tournaments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadTournaments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await ApiService.getTournaments();
      if (result['tournaments'] != null) {
        _tournaments = result['tournaments'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Load tournaments error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> joinTournament(String tournamentId) async {
    try {
      final result = await ApiService.joinTournament(tournamentId);
      
      if (result['error'] != null) {
        _error = result['error'];
        notifyListeners();
        return false;
      }
      
      await loadTournaments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}


