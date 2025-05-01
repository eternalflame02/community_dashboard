import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                Tooltip(
                  message: user?.photoURL == null ? 'Default profile icon' : 'Profile photo',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Tooltip(
                    message: 'Change profile photo',
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        color: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          // TODO: Implement photo upload
                          // You can use ImagePicker or similar package to allow users to select and upload a photo.
                          // Example: Use ImagePicker.pickImage and upload to your backend or Firebase Storage.
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.displayName ?? 'Anonymous User',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _SettingsSection(
            title: 'Account Settings',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
              ),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Location Settings',
              ),
            ],
          ),
          const Divider(height: 32),
          _SettingsSection(
            title: 'App Settings',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const _SettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: Text('English'),
              ),
            ],
          ),
          const Divider(height: 32),
          const _SettingsSection(
            title: 'Support',
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Tooltip(
        message: title,
        child: Icon(icon),
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Implement settings navigation
        // You can use Navigator.push to navigate to a settings screen when this is triggered.
      },
    );
  }
}