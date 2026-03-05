import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AccountRestrictedScreen extends StatefulWidget {
  final Map<String, dynamic> accountStatus;
  final String? email;

  const AccountRestrictedScreen({
    super.key,
    required this.accountStatus,
    this.email,
  });

  @override
  State<AccountRestrictedScreen> createState() => _AccountRestrictedScreenState();
}

class _AccountRestrictedScreenState extends State<AccountRestrictedScreen> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _requestUnblock() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await ApiService.requestUnblock(
      email: email,
      message: _messageController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'].toString())),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unblock request sent to admin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.accountStatus['status'] ?? 'BLOCKED')
        .toString()
        .toUpperCase();
    final reason = (widget.accountStatus['reason'] ?? 'No reason provided')
        .toString();
    final daysRemaining = widget.accountStatus['daysRemaining'];
    final suspendedUntil =
        (widget.accountStatus['suspendedUntil'] ?? '').toString();
    final canRequestUnblock = widget.accountStatus['canRequestUnblock'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account Status'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status == 'SUSPENDED'
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: status == 'SUSPENDED'
                        ? Colors.orange.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  status == 'SUSPENDED'
                      ? 'Your account is suspended'
                      : 'Your account is blocked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: status == 'SUSPENDED'
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Reason', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Text(reason, style: const TextStyle(fontSize: 16)),
              if (status == 'SUSPENDED' && daysRemaining != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Days remaining: $daysRemaining',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (status == 'SUSPENDED' && suspendedUntil.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Suspended until: $suspendedUntil'),
              ],
              if (canRequestUnblock) ...[
                const SizedBox(height: 22),
                const Text(
                  'Request Unblock',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _requestUnblock,
                    child: Text(
                      _submitting ? 'Submitting...' : 'Send Unblock Request',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
