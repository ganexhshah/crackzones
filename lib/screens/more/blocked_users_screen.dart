import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final List<Map<String, String>> _blockedUsers = [
    {'name': 'Player123', 'uid': '987654321', 'date': '2 days ago'},
    {'name': 'GamerPro', 'uid': '876543210', 'date': '1 week ago'},
    {'name': 'NoobMaster', 'uid': '765432109', 'date': '2 weeks ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        return _buildBlockedUserItem(_blockedUsers[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Blocked Users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          Spacer(),
          Text(
            '${_blockedUsers.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserItem(Map<String, String> user, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, color: Colors.grey[600], size: 28),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'UID: ${user['uid']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Blocked ${user['date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Unblock User'),
                  content: Text('Are you sure you want to unblock ${user['name']}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _blockedUsers.removeAt(index);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User unblocked')),
                        );
                      },
                      child: Text('Unblock', style: TextStyle(color: Colors.yellow[700])),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.yellow[700],
              side: BorderSide(color: Colors.yellow[700]!, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No Blocked Users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You haven\'t blocked anyone yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
