import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildContactCard(),
                      SizedBox(height: 24),
                      _buildFAQSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'Help & Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[100]!, Colors.yellow[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 60, color: Colors.yellow[700]),
          SizedBox(height: 16),
          Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Our support team is here to help you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(Icons.email, 'Email', Colors.blue),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(Icons.chat, 'Chat', Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        SizedBox(height: 16),
        _buildFAQItem('How do I add money to my wallet?', 'Go to Wallet section and click on Add Money button...'),
        _buildFAQItem('How do I withdraw money?', 'Navigate to Wallet and click Withdraw button...'),
        _buildFAQItem('How do I join a tournament?', 'Go to Tournaments tab and select the tournament...'),
        _buildFAQItem('What payment methods are supported?', 'We support eSewa, Khalti, and bank transfers...'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
