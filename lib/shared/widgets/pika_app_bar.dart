import 'dart:ui';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/profile_avatar.dart';

/// A consistent top app bar used across the app.
///
/// Pass [leading] to control the left button:
/// - [PikaAppBarLeading.back] — chevron back button (e.g. profile page).
/// - [PikaAppBarLeading.profile] — avatar/profile button (e.g. home page).
///
/// The right side always shows a notification bell button.
/// Wrap in a [SafeArea] at the call site or set [safeArea] to true.
class PikaAppBar extends StatelessWidget {
  const PikaAppBar({
    super.key,
    this.leading = PikaAppBarLeading.back,
    this.initials,
    this.avatarUrl,
    this.avatarFileId,
    this.avatarBucketId,
    this.storage,
    this.onSettingsTap,
    this.onNotificationTap,
    this.onLeadingTap,
    this.trailing,
    this.safeArea = true,
  });

  /// Which button to show on the left.
  final PikaAppBarLeading leading;

  /// Initials displayed inside the profile avatar (e.g. "JD").
  /// Only used when [leading] is [PikaAppBarLeading.profile].
  final String? initials;

  /// Profile picture URL displayed for [PikaAppBarLeading.profile] when set.
  final String? avatarUrl;

  /// Optional uploaded file id for authenticated avatar fetching fallback.
  final String? avatarFileId;

  /// Optional avatar bucket id used with [avatarFileId].
  final String? avatarBucketId;

  /// Optional Appwrite storage client used to fetch private avatar bytes.
  final Storage? storage;

  /// Called when the settings button is tapped.
  final VoidCallback? onSettingsTap;

  /// Called when the notification bell is tapped.
  final VoidCallback? onNotificationTap;

  /// Called when the leading button is tapped.
  /// Defaults to [Navigator.maybePop] for [PikaAppBarLeading.back].
  final VoidCallback? onLeadingTap;

  /// Optional custom trailing widget.
  ///
  /// When provided, this replaces the default settings/bell cluster.
  final Widget? trailing;

  /// Wraps the bar in a [SafeArea] (top only). Defaults to true.
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final bar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PikaLeadingButton(
              leading: leading,
              initials: initials,
              avatarUrl: avatarUrl,
              avatarFileId: avatarFileId,
              avatarBucketId: avatarBucketId,
              storage: storage,
              onTap:
                  onLeadingTap ??
                  (leading == PikaAppBarLeading.back
                      ? () => Navigator.of(context).maybePop()
                      : null),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  trailing!
                else ...[
                  if (onSettingsTap != null)
                    PikaNavButton(
                      icon: CupertinoIcons.gear,
                      onTap: onSettingsTap,
                    ),
                  if (onSettingsTap != null) const SizedBox(width: 10),
                  PikaNavButton(
                    icon: CupertinoIcons.bell,
                    onTap: onNotificationTap,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return safeArea ? SafeArea(bottom: false, child: bar) : bar;
  }
}

enum PikaAppBarLeading { back, profile }

// ---------------------------------------------------------------------------

class PikaNavButton extends StatelessWidget {
  const PikaNavButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassPill(
        height: 44,
        width: 44,
        child: Icon(icon, size: 22, color: const Color(0xFF1D2230)),
      ),
    );
  }
}

class PikaLeadingButton extends StatelessWidget {
  const PikaLeadingButton({
    super.key,
    required this.leading,
    required this.initials,
    this.avatarUrl,
    this.avatarFileId,
    this.avatarBucketId,
    this.storage,
    required this.onTap,
  });

  final PikaAppBarLeading leading;
  final String? initials;
  final String? avatarUrl;
  final String? avatarFileId;
  final String? avatarBucketId;
  final Storage? storage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassPill(
        height: 44,
        width: 44,
        child: leading == PikaAppBarLeading.back
            ? const Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: Color(0xFF1D2230),
              )
              : ProfileAvatar(
                initials: initials,
                avatarUrl: avatarUrl,
                avatarFileId: avatarFileId,
                avatarBucketId: avatarBucketId,
                storage: storage,
              ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.height = 44, this.width = 44});

  final Widget child;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

