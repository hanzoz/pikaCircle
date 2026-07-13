import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:pikacircle/app/router/routes.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/shared/widgets/placeholder_page.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<PackageInfo> _packageInfoFuture;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _openPlaceholder({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PlaceholderPage(title: title, message: message, icon: icon),
      ),
    );
  }

  Future<void> _logOut() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);
    final failure = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;

    setState(() => _loggingOut = false);
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }

    context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final packageInfo = snapshot.data;
                final appVersion = packageInfo == null
                    ? 'Loading version...'
                    : '${packageInfo.version}+${packageInfo.buildNumber}';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PikaAppBar(leading: PikaAppBarLeading.back, initials: 'P'),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9FA),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFF0F1F5),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 28,
                                    offset: Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settings',
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: const Color(0xFF1D2230),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Manage your account, app behavior, and saved places.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF6F7482),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: const Color(0xFFF0F1F5),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _SettingsMenuTile(
                                          icon:
                                              CupertinoIcons.person_alt_circle,
                                          title: 'Edit Profile',
                                          subtitle:
                                              'Update your name, username, and avatar.',
                                          onTap: () => _openPlaceholder(
                                            title: 'Edit Profile',
                                            message:
                                                'Profile editing will be available here.',
                                            icon: CupertinoIcons
                                                .person_crop_circle,
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFEBEDF2),
                                        ),
                                        _SettingsMenuTile(
                                          icon: CupertinoIcons
                                              .slider_horizontal_3,
                                          title: 'Preferences',
                                          subtitle:
                                              'Notification and app preferences.',
                                          onTap: () => _openPlaceholder(
                                            title: 'Preferences',
                                            message:
                                                'App preferences will live here.',
                                            icon: CupertinoIcons.gear,
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFEBEDF2),
                                        ),
                                        _SettingsMenuTile(
                                          icon: CupertinoIcons.location,
                                          title: 'Locations',
                                          subtitle:
                                              'Saved courts, venues, and nearby places.',
                                          onTap: () => _openPlaceholder(
                                            title: 'Locations',
                                            message:
                                                'Saved locations will be managed here.',
                                            icon: CupertinoIcons.location_solid,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9FA),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFF0F1F5),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: _loggingOut ? null : _logOut,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFE8E8),
                                            borderRadius: BorderRadius.circular(
                                              19,
                                            ),
                                          ),
                                          child: _loggingOut
                                              ? const Padding(
                                                  padding: EdgeInsets.all(9),
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFFCC3D3D)),
                                                  ),
                                                )
                                              : const Icon(
                                                  CupertinoIcons
                                                      .square_arrow_right,
                                                  color: Color(0xFFCC3D3D),
                                                  size: 18,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Log Out',
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFFCC3D3D,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        const Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 17,
                                          color: Color(0xFFCC3D3D),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9FA),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFF0F1F5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF23262D),
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'App Version',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFF1D2230),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appVersion,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: const Color(0xFF6F7482),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF262B37)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF202532),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6F7482),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 17,
              color: Color(0xFF202532),
            ),
          ],
        ),
      ),
    );
  }
}
