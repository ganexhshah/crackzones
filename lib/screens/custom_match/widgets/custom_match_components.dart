import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../custom_match_ui_models.dart';

class MatchStatusBadge extends StatelessWidget {
  final MatchStatus status;

  const MatchStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      MatchStatus.open => 'OPEN',
      MatchStatus.requested => 'REQUESTED',
      MatchStatus.confirmed => 'CONFIRMED',
      MatchStatus.completed => 'COMPLETED',
      MatchStatus.rejected => 'REJECTED',
      MatchStatus.expired => 'EXPIRED',
      MatchStatus.cancelled => 'CANCELLED',
    };

    final color = switch (status) {
      MatchStatus.open => Colors.blue,
      MatchStatus.requested => Colors.orange,
      MatchStatus.confirmed => Colors.green,
      MatchStatus.completed => Colors.purple,
      MatchStatus.rejected => Colors.red,
      MatchStatus.expired => Colors.grey,
      MatchStatus.cancelled => Colors.blueGrey,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
      ),
    );
  }
}

class MatchActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const MatchActionButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      height: 44,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: enabled ? Colors.yellow[800]! : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? Colors.yellow[700]
                    : Colors.grey[300],
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class TimerChip extends StatefulWidget {
  final DateTime expiresAt;

  const TimerChip({super.key, required this.expiresAt});

  @override
  State<TimerChip> createState() => _TimerChipState();
}

class _TimerChipState extends State<TimerChip> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final value = widget.expiresAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remaining = value.isNegative ? Duration.zero : value;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: Colors.orange[800]),
          const SizedBox(width: 6),
          Text(
            '$mm:$ss',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.orange[900],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class RoomCredentialCard extends StatelessWidget {
  final String roomId;
  final String roomPassword;

  const RoomCredentialCard({
    super.key,
    required this.roomId,
    required this.roomPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.yellow[200]!),
      ),
      child: Column(
        children: [
          _row(context, 'Room ID', roomId),
          const SizedBox(height: 10),
          _row(context, 'Password', roomPassword),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_all_rounded),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copied')),
            );
          },
        ),
      ],
    );
  }
}

class RequestBottomSheet extends StatelessWidget {
  final MatchRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestBottomSheet({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.yellow[100],
            child: Text(
              request.avatar,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text('Level ${request.level} challenger'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MatchActionButton(
                  label: 'Reject',
                  outlined: true,
                  onTap: () {
                    Navigator.pop(context);
                    onReject();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MatchActionButton(
                  label: 'Accept',
                  onTap: () {
                    Navigator.pop(context);
                    onAccept();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isMine;
  final String text;

  const ChatBubble({
    super.key,
    required this.isMine,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMine ? Colors.yellow[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine ? Colors.yellow[300]! : Colors.grey[300]!,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class WalletTile extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;

  const WalletTile({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.yellow[800]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class CustomMatchCard extends StatelessWidget {
  final CustomMatchUiModel match;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onTap;

  const CustomMatchCard({
    super.key,
    required this.match,
    required this.actionLabel,
    this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.yellow[100],
                    child: Text(
                      match.creatorAvatar,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.gameName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${match.matchType} � by ${match.creatorName}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MatchStatusBadge(status: match.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _meta('Entry Fee', 'Rs ${match.entryFee.toStringAsFixed(0)}'),
                  const SizedBox(width: 10),
                  _meta(
                    'Prize Pool',
                    'Rs ${match.prizePool.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                match.subtitle,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (match.status == MatchStatus.requested &&
                  !match.isCreator &&
                  match.requestExpiryAt != null) ...[
                const SizedBox(height: 8),
                TimerChip(expiresAt: match.requestExpiryAt!),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: MatchActionButton(label: actionLabel, onTap: onAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

