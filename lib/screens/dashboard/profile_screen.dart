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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return Center(
            child: SingleChildScrollView(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(horizontal: 48, vertical: 48)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 480),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile info
                          Expanded(
                            flex: 2,
                            child: Container(
                              margin: const EdgeInsets.only(right: 32),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      Tooltip(
                                        message: user?.photoURL == null ? 'Default profile icon' : 'Profile photo',
                                        child: CircleAvatar(
                                          radius: 64,
                                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                                          child: user?.photoURL == null ? const Icon(Icons.person, size: 64) : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Tooltip(
                                          message: 'Change profile photo',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(18),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Change profile photo'),
                                                    content: const Text('This feature is coming soon!'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                backgroundColor: theme.colorScheme.primary,
                                                radius: 22,
                                                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    user?.displayName ?? 'Anonymous User',
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Settings
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Card(
                                  elevation: 0,
                                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: const _SettingsSection(
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 0,
                                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: _SettingsSection(
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 0,
                                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: const _SettingsSection(
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Tooltip(
                                    message: user?.photoURL == null ? 'Default profile icon' : 'Profile photo',
                                    child: CircleAvatar(
                                      radius: 54,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                                      child: user?.photoURL == null ? const Icon(Icons.person, size: 54) : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Tooltip(
                                      message: 'Change profile photo',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(18),
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Change profile photo'),
                                                content: const Text('This feature is coming soon!'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: theme.colorScheme.primary,
                                            radius: 20,
                                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                          ),
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
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              user?.email ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Card(
                              elevation: 0,
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: const _SettingsSection(
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
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: _SettingsSection(
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
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: const _SettingsSection(
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
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: const Text('This feature is coming soon!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}