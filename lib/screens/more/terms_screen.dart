import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isNepali = false;

  @override
  Widget build(BuildContext context) {
    final terms = _isNepali ? _nepaliTerms : _englishTerms;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isNepali ? 'नियम तथा सर्तहरू' : 'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isNepali
                          ? 'अन्तिम अपडेट: February 28, 2026'
                          : 'Last updated: February 28, 2026',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ...terms.map(
                      (item) => _buildSection(item['title']!, item['content']!),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isNepali ? 'नियम तथा सर्तहरू' : 'Terms & Conditions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ),
          IconButton(
            tooltip: _isNepali ? 'Switch to English' : 'नेपालीमा हेर्नुहोस्',
            onPressed: () => setState(() => _isNepali = !_isNepali),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: Text(
                _isNepali ? 'EN' : 'ने',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
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

final List<Map<String, String>> _englishTerms = [
  {
    'title': '1. Introduction',
    'content':
        'Welcome to CrackZone Esports, operated by CrackZoneEsports Private Ltd., a company registered under the laws of Nepal. This platform provides skill-based esports competitions for players of Garena Free Fire. By creating an account or using our services, you agree to be legally bound by these Terms & Conditions under Nepal law. If you do not agree, please do not use the platform.',
  },
  {
    'title': '2. Nature of Service (Skill-Based Competition)',
    'content':
        'CrackZone Esports provides skill-based competitive tournaments. Tournament results depend on player skill, strategy, and performance. The platform does NOT offer gambling, betting, or games of chance. Entry fees are participation fees, not wagers.',
  },
  {
    'title': '3. Eligibility',
    'content':
        'Users must be at least 16 years old for free tournaments and 18 years old for paid tournaments. Users must comply with all applicable Nepal laws. Fake accounts are strictly prohibited.',
  },
  {
    'title': '4. Account Registration',
    'content':
        'Users must provide accurate and truthful information. Only one account per user is allowed. Users are responsible for maintaining account security. The Company reserves the right to suspend suspicious accounts.',
  },
  {
    'title': '5. Tournament Rules',
    'content':
        'Players must follow official game rules. Use of hacks, cheats, scripts, emulators (if restricted), or unfair tools is strictly prohibited. The platform is not affiliated with Garena unless officially declared. Violation may result in immediate disqualification, prize cancellation, and permanent ban.',
  },
  {
    'title': '6. Server Downtime & 24/7 Support',
    'content':
        'In case of server failure or technical issues, the team will provide 24/7 support. Tournaments may be paused, rescheduled, or cancelled if required. Refund decisions due to technical failure shall be at Company discretion.',
  },
  {
    'title': '7. Payments & Wallet Policy',
    'content':
        'Deposits are required before joining paid tournaments. Minimum deposit: NPR 50. Maximum deposit per day: NPR 1,000. Deposits are non-transferable. All payments are subject to manual admin verification. Withdrawals may require identity verification. The Company reserves the right to delay or reject suspicious transactions.',
  },
  {
    'title': '8. eSewa & Khalti Payment Terms',
    'content':
        'Payments may be processed via eSewa and Khalti. Users must use their own verified wallet accounts. The Company is not responsible for third-party wallet downtime, payment gateway errors, or user input mistakes. Refunds due to payment gateway errors will be processed after verification.',
  },
  {
    'title': '9. Anti-Money Laundering (AML) Policy',
    'content':
        'To comply with Nepal financial regulations, the Company strictly prohibits money laundering, terrorism financing, fraudulent transactions, and use of stolen payment methods. The Company reserves the right to request KYC (Citizenship/ID verification), freeze suspicious accounts, and report suspicious activity to authorities. Misuse for illegal financial activity will result in immediate permanent ban, forfeiture of funds, and legal action under Nepal law.',
  },
  {
    'title': '10. Improper Behaviour & Strict Action',
    'content':
        'Improper conduct includes abusive or threatening language, cheating or hacking, match fixing, harassment, and fraudulent payment activity. Strict actions may include deduction of wallet balance, temporary suspension, permanent ban, and cancellation of winnings. The Company’s decision shall be final and binding.',
  },
  {
    'title': '11. Refund Policy',
    'content':
        'Entry fees are non-refundable once tournament starts. Refunds may be issued only if tournament is cancelled by the Company or a technical error prevents participation. Refund approval is at Company discretion.',
  },
  {
    'title': '12. Limitation of Liability',
    'content':
        'CrackZoneEsports Private Ltd. shall not be liable for internet connectivity issues, game server crashes, device malfunctions, or third-party service interruptions. Participation is at the user\'s own risk.',
  },
  {
    'title': '13. Company Protection Clause',
    'content':
        'All intellectual property, branding, logo, software, and platform content belong exclusively to CrackZoneEsports Private Ltd. Unauthorized copying, reverse engineering, data scraping, or misuse of platform materials is strictly prohibited. The Company reserves the right to take civil and criminal legal action against violators.',
  },
  {
    'title': '14. Compliance with Nepal Law',
    'content':
        'This agreement shall be governed by Laws of Nepal, Electronic Transactions Act, 2063, Consumer Protection Act of Nepal, and applicable financial and cybercrime regulations. All disputes shall fall under the jurisdiction of courts of Nepal.',
  },
  {
    'title': '15. Termination of Account',
    'content':
        'The Company reserves the right to suspend or permanently terminate accounts, cancel tournaments, and modify or discontinue services without prior notice if terms are violated.',
  },
  {
    'title': '16. Amendments',
    'content':
        'The Company may update these Terms at any time. Continued use of the platform means acceptance of revised Terms.',
  },
  {
    'title': 'Declaration',
    'content':
        'By creating an account, you confirm that you understand this is a skill-based esports platform, you agree to comply with Nepal law, you accept all Terms & Conditions, and you confirm you are legally eligible. All Rights Reserved © CrackZoneEsports Private Ltd.',
  },
];

final List<Map<String, String>> _nepaliTerms = [
  {
    'title': '1. परिचय',
    'content':
        'CrackZone Esports मा स्वागत छ, जुन नेपालको कानुन अनुसार दर्ता भएको CrackZoneEsports Private Ltd. द्वारा सञ्चालन हुन्छ। यो प्लेटफर्म Garena Free Fire खेलाडीहरूका लागि कौशल-आधारित इ-स्पोर्ट्स प्रतियोगिता उपलब्ध गराउँछ। खाता बनाउँदा वा सेवा प्रयोग गर्दा तपाईं नेपाल कानून अन्तर्गत यी नियम तथा सर्तहरूमा कानुनी रूपमा सहमत हुनुहुन्छ। सहमत नभए प्लेटफर्म प्रयोग नगर्नुहोस्।',
  },
  {
    'title': '2. सेवाको प्रकृति (कौशल-आधारित प्रतियोगिता)',
    'content':
        'CrackZone Esports ले कौशल-आधारित प्रतिस्पर्धात्मक टुर्नामेन्ट प्रदान गर्दछ। नतिजा खेलाडीको सीप, रणनीति र प्रदर्शनमा आधारित हुन्छ। यो प्लेटफर्म जुवा, बेटिङ, वा भाग्यमाथि आधारित खेल होइन। Entry fee सहभागिता शुल्क हो, बाजी होइन।',
  },
  {
    'title': '3. योग्यता',
    'content':
        'निःशुल्क टुर्नामेन्टका लागि कम्तीमा १६ वर्ष र सशुल्क टुर्नामेन्टका लागि कम्तीमा १८ वर्ष हुनुपर्छ। प्रयोगकर्ताले नेपालका लागू कानून पालना गर्नुपर्छ। नक्कली खाता कडाइका साथ निषेध छ।',
  },
  {
    'title': '4. खाता दर्ता',
    'content':
        'प्रयोगकर्ताले सही र सत्य जानकारी दिनुपर्छ। प्रति प्रयोगकर्ता एक मात्र खाता अनुमति छ। खाताको सुरक्षा प्रयोगकर्ताकै जिम्मेवारी हो। कम्पनीले शंकास्पद खाता निलम्बन गर्न सक्नेछ।',
  },
  {
    'title': '5. टुर्नामेन्ट नियम',
    'content':
        'खेलाडीले आधिकारिक गेम नियम पालना गर्नुपर्छ। Hack, cheat, script, emulator (निषेध भएको अवस्थामा), वा अन्य अनुचित उपकरण प्रयोग कडाइका साथ निषेध छ। आधिकारिक रूपमा घोषणा नभएसम्म प्लेटफर्म Garena सँग आबद्ध छैन। उल्लंघनमा तुरुन्त अयोग्य, पुरस्कार रद्द, र स्थायी प्रतिबन्ध हुन सक्छ।',
  },
  {
    'title': '6. सर्भर डाउनटाइम र 24/7 सपोर्ट',
    'content':
        'सर्भर फेल वा प्राविधिक समस्या भएमा टिमले 24/7 सपोर्ट दिनेछ। आवश्यक परे टुर्नामेन्ट pause, reschedule, वा cancel हुन सक्छ। प्राविधिक विफलताबाट सम्बन्धित refund कम्पनीको विवेकमा निर्भर हुनेछ।',
  },
  {
    'title': '7. भुक्तानी र वालेट नीति',
    'content':
        'सशुल्क टुर्नामेन्टमा सहभागी हुन deposit आवश्यक छ। न्यूनतम deposit NPR 50 र दैनिक अधिकतम NPR 1,000 हो। Deposit transfer गर्न मिल्दैन। सबै भुक्तानी admin verification पछि मात्र मान्य हुन्छ। Withdrawal मा परिचय प्रमाण मागिन सक्छ। शंकास्पद कारोबार ढिलाइ वा अस्वीकार हुन सक्छ।',
  },
  {
    'title': '8. eSewa र Khalti भुक्तानी सर्त',
    'content':
        'भुक्तानी eSewa वा Khalti बाट हुन सक्छ। प्रयोगकर्ताले आफ्नै verified wallet account प्रयोग गर्नुपर्छ। third-party wallet downtime, payment gateway error, वा user input गल्तीका लागि कम्पनी जिम्मेवार हुने छैन। gateway error सम्बन्धित refund verification पछि मात्र हुनेछ।',
  },
  {
    'title': '9. मनी लाउन्डरिङ विरुद्ध (AML) नीति',
    'content':
        'नेपालका वित्तीय नियम पालना गर्न कम्पनीले money laundering, terrorism financing, fraudulent transactions, र stolen payment method प्रयोगलाई कडाइका साथ निषेध गर्छ। कम्पनीले KYC माग्न, शंकास्पद खाता freeze गर्न, र सम्बन्धित निकायलाई रिपोर्ट गर्न सक्नेछ। गैरकानुनी वित्तीय गतिविधिमा स्थायी प्रतिबन्ध, रकम जफत, र कानुनी कारबाही हुनेछ।',
  },
  {
    'title': '10. अनुचित व्यवहार र कडा कारबाही',
    'content':
        'गालीगलौज, धम्की, cheating, hacking, match fixing, harassment, र fraudulent payment activity अनुचित व्यवहारमा पर्छ। कारबाहीमा wallet कटौती, अस्थायी निलम्बन, स्थायी प्रतिबन्ध, र winnings रद्द हुन सक्छ। कम्पनीको निर्णय अन्तिम र बाध्यकारी हुनेछ।',
  },
  {
    'title': '11. Refund नीति',
    'content':
        'टुर्नामेन्ट सुरु भएपछि entry fee refundable हुँदैन। टुर्नामेन्ट कम्पनीले cancel गरेको वा प्राविधिक त्रुटिका कारण सहभागिता असम्भव भएको अवस्थामा मात्र refund सम्भव हुन सक्छ। Refund स्वीकृति कम्पनीको विवेकमा निर्भर छ।',
  },
  {
    'title': '12. जिम्मेवारीको सीमा',
    'content':
        'Internet समस्या, game server crash, device malfunction, वा third-party service interruption का लागि CrackZoneEsports Private Ltd. जिम्मेवार हुने छैन। सहभागिता प्रयोगकर्ताको आफ्नै जोखिममा हुनेछ।',
  },
  {
    'title': '13. कम्पनी संरक्षण प्रावधान',
    'content':
        'सभी बौद्धिक सम्पत्ति, branding, logo, software, र platform content को एकमात्र स्वामित्व CrackZoneEsports Private Ltd. को हो। अनधिकृत copying, reverse engineering, data scraping, वा दुरुपयोग पूर्ण रूपमा निषेध छ। उल्लंघनकर्तामाथि कम्पनीले दीवानी र फौजदारी दुवै कानुनी कारबाही गर्न सक्नेछ।',
  },
  {
    'title': '14. नेपाल कानूनको अनुपालन',
    'content':
        'यो सम्झौता नेपालका कानून, Electronic Transactions Act, 2063, Consumer Protection Act, र सम्बन्धित वित्तीय तथा साइबर अपराध नियमद्वारा शासित हुनेछ। सबै विवाद नेपालका अदालतको अधिकार क्षेत्रमा पर्छन्।',
  },
  {
    'title': '15. खाता समाप्ति',
    'content':
        'नियम उल्लंघन भए कम्पनीले पूर्वसूचना बिना खाता निलम्बन वा स्थायी रूपमा समाप्त गर्न, टुर्नामेन्ट रद्द गर्न, वा सेवा परिमार्जन/बन्द गर्न सक्नेछ।',
  },
  {
    'title': '16. संशोधन',
    'content':
        'कम्पनीले यी Terms जुनसुकै बेला अपडेट गर्न सक्छ। अपडेटपछि प्लेटफर्मको निरन्तर प्रयोगलाई संशोधित Terms को स्वीकृति मानिनेछ।',
  },
  {
    'title': 'घोषणा',
    'content':
        'खाता सिर्जना गरेर तपाईंले यो कौशल-आधारित इ-स्पोर्ट्स प्लेटफर्म हो भन्ने बुझ्नुभएको, नेपाल कानून पालना गर्ने, सबै Terms स्वीकार गर्ने, र कानुनी रूपमा योग्य हुनुहुन्छ भन्ने पुष्टि गर्नुहुन्छ। All Rights Reserved © CrackZoneEsports Private Ltd.',
  },
];
