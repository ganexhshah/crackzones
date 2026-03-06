import 'package:flutter/material.dart';

class MatchRulesScreen extends StatefulWidget {
  final String actionType; // 'create' or 'join'
  
  const MatchRulesScreen({
    super.key,
    required this.actionType,
  });

  @override
  State<MatchRulesScreen> createState() => _MatchRulesScreenState();
}

class _MatchRulesScreenState extends State<MatchRulesScreen> {
  bool _agreedToRules = false;
  bool _isNepali = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(_isNepali ? 'निष्पक्ष खेल र नियमहरू' : 'Fair Play & Match Rules'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isNepali ? Colors.yellow[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇳🇵',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isNepali ? 'EN' : 'NP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isNepali ? Colors.orange[800] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                _isNepali = !_isNepali;
              });
            },
            tooltip: _isNepali ? 'Switch to English' : 'नेपालीमा स्विच गर्नुहोस्',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildRuleCard(
                  number: '1',
                  icon: Icons.phone_android,
                  iconColor: Colors.blue,
                  title: _isNepali ? 'उपकरण नियम' : 'Device Rule',
                  rules: _isNepali
                      ? [
                          'खेलहरू मोबाइल उपकरणहरूमा मात्र खेल्नुपर्छ।',
                          'PC इमुलेटरहरू (Bluestacks, Gameloop, आदि) कडाइका साथ निषेधित छन्।',
                          'यदि कुनै खेलाडीले इमुलेटर प्रयोग गरेको पाइयो भने, खेलाडीलाई तुरुन्त अयोग्य घोषित गरिनेछ।',
                        ]
                      : [
                          'Matches must be played only on mobile devices.',
                          'PC emulators (Bluestacks, Gameloop, etc.) are strictly prohibited.',
                          'If a player is found using an emulator, the player will be disqualified immediately.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '2',
                  icon: Icons.block,
                  iconColor: Colors.red,
                  title: _isNepali ? 'ह्याक वा चीट निषेध' : 'No Hacks or Cheats',
                  rules: _isNepali
                      ? [
                          'खेलाडीहरूलाई निम्न प्रयोग गर्न कडाइका साथ निषेध गरिएको छ:',
                          '  • Aimbot',
                          '  • Wallhack',
                          '  • Auto Headshot उपकरणहरू',
                          '  • Speed hacks',
                          '  • परिमार्जित खेल फाइलहरू / mod APK',
                          '',
                          'उल्लङ्घनले निम्न परिणाम दिनेछ:',
                          '  • तुरुन्त खेल हार',
                          '  • स्थायी खाता निलम्बन',
                        ]
                      : [
                          'Players are strictly prohibited from using:',
                          '  • Aimbot',
                          '  • Wallhack',
                          '  • Auto Headshot tools',
                          '  • Speed hacks',
                          '  • Modified game files / mod APK',
                          '',
                          'Violation will result in:',
                          '  • Immediate match loss',
                          '  • Permanent account suspension',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '3',
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orange,
                  title: _isNepali ? 'प्यानल वा तेस्रो-पक्ष उपकरण निषेध' : 'No Panel or Third-Party Tools',
                  rules: _isNepali
                      ? [
                          'खेलाडीहरूले प्रयोग गर्नु हुँदैन:',
                          '  • Headshot panels',
                          '  • Mod menus',
                          '  • Script injectors',
                          '  • तेस्रो-पक्ष चीट उपकरणहरू',
                          '',
                          'यी मध्ये कुनै पनि उपकरण प्रयोग गर्दा खेल रद्द र खाता प्रतिबन्ध हुनेछ।',
                        ]
                      : [
                          'Players must not use:',
                          '  • Headshot panels',
                          '  • Mod menus',
                          '  • Script injectors',
                          '  • Third-party cheat tools',
                          '',
                          'Using any of these tools will lead to match cancellation and account ban.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '4',
                  icon: Icons.settings,
                  iconColor: Colors.purple,
                  title: _isNepali ? 'खेल सेटिङ्ग सम्मान गर्नुहोस्' : 'Respect Match Settings',
                  rules: _isNepali
                      ? [
                          'खेलाडीहरूले खेल सिर्जनाकर्ताद्वारा बनाइएको कस्टम कोठा सेटिङहरू पालना गर्नुपर्छ:',
                          '  • क्यारेक्टर स्किल नियमहरू',
                          '  • हतियार प्रतिबन्धहरू',
                          '  • फ्याँक्न सकिने सीमाहरू',
                          '  • हेडशट मोड वा अन्य विशेष सेटिङहरू',
                          '',
                          'कोठा नियमहरू तोड्दा खेल हार हुन सक्छ।',
                        ]
                      : [
                          'Players must follow the custom room settings created by the match creator:',
                          '  • Character skill rules',
                          '  • Weapon restrictions',
                          '  • Throwable limits',
                          '  • Headshot mode or other special settings',
                          '',
                          'Breaking room rules may result in match forfeiture.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '5',
                  icon: Icons.camera_alt,
                  iconColor: Colors.green,
                  title: _isNepali ? 'स्क्रिनशट प्रमाण' : 'Screenshot Proof',
                  rules: _isNepali
                      ? [
                          'खेल समाप्त भएपछि:',
                          '  • खेलाडीहरूले परिणाम स्क्रिनको स्पष्ट स्क्रिनशट पेश गर्नुपर्छ।',
                          '  • स्क्रिनशटमा खेलाडीको नाम र खेल परिणाम देखिनुपर्छ।',
                          '',
                          'नक्कली वा सम्पादित स्क्रिनशटले खाता निलम्बन निम्त्याउनेछ।',
                        ]
                      : [
                          'After the match ends:',
                          '  • Players must submit a clear screenshot of the result screen.',
                          '  • The screenshot must show player name and match result.',
                          '',
                          'Fake or edited screenshots will lead to account suspension.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '6',
                  icon: Icons.wifi_off,
                  iconColor: Colors.grey,
                  title: _isNepali ? 'विच्छेदन नियम' : 'Disconnection Rule',
                  rules: _isNepali
                      ? [
                          'यदि कुनै खेलाडी इन्टरनेट समस्याका कारण विच्छेद भयो भने, खेल सामान्य रूपमा जारी रहनेछ।',
                          'विपक्षीलाई विजेता घोषित गर्न सकिन्छ जबसम्म दुवै खेलाडीहरू पुन: खेल्न सहमत हुँदैनन्।',
                        ]
                      : [
                          'If a player disconnects due to internet issues, the match will continue normally.',
                          'The opponent may be declared the winner unless both players agree to a rematch.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '7',
                  icon: Icons.gavel,
                  iconColor: Colors.indigo,
                  title: _isNepali ? 'विवाद समाधान' : 'Dispute Handling',
                  rules: _isNepali
                      ? [
                          'यदि दुवै खेलाडीहरूले फरक परिणाम दाबी गर्छन्:',
                          '  • दुवै खेलाडीहरूले खेल स्क्रिनशटहरू अपलोड गर्नुपर्छ।',
                          '  • प्रणाली वा प्रशासकले प्रमाण समीक्षा गर्नेछ।',
                          '  • प्रशासकको निर्णय अन्तिम हुनेछ।',
                        ]
                      : [
                          'If both players claim different results:',
                          '  • Both players must upload match screenshots.',
                          '  • The system or admin will review the evidence.',
                          '  • Admin decision will be final.',
                        ],
                ),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: '8',
                  icon: Icons.handshake,
                  iconColor: Colors.teal,
                  title: _isNepali ? 'निष्पक्ष खेल र आचरण' : 'Fair Play & Conduct',
                  rules: _isNepali
                      ? [
                          'खेलाडीहरूले सम्मानजनक व्यवहार कायम राख्नुपर्छ।',
                          '',
                          'निम्न कार्यहरू निषेधित छन्:',
                          '  • उत्पीडन वा अपमानजनक भाषा',
                          '  • खेल बगहरूको दुरुपयोग',
                          '  • अन्य खेलाडीहरूसँग मिलीभगत',
                          '',
                          'उल्लङ्घनले चेतावनी, खेल हार, वा खाता निलम्बन निम्त्याउन सक्छ।',
                        ]
                      : [
                          'Players must maintain respectful behavior.',
                          '',
                          'The following actions are prohibited:',
                          '  • Harassment or abusive language',
                          '  • Exploiting game bugs',
                          '  • Collusion with other players',
                          '',
                          'Violations may lead to warnings, match loss, or account suspension.',
                        ],
                ),
                const SizedBox(height: 16),
                _buildAgreementCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[700]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isNepali ? 'निष्पक्ष खेल र म्याच नियमहरू' : 'Fair Play & Match Rules',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isNepali
                ? 'कृपया म्याच ${widget.actionType == 'create' ? 'सिर्जना' : 'सामेल'} गर्नु अघि यी नियमहरू पढ्नुहोस् र स्वीकार गर्नुहोस्'
                : 'Please read and accept these rules before ${widget.actionType == 'create' ? 'creating' : 'joining'} a match',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String number,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> rules,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          number,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rules.map((rule) {
                final isSubPoint = rule.startsWith('  •');
                final isEmpty = rule.trim().isEmpty;
                
                if (isEmpty) {
                  return const SizedBox(height: 8);
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSubPoint && rule.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 10),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          rule,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.6,
                            fontWeight: isSubPoint ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _isNepali ? 'खेलाडी सम्झौता' : 'Player Agreement',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _isNepali
                ? 'म्याच ${widget.actionType == 'create' ? 'सिर्जना' : 'सामेल'} गर्नु अघि, तपाईंले सहमत हुनुपर्छ:'
                : 'Before ${widget.actionType == 'create' ? 'creating' : 'joining'} a match, you must agree:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              setState(() {
                _agreedToRules = !_agreedToRules;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _agreedToRules ? Colors.green[600]! : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: _agreedToRules
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _agreedToRules ? Icons.check_box : Icons.check_box_outline_blank,
                    color: _agreedToRules ? Colors.green[600] : Colors.grey[400],
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isNepali
                          ? 'म सबै निष्पक्ष खेल नियमहरू पालना गर्न र प्रशासकको निर्णय स्वीकार गर्न सहमत छु।'
                          : 'I agree to follow all fair play rules and accept admin decisions.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _agreedToRules
              ? () {
                  Navigator.pop(context, true);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            foregroundColor: Colors.black87,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: _agreedToRules ? 2 : 0,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_agreedToRules)
                const Icon(Icons.check_circle, size: 22),
              if (_agreedToRules) const SizedBox(width: 10),
              Text(
                _agreedToRules
                    ? _isNepali
                        ? 'म सहमत छु - ${widget.actionType == 'create' ? 'म्याच सिर्जना गर्नुहोस्' : 'म्याचमा सामेल हुनुहोस्'}'
                        : 'I Agree - Continue to ${widget.actionType == 'create' ? 'Create' : 'Join'} Match'
                    : _isNepali
                        ? 'जारी राख्न कृपया नियमहरू स्वीकार गर्नुहोस्'
                        : 'Please Accept Rules to Continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

