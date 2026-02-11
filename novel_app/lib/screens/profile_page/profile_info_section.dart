import 'package:flutter/material.dart';

import '../../api/user_api.dart';
import '../../settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';

class ProfileInfoSection extends StatefulWidget {
  final String name;
  final String email;
  final String avatar;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  final SettingsController settings;

  const ProfileInfoSection({
    super.key,
    required this.name,
    required this.email,
    required this.avatar,
    required this.onEdit,
    required this.onLogout,
    required this.settings,
  });

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  late bool darkMode;
  late String languageCode; // 'en' / 'pl'

  @override
  void initState() {
    super.initState();
    darkMode = widget.settings.themeMode == ThemeMode.dark;
    languageCode = widget.settings.locale.languageCode; // 'en' or 'pl'
  }

  Future<void> _changePassword() async {
    final s = AppLocalizations.of(context)!;

    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final repeatCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.changePasswordTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: oldCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.currentPasswordLabel,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? s.enterCurrentPassword : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.newPasswordLabel,
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? s.minPasswordLength : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: repeatCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.repeatNewPasswordLabel,
                ),
                validator: (v) =>
                    (v != newCtrl.text) ? s.passwordsDoNotMatch : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(s.saveButton),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await UserApi.changePassword(
                        oldPassword: oldCtrl.text.trim(),
                        newPassword: newCtrl.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.passwordChanged)),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(widget.avatar),
          ),
          const SizedBox(height: 12),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(widget.email),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(s.editProfileTitle),
            onTap: widget.onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(s.changePasswordTitle),
            onTap: _changePassword,
          ),

          SwitchListTile(
            title: Text(s.darkTheme),
            value: darkMode,
            onChanged: (v) {
              setState(() => darkMode = v);
              widget.settings
                  .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.language),
            trailing: DropdownButton<String>(
              value: languageCode,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(s.english),
                ),
                DropdownMenuItem(
                  value: 'pl',
                  child: Text(s.polish),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => languageCode = v);

                if (v == 'pl') {
                  widget.settings.setLocale(const Locale('pl'));
                } else {
                  widget.settings.setLocale(const Locale('en'));
                }
              },
            ),
          ),

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.onLogout,
            child: Text(s.logOut),
          ),
        ],
      ),
    );
  }
}
