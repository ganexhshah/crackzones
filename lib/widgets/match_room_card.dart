import 'package:flutter/material.dart';

class MatchRoomCard extends StatelessWidget {
  final String title;
  final String mode;
  final String opponent;
  final String entryFee;
  final String winning;
  final String status;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;

  const MatchRoomCard({
    super.key,
    required this.title,
    required this.mode,
    required this.opponent,
    required this.entryFee,
    required this.winning,
    required this.status,
    this.actionLabel,
    this.onActionTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow[600]!, Colors.yellow[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_esports, color: Colors.yellow[700], size: isCompact ? 20 : 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      mode,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 12,
                  vertical: isCompact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'RESOLVED' 
                      ? Colors.green[50] 
                      : status == 'ACTIVE'
                          ? Colors.orange[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                    color: status == 'RESOLVED' 
                        ? Colors.green[700] 
                        : status == 'ACTIVE'
                            ? Colors.orange[700]
                            : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, 'Opponent:', opponent, Colors.grey, isCompact),
          SizedBox(height: 8),
          _buildInfoRow(Icons.attach_money, 'Entry Fee:', entryFee, Colors.orange, isCompact),
          SizedBox(height: 8),
          _buildInfoRow(Icons.emoji_events, 'Winning:', winning, Colors.green, isCompact),
          if (actionLabel != null) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onActionTap == null
                      ? Colors.grey[300]
                      : Colors.yellow[700],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, MaterialColor color, bool isCompact) {
    return Row(
      children: [
        Icon(icon, size: isCompact ? 16 : 18, color: color[600]),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: isCompact ? 12 : 13, color: Colors.grey[600]),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            fontWeight: FontWeight.bold,
            color: color[700],
          ),
        ),
      ],
    );
  }
}
