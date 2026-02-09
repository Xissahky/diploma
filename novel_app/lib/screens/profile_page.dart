import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../api/user_api.dart';
import '../storage/auth_storage.dart';
import '../screens/root_screen.dart';

import './profile_page/profile_achievements_section.dart';
import './profile_page/profile_library_section.dart';
import './profile_page/profile_info_section.dart';
import '../settings/settings_controller.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final int? initialTab;
  final SettingsController settings;

  const ProfilePage({
    super.key,
    this.initialTab,
    required this.settings,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? user;
  bool loading = true;
  String? error;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTab != null &&
              widget.initialTab! >= 0 &&
              widget.initialTab! < 3)
          ? widget.initialTab!
          : 0,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await UserApi.getProfile();
      setState(() {
        user = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final s = AppLocalizations.of(context)!;

    await AuthStorage.clearToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.loggedOut)));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RootScreen(settings: widget.settings),
      ),
      (route) => false,
    );
  }

  Future<String?> _uploadImage(File file) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('http://10.0.2.2:3000/uploads');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['url'];
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }

  void _editProfile() {
    final s = AppLocalizations.of(context)!;

    final nameController =
        TextEditingController(text: user?['displayName'] ?? '');
    final bioController = TextEditingController(text: user?['bio'] ?? '');
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.editProfileTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration:
                      InputDecoration(labelText: s.displayNameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(labelText: s.bioLabel),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                selectedImage != null
                    ? Image.file(selectedImage!, height: 100)
                    : user?['avatarUrl'] != null
                        ? Image.network(user!['avatarUrl'], height: 100)
                        : const Icon(Icons.person, size: 80),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery);
                    if (picked != null) {
                      setStateModal(() => selectedImage = File(picked.path));
                    }
                  },
                  icon: const Icon(Icons.photo),
                  label: Text(s.uploadAvatar),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    String? avatarUrl = user?['avatarUrl'];
                    if (selectedImage != null) {
                      avatarUrl = await _uploadImage(selectedImage!);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    final updated = await UserApi.updateProfile(
                      name: nameController.text.trim(),
                      avatarUrl: avatarUrl,
                      bio: bioController.text.trim(),
                    );
                    setState(() => user = updated);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.profileUpdated)),
                    );
                  },
                  child: Text(s.saveButton),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $error')),
      );
    }
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(s.noUserData)),
      );
    }

    final name = user!['displayName'] ?? 'Unknown';
    final email = user!['email'] ?? '';
    final avatarUrl = user!['avatarUrl'] ?? '';
    final avatar = avatarUrl.startsWith('http')
        ? avatarUrl
        : 'http://10.0.2.2:3000$avatarUrl';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.tabLibrary),
            Tab(text: s.tabInfo),
            Tab(text: s.tabAchievements),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ProfileLibrarySection(),
          ProfileInfoSection(
            name: name,
            email: email,
            avatar: avatar,
            onEdit: _editProfile,
            onLogout: _logout,
            settings: widget.settings,
          ),
          const ProfileAchievementsSection(),
        ],
      ),
    );
  }
}
