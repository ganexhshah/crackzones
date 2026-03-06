import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../wallet/add_money_screen.dart';
import 'match_rules_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _entryFeeCtrl = TextEditingController(text: '0');
  final _defaultCoinCtrl = TextEditingController(text: '9950');

  String _roomType = 'CUSTOM_ROOM';
  String _selectedMode = '1v1';
  int _selectedRounds = 7;

  bool _throwableLimit = true;
  bool _characterSkill = true;
  bool _headshotOnly = true;
  bool _gunAttributes = false;
  bool _allCharactersSelected = true;

  static const List<String> _activeCharacters = [
    'Tatsuya',
    'Alok',
    'Iris',
    'Xayne',
    'Homer',
    'Kenta',
    'Dmitri',
    'Skyler',
    'Chrono',
    'K',
    'Clu',
    'Steffie',
    'A124',
    'Wukong',
    'Santino',
    'Nero',
    'Oscar',
    'Koda',
    'Kassie',
    'Ignis',
    'Orion',
    'Ryden',
  ];
  Set<String> _selectedCharacters = <String>{};

  bool _submitting = false;
  bool _loadingOdds = true;
  Map<String, double> _oddsByMode = {
    '1v1': 1.8,
    '2v2': 1.8,
    '3v3': 1.8,
    '4v4': 1.8,
  };

  List<String> get _modeOptions => _roomType == 'CUSTOM_ROOM'
      ? const ['1v1', '2v2', '3v3', '4v4']
      : const ['1v1', '2v2'];

  List<int> get _roundOptions =>
      _roomType == 'CUSTOM_ROOM' ? const [7, 13] : const [9, 13];

  double get _entryFee => double.tryParse(_entryFeeCtrl.text.trim()) ?? 0;
  double get _currentOdd => _oddsByMode[_selectedMode] ?? 1.8;
  double get _winnerPayout => _entryFee * _currentOdd;

  @override
  void initState() {
    super.initState();
    if (_selectedCharacters.isEmpty) {
      _selectedCharacters = _activeCharacters.toSet();
    }
    _entryFeeCtrl.addListener(() => setState(() {}));
    _loadOdds();
  }

  @override
  void dispose() {
    _entryFeeCtrl.dispose();
    _defaultCoinCtrl.dispose();
    super.dispose();
  }

  void _onRoomTypeChanged(String roomType) {
    setState(() {
      _roomType = roomType;
      _selectedMode = _modeOptions.first;
      _selectedRounds = _roundOptions.first;
    });
  }

  Future<void> _loadOdds() async {
    setState(() => _loadingOdds = true);
    final res = await ApiService.getV1MatchOdds();
    if (!mounted) return;

    if (res['error'] == null && res['odds'] is Map) {
      final raw = Map<String, dynamic>.from(res['odds'] as Map);
      setState(() {
        _oddsByMode = {
          '1v1': (raw['1v1'] as num?)?.toDouble() ?? 1.8,
          '2v2': (raw['2v2'] as num?)?.toDouble() ?? 1.8,
          '3v3': (raw['3v3'] as num?)?.toDouble() ?? 1.8,
          '4v4': (raw['4v4'] as num?)?.toDouble() ?? 1.8,
        };
        _loadingOdds = false;
      });
      return;
    }

    setState(() => _loadingOdds = false);
  }

  Future<void> _createRoom() async {
    if (_submitting) return;
    if (_entryFee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry fee must be greater than 0')),
      );
      return;
    }
    if (!_characterSkill && _selectedCharacters.isNotEmpty) {
      _selectedCharacters.clear();
    }
    if (_characterSkill && !_allCharactersSelected && _selectedCharacters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 1 character or allow all')),
      );
      return;
    }

    // Show rules screen first
    final agreedToRules = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchRulesScreen(actionType: 'create'),
      ),
    );
    
    if (agreedToRules != true || !mounted) return;

    final shouldContinue = await _showDeductionConfirmDialog();
    if (!shouldContinue || !mounted) return;

    setState(() => _submitting = true);
    final defaultCoin = int.tryParse(_defaultCoinCtrl.text.trim()) ?? 9950;
    final selectedSkills = _characterSkill
        ? (_allCharactersSelected
              ? List<String>.from(_activeCharacters)
              : _selectedCharacters.toList())
        : <String>[];
    final res = await ApiService.createV1Match(
      entryFee: _entryFee,
      gameName: 'Free Fire',
      roomType: _roomType,
      matchType: _selectedMode,
      rounds: _selectedRounds,
      defaultCoin: defaultCoin,
      throwableLimit: _throwableLimit,
      characterSkill: _characterSkill,
      allSkillsAllowed: _allCharactersSelected,
      selectedSkills: selectedSkills,
      headshotOnly: _headshotOnly,
      gunAttributes: _gunAttributes,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['error'] != null) {
      final errorText = res['error'].toString();
      if (errorText.toLowerCase().contains('insufficient balance')) {
        await _showInsufficientBalanceDialog();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room created successfully')),
    );
    Navigator.pop(context, true);
  }

  Future<bool> _showDeductionConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Match Creation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rs ${_entryFee.toStringAsFixed(2)} will be deducted from your wallet and locked until match completion.',
              ),
              const SizedBox(height: 10),
              Text(
                'Winner payout: Rs ${_winnerPayout.toStringAsFixed(2)} (Odds ${_currentOdd.toStringAsFixed(2)}x)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.yellow[700]),
              child: const Text('Continue', style: TextStyle(color: Colors.black87)),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _showInsufficientBalanceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.yellow[800],
            size: 34,
          ),
          title: const Text('Insufficient Balance'),
          content: Text(
            'You need Rs ${_entryFee.toStringAsFixed(2)} to create this match. Please add money to your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.yellow[700]),
              icon: const Icon(Icons.add_card, color: Colors.black87),
              label: const Text(
                'Add Money',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            title: const Text('Create Match'),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Your Own Match Room',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose room type, rules, and entry fee.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _chipButton(
                        label: 'Custom Room',
                        selected: _roomType == 'CUSTOM_ROOM',
                        onTap: () => _onRoomTypeChanged('CUSTOM_ROOM'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _chipButton(
                        label: 'Lone Wolf',
                        selected: _roomType == 'LONE_WOLF',
                        onTap: () => _onRoomTypeChanged('LONE_WOLF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _modeOptions
                      .map(
                        (mode) => _pill(
                          label: mode,
                          selected: _selectedMode == mode,
                          onTap: () => setState(() => _selectedMode = mode),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _roundOptions
                      .map(
                        (r) => _pill(
                          label: '$r',
                          selected: _selectedRounds == r,
                          onTap: () => setState(() => _selectedRounds = r),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _defaultCoinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Default Coin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _ruleSwitch(
                  title: 'Throwable Limit',
                  subtitle: 'Enable throwable limit',
                  value: _throwableLimit,
                  onChanged: (v) => setState(() => _throwableLimit = v),
                ),
                _ruleSwitch(
                  title: 'Character Skill',
                  subtitle: 'Allow character skills',
                  value: _characterSkill,
                  onChanged: (v) => setState(() {
                    _characterSkill = v;
                    if (!_characterSkill) {
                      _allCharactersSelected = false;
                      _selectedCharacters.clear();
                    } else if (_selectedCharacters.isEmpty) {
                      _allCharactersSelected = true;
                      _selectedCharacters = _activeCharacters.toSet();
                    }
                  }),
                ),
                if (_characterSkill) _characterSelector(),
                _ruleSwitch(
                  title: 'Headshot Mode',
                  subtitle: 'Headshot only',
                  value: _headshotOnly,
                  onChanged: (v) => setState(() => _headshotOnly = v),
                ),
                _ruleSwitch(
                  title: 'Gun Attributes',
                  subtitle: 'Enable gun attributes',
                  value: _gunAttributes,
                  onChanged: (v) => setState(() => _gunAttributes = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _entryFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Entry Fee',
                          border: OutlineInputBorder(),
                          prefixText: 'Rs ',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _vsRoundPreview(),
                const SizedBox(height: 12),
                Text(
                  _loadingOdds
                      ? 'Winner payout: calculating with latest odds...'
                      : 'Winner payout: Rs ${_winnerPayout.toStringAsFixed(2)} (${_currentOdd.toStringAsFixed(2)}x odds)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black87,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(
                    _submitting ? 'Creating...' : 'Create Room',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
        // Loading overlay
        if (_submitting)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Creating Match...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _characterSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _allCharactersSelected,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.yellow[700],
            title: const Text(
              'Allow all active characters',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onChanged: (v) {
              setState(() {
                _allCharactersSelected = v ?? false;
                if (_allCharactersSelected) {
                  _selectedCharacters = _activeCharacters.toSet();
                }
              });
            },
          ),
          if (!_allCharactersSelected) ...[
            Text(
              'Select allowed characters (${_selectedCharacters.length})',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeCharacters.map((name) {
                final selected = _selectedCharacters.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedCharacters.add(name);
                      } else {
                        _selectedCharacters.remove(name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vsRoundPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mode: $_selectedMode',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_selectedRounds Rounds',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _slotCard('Slot 1', 'Me')),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.yellow[700],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'VS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _slotCard('Slot 2', 'Opponent')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _chipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow[700] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.yellow[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.yellow[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.orange[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _ruleSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _slotCard(String slot, String name) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slot, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

