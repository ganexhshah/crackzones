import 'package:flutter/material.dart';
import 'package:my_app/screens/custom_match/custom_match_components.dart';

import 'custom_match_ui_models.dart';

class CustomMatchRequestsScreen extends StatefulWidget {
  final CustomMatchUiModel match;

  const CustomMatchRequestsScreen({super.key, required this.match});

  @override
  State<CustomMatchRequestsScreen> createState() =>
      _CustomMatchRequestsScreenState();
}

class _CustomMatchRequestsScreenState extends State<CustomMatchRequestsScreen> {
  late List<MatchRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = widget.match.joinRequests;
    if (_requests.isEmpty) {
      _requests = const [
        MatchRequest(id: 'u_5', name: 'ToxicBoy', avatar: 'TB', level: 38),
      ];
    }
  }

  void _accept(MatchRequest request) {
    setState(() => _requests = _requests.where((r) => r.id != request.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accepted. Match moved to CONFIRMED state.')),
    );
  }

  void _reject(MatchRequest request) {
    setState(() => _requests = _requests.where((r) => r.id != request.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rejected. Refund toast delivered to joiner.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests'), backgroundColor: Colors.white),
      backgroundColor: const Color(0xFFF8F9FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              border: Border.all(color: Colors.yellow[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Review requests within 5 minutes. Expired requests auto-refund (UI state).',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          if (_requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Text('No pending requests.'),
            ),
          ..._requests.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.yellow[100],
                    child: Text(r.avatar),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('Level ${r.level}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => RequestBottomSheet(
                        request: r,
                        onAccept: () => _accept(r),
                        onReject: () => _reject(r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

