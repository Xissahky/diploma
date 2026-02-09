import 'package:flutter/material.dart';

import '../widgets/custom_bottom_nav_bar.dart';
import 'main_screen.dart';
import 'search.dart';
import 'new_chapter_page.dart';
import 'notifications.dart';
import 'profile_page.dart';
import '../storage/auth_storage.dart';
import '../api/user_api.dart';
import '../settings/settings_controller.dart';

class RootScreen extends StatefulWidget {
  final SettingsController settings;

  const RootScreen({
    super.key,
    required this.settings,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? user;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final hasToken = await AuthStorage.hasToken();
    if (!hasToken) {
      setState(() {
        _loadingUser = false;
        user = null;
      });
      return;
    }

    try {
      final data = await UserApi.getProfile();
      setState(() {
        user = data;
        _loadingUser = false;
      });
    } catch (e) {
      setState(() {
        user = null;
        _loadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user != null && user!['avatarUrl'] != null
        ? (user!['avatarUrl'].toString().startsWith('http')
            ? user!['avatarUrl']
            : 'http://10.0.2.2:3000${user!['avatarUrl']}')
        : 'https://placehold.co/32x32';

    final pages = [
      const MainScreen(),
      const SearchPage(),
      const NewContentPage(),
      NotificationsPage(settings: widget.settings),
      ProfilePage(
        initialTab: 1,
        settings: widget.settings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel-App'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (user == null) {
                  Navigator.pushNamed(context, '/signin');
                } else {
                  setState(() => _currentIndex = 4);
                }
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatarUrl),
              ),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          const restrictedTabs = [2, 3, 4]; // Add, Notifications, Profile
          final loggedIn = await AuthStorage.hasToken();

          if (restrictedTabs.contains(index) && !loggedIn) {
            if (context.mounted) {
              Navigator.pushNamed(context, '/signin');
            }
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
