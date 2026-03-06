import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'coin_withdraw_screen.dart';
import 'spin_wheel_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _claiming = false;
  int _coins = 0;
  int _diamonds = 0;
  int _streak = 0;
  int _spinsLeft = 0;
  int _nextDailyRewardCoins = 0;
  bool _canClaimDaily = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _loadRewardsStatus();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadRewardsStatus({
    bool forceRefresh = false,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    final response = await ApiService.getRewardsStatus(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    if (response['error'] == null) {
      setState(() {
        _coins = _asInt(response['coins']);
        _diamonds = _asInt(response['diamonds']);
        _streak = _asInt(response['streak']);
        _spinsLeft = _asInt(response['spinsLeft']);
        _nextDailyRewardCoins = _asInt(response['nextDailyRewardCoins']);
        _canClaimDaily = (response['canClaimDaily'] ?? false) as bool;
        _loading = false;
      });
      return;
    }

    if (showLoader) {
      setState(() => _loading = false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error'].toString()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _claimDaily() async {
    if (_claiming || !_canClaimDaily) return;
    setState(() => _claiming = true);
    final response = await ApiService.claimDailyReward();
    if (!mounted) return;
    setState(() => _claiming = false);

    if (response['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _loadRewardsStatus(forceRefresh: true, showLoader: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Claimed +${response['rewardCoins'] ?? 0} coins. Streak ${response['streak'] ?? 1}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openSpinWheel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
    );
    if (!mounted) return;
    await _loadRewardsStatus(forceRefresh: true, showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1B2430)),
        title: const Text(
          'Rewards',
          style: TextStyle(
            color: Color(0xFF1B2430),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? _buildRewardsSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadRewardsStatus(
                forceRefresh: true,
                showLoader: false,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _heroWalletCard(),
                  const SizedBox(height: 14),
                  _statsGrid(),
                  const SizedBox(height: 14),
                  _streakStrip(),
                  const SizedBox(height: 14),
                  _dailyClaimCard(),
                  const SizedBox(height: 14),
                  _spinActionCard(),
                  const SizedBox(height: 14),
                  _withdrawEntryCard(),
                ],
              ),
            ),
    );
  }

  Widget _heroWalletCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Reward Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _bigNumber(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: _coins.toString(),
                ),
              ),
              Container(
                width: 1,
                height: 54,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _bigNumber(
                  icon: Icons.diamond,
                  label: 'Diamonds',
                  value: _diamonds.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigNumber({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFBBF24)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            color: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFEA580C),
            icon: Icons.local_fire_department,
            title: 'Streak',
            value: '$_streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            color: const Color(0xFFE0E7FF),
            iconColor: const Color(0xFF3730A3),
            icon: Icons.casino,
            title: 'Spins Left',
            value: '$_spinsLeft',
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1B2430),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Streak',
            style: TextStyle(
              color: Color(0xFF1B2430),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              final active = day <= _streak;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: day == 7 ? 0 : 6),
                  height: 34,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'D$day',
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF111827)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _dailyClaimCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 18,
                color: Color(0xFF334155),
              ),
              const SizedBox(width: 8),
              const Text(
                'Daily Check-in',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2430),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _canClaimDaily
                ? 'Claim now to get $_nextDailyRewardCoins coins and +1 spin token.'
                : 'Already claimed today. Come back tomorrow.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_canClaimDaily && !_claiming) ? _claimDaily : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canClaimDaily
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFE2E8F0),
                foregroundColor: _canClaimDaily
                    ? const Color(0xFF111827)
                    : const Color(0xFF64748B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _claiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _canClaimDaily ? 'Claim Daily Reward' : 'Claimed Today',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spinActionCard() {
    final hasSpins = _spinsLeft > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSpins
              ? const [Color(0xFF14532D), Color(0xFF166534)]
              : const [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final scale = hasSpins ? 1 + (_pulse.value * 0.12) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.casino,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSpins ? 'Spin Wheel Ready' : 'No Spin Tokens',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$_spinsLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: hasSpins ? _openSpinWheel : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: hasSpins
                    ? const Color(0xFF14532D)
                    : const Color(0xFF64748B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                hasSpins ? 'Open Spin Wheel' : 'Claim Daily to Get Spins',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withdrawEntryCard() {
    final maxRupees = _coins ~/ 500;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18, color: Color(0xFF334155)),
              const SizedBox(width: 8),
              const Text(
                'Coin Withdrawal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2430),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Max Rs $maxRupees',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '500 coins = 1 diamond = Rs 1',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoinWithdrawScreen()),
                );
                if (!mounted) return;
                await _loadRewardsStatus(
                  forceRefresh: true,
                  showLoader: false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Withdraw Screen',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _skeletonBlock(height: 170, radius: 20),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _skeletonBlock(height: 84, radius: 14)),
            const SizedBox(width: 10),
            Expanded(child: _skeletonBlock(height: 84, radius: 14)),
          ],
        ),
        const SizedBox(height: 14),
        _skeletonBlock(height: 110, radius: 14),
        const SizedBox(height: 14),
        _skeletonBlock(height: 170, radius: 16),
        const SizedBox(height: 14),
        _skeletonBlock(height: 150, radius: 16),
        const SizedBox(height: 14),
        _skeletonBlock(height: 150, radius: 16),
      ],
    );
  }

  Widget _skeletonBlock({required double height, double radius = 12}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

