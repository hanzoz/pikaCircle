import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _locationServices = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 44),
        child: const PikaAppBar(leading: PikaAppBarLeading.back, initials: 'P'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preferences',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2230),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize your app experience',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F7482),
                ),
              ),
              const SizedBox(height: 20),
              // Notifications Section
              _SectionCard(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    'All Notifications',
                    'Receive all notification types',
                    _notificationsEnabled,
                    (value) => setState(() => _notificationsEnabled = value),
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Get updates via email',
                    _emailNotifications,
                    (value) => setState(() => _emailNotifications = value),
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSwitchTile(
                    'Push Notifications',
                    'Get in-app alerts',
                    _pushNotifications,
                    (value) => setState(() => _pushNotifications = value),
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSwitchTile(
                    'SMS Notifications',
                    'Get text message updates',
                    _smsNotifications,
                    (value) => setState(() => _smsNotifications = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Privacy Section
              _SectionCard(
                title: 'Privacy & Data',
                children: [
                  _buildSwitchTile(
                    'Location Services',
                    'Allow app to access your location',
                    _locationServices,
                    (value) => setState(() => _locationServices = value),
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSettingsTile(
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy practices',
                    onTap: () {},
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSettingsTile(
                    title: 'Terms of Service',
                    subtitle: 'Review terms and conditions',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Appearance Section
              _SectionCard(
                title: 'Appearance',
                children: [
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use dark theme',
                    _darkMode,
                    (value) => setState(() => _darkMode = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Account Settings Section
              _SectionCard(
                title: 'Account',
                children: [
                  _buildSettingsTile(
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {},
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSettingsTile(
                    title: 'Connected Apps',
                    subtitle: 'Manage third-party app access',
                    onTap: () {},
                  ),
                  const Divider(height: 12, color: Color(0xFFF0F1F5)),
                  _buildSettingsTile(
                    title: 'Blocked Users',
                    subtitle: 'Manage your blocked list',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D2230),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7482)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D2230),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6F7482),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFF6F7482),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D2230),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
