import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Last updated: February 26, 2026',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildSection('Information We Collect',
                      'We collect information you provide directly to us, including name, email address, phone number, and gaming profile information.'),
                    _buildSection('How We Use Your Information',
                      'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.'),
                    _buildSection('Information Sharing',
                      'We do not sell your personal information. We may share your information with service providers who assist us in operating our platform.'),
                    _buildSection('Data Security',
                      'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or destruction.'),
                    _buildSection('Your Rights',
                      'You have the right to access, update, or delete your personal information at any time through your account settings.'),
                    _buildSection('Cookies',
                      'We use cookies and similar technologies to enhance your experience and analyze usage patterns.'),
                    _buildSection('Children\'s Privacy',
                      'Our service is not intended for users under 18 years of age. We do not knowingly collect information from children.'),
                    _buildSection('Changes to Privacy Policy',
                      'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.'),
                    _buildSection('Contact Us',
                      'If you have questions about this privacy policy, please contact us at privacy@gamehub.com'),
                  ],
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
            'Privacy Policy',
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

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

