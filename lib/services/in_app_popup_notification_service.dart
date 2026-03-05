import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class InAppPopupNotificationService {
  InAppPopupNotificationService._();

  static final InAppPopupNotificationService instance =
      InAppPopupNotificationService._();

  bool _isShowing = false;

  Future<void> showLatestPopupIfNeeded(BuildContext context) async {
    if (_isShowing) return;

    final response = await ApiService.getBroadcastNotifications();
    final list = (response['notifications'] is List)
        ? (response['notifications'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? latestPopup;
    for (final item in list) {
      final type = (item['type'] ?? '').toString().toUpperCase();
      final showAsPopup = item['showAsPopup'] == true || type == 'POPUP';
      if (!showAsPopup) continue;
      latestPopup = item;
      break;
    }
    if (latestPopup == null) return;

    final broadcastId = (latestPopup['id'] ?? '').toString();
    if (broadcastId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('popup_dismissed_local_$broadcastId') == true) {
      return;
    }

    final allowDontShowAgain = latestPopup['allowDontShowAgain'] != false;
    final title = (latestPopup['title'] ?? '').toString();
    final message = (latestPopup['message'] ?? '').toString();
    final imageUrl = (latestPopup['bannerImageUrl'] ?? '').toString();

    if (!context.mounted) return;
    _isShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool dontShowAgain = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            title: Text(title.isEmpty ? 'Notice' : title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageUrl.isNotEmpty) const SizedBox(height: 10),
                  Text(
                    message.isEmpty ? 'New update is available.' : message,
                  ),
                  if (allowDontShowAgain) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: dontShowAgain,
                          onChanged: (value) {
                            setState(() => dontShowAgain = value == true);
                          },
                        ),
                        const Expanded(child: Text("Don't show again")),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (allowDontShowAgain && dontShowAgain) {
                    await prefs.setBool('popup_dismissed_local_$broadcastId', true);
                    await ApiService.dismissBroadcastPopup(broadcastId);
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
    _isShowing = false;
  }
}
