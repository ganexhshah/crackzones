import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  static const List<_WheelSlice> _slices = [
    _WheelSlice(
      label: '50',
      type: 'coins',
      value: 50,
      color: Color(0xFF3B82F6),
    ),
    _WheelSlice(
      label: '100',
      type: 'coins',
      value: 100,
      color: Color(0xFFEF4444),
    ),
    _WheelSlice(
      label: '200',
      type: 'coins',
      value: 200,
      color: Color(0xFFF59E0B),
    ),
    _WheelSlice(
      label: '500',
      type: 'coins',
      value: 500,
      color: Color(0xFF10B981),
    ),
    _WheelSlice(
      label: 'TOKEN',
      type: 'free_entry_token',
      value: 1,
      color: Color(0xFFA855F7),
    ),
    _WheelSlice(
      label: '1000',
      type: 'coins',
      value: 1000,
      color: Color(0xFFEC4899),
    ),
  ];

  late final AnimationController _spinController;
  Animation<double>? _spinAnimation;
  double _wheelRotation = 0.0;
  int _lastTickSegment = -1;
  bool _loading = true;
  bool _spinning = false;
  int _coinBalance = 0;
  int _diamonds = 0;
  int _spinsLeft = 0;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _spinController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 5200),
          )
          ..addListener(_onSpinTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _spinning = false;
              });
              if (_lastResult.isNotEmpty) {
                _showResultDialog(_lastResult);
              }
            }
          });
    _loadStatus();
  }

  @override
  void dispose() {
    _spinController.removeListener(_onSpinTick);
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final res = await ApiService.getRewardsStatus();
    if (!mounted) return;
    if (res['error'] == null) {
      setState(() {
        _coinBalance = _asInt(res['coins']);
        _diamonds = _asInt(res['diamonds']);
        _spinsLeft = _asInt(res['spinsLeft']);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _spinNow() async {
    if (_spinning || _spinsLeft <= 0) return;
    setState(() => _spinning = true);

    final res = await ApiService.spinRewardWheel(
      clientSeed: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    if (!mounted) return;

    if (res['error'] != null) {
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final spin = Map<String, dynamic>.from((res['spin'] ?? {}) as Map);
    final rewardType = (spin['rewardType'] ?? '').toString();
    final rewardValue = _asInt(spin['rewardValue']);
    final rewardIndex = _resolveSliceIndex(
      rewardType: rewardType,
      rewardValue: rewardValue,
    );
    final rewardLabel = (res['rewardLabel'] ?? '${spin['rewardValue']}')
        .toString();

    setState(() {
      _spinsLeft = _asInt(res['spinsLeft']);
      _coinBalance = _asInt(res['coinBalance']);
      _diamonds = _coinBalance ~/ 500;
      _lastResult = rewardLabel;
    });

    _startSpinAnimation(rewardIndex);
  }

  int _resolveSliceIndex({
    required String rewardType,
    required int rewardValue,
  }) {
    final idx = _slices.indexWhere(
      (s) => s.type == rewardType && s.value == rewardValue,
    );
    return idx >= 0 ? idx : 0;
  }

  void _startSpinAnimation(int targetIndex) {
    final sliceAngle = (2 * math.pi) / _slices.length;
    final targetCenter = targetIndex * sliceAngle + (sliceAngle / 2);
    final stopAt = (-math.pi / 2) - targetCenter;
    final normalizedStop = _normalizeRadians(stopAt);
    final currentNorm = _normalizeRadians(_wheelRotation);
    var delta = normalizedStop - currentNorm;
    if (delta < 0) {
      delta += 2 * math.pi;
    }
    final fullRounds = (2 * math.pi) * 7;
    final targetRotation = _wheelRotation + fullRounds + delta;

    _spinAnimation = Tween<double>(begin: _wheelRotation, end: targetRotation)
        .animate(
          CurvedAnimation(parent: _spinController, curve: Curves.easeOutQuart),
        );
    _lastTickSegment = -1;
    _spinController.forward(from: 0);
  }

  void _onSpinTick() {
    final animation = _spinAnimation;
    if (animation == null) return;
    final value = animation.value;
    setState(() => _wheelRotation = value);

    final sliceAngle = (2 * math.pi) / _slices.length;
    final segment = (value / sliceAngle).floor();
    if (segment != _lastTickSegment) {
      _lastTickSegment = segment;
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
  }

  double _normalizeRadians(double angle) {
    final twoPi = 2 * math.pi;
    var result = angle % twoPi;
    if (result < 0) result += twoPi;
    return result;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showResultDialog(String rewardLabel) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFF59E0B),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You Won',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  rewardLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Awesome'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1020), Color(0xFF1F1140), Color(0xFFFF4DA6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Spin Wheel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _loadStatus,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBox('Coins', '$_coinBalance'),
                      _statBox('Diamonds', '$_diamonds'),
                      _statBox('Spins', '$_spinsLeft'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 330,
                      height: 330,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD966,
                            ).withValues(alpha: 0.45),
                            blurRadius: 34,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    _wheelView(),
                    Positioned(
                      top: 18,
                      child: CustomPaint(
                        size: const Size(40, 44),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: (_spinning || _loading || _spinsLeft <= 0)
                        ? null
                        : _spinNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD23F),
                      foregroundColor: const Color(0xFF111827),
                      disabledBackgroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _spinning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _spinsLeft > 0 ? 'SPIN NOW' : 'NO SPINS LEFT',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wheelView() {
    return Transform.rotate(
      angle: _wheelRotation,
      child: Container(
        width: 290,
        height: 290,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD23F), width: 9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _WheelPainter(slices: _slices),
          child: const Center(
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFF111827),
              child: Icon(Icons.casino, color: Color(0xFFFFD23F), size: 30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WheelSlice {
  final String label;
  final String type;
  final int value;
  final Color color;

  const _WheelSlice({
    required this.label,
    required this.type,
    required this.value,
    required this.color,
  });
}

class _WheelPainter extends CustomPainter {
  final List<_WheelSlice> slices;

  _WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sliceAngle = (2 * math.pi) / slices.length;

    for (int i = 0; i < slices.length; i++) {
      final start = (i * sliceAngle) - (math.pi / 2);
      final paint = Paint()..color = slices[i].color;
      canvas.drawArc(rect, start, sliceAngle, true, paint);

      final textAngle = start + (sliceAngle / 2);
      final textRadius = radius * 0.66;
      final dx = center.dx + math.cos(textAngle) * textRadius;
      final dy = center.dy + math.sin(textAngle) * textRadius;

      final tp = TextPainter(
        text: TextSpan(
          text: slices[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(textAngle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()..color = const Color(0xFFFFD23F);
    canvas.drawShadow(path, Colors.black54, 5, true);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = const Color(0xFF111827);
    canvas.drawCircle(Offset(size.width / 2, 6), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
