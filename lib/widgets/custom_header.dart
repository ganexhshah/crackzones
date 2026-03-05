import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/more/edit_profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/gift/gift_screen.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final profile = userProvider.profile;
            final name = profile?['name'] ?? 'User';
            final avatar = profile?['avatar'];

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.yellow[100],
                    backgroundImage: avatar != null
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null
                        ? Icon(
                            Icons.person,
                            color: Colors.yellow[700],
                            size: 24,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hi, $name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.grey[600], size: 24),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.card_giftcard,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GiftScreen(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
