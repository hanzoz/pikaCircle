import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    this.onNotificationTap,
    this.onLeadingTap,
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

  /// Called when the notification bell is tapped.
  final VoidCallback? onNotificationTap;

  /// Called when the leading button is tapped.
  /// Defaults to [Navigator.maybePop] for [PikaAppBarLeading.back].
  final VoidCallback? onLeadingTap;

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
            PikaNavButton(icon: CupertinoIcons.bell, onTap: onNotificationTap),
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
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
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
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: leading == PikaAppBarLeading.back
            ? const Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: Color(0xFF1D2230),
              )
            : _ProfileAvatar(
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.initials,
    this.avatarUrl,
    this.avatarFileId,
    this.avatarBucketId,
    this.storage,
  });

  final String? initials;
  final String? avatarUrl;
  final String? avatarFileId;
  final String? avatarBucketId;
  final Storage? storage;

  @override
  Widget build(BuildContext context) {
    final label = (initials?.trim().isNotEmpty == true) ? initials! : 'P';
    final resolvedAvatarUrl = avatarUrl?.trim();
    if (resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolvedAvatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _AvatarFromStorageOrFallback(
            avatarFileId: avatarFileId,
            avatarBucketId: avatarBucketId,
            storage: storage,
            label: label,
          ),
        ),
      );
    }

    return _AvatarFromStorageOrFallback(
      avatarFileId: avatarFileId,
      avatarBucketId: avatarBucketId,
      storage: storage,
      label: label,
    );
  }
}

class _AvatarFromStorageOrFallback extends StatelessWidget {
  const _AvatarFromStorageOrFallback({
    required this.avatarFileId,
    required this.avatarBucketId,
    required this.storage,
    required this.label,
  });

  final String? avatarFileId;
  final String? avatarBucketId;
  final Storage? storage;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalizedFileId = avatarFileId?.trim();
    final normalizedBucketId = avatarBucketId?.trim();
    if (normalizedFileId == null ||
        normalizedFileId.isEmpty ||
        normalizedBucketId == null ||
        normalizedBucketId.isEmpty ||
        storage == null) {
      return _InitialsAvatar(label: label);
    }

    return FutureBuilder<Uint8List>(
      future: storage!.getFileView(
        bucketId: normalizedBucketId,
        fileId: normalizedFileId,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _InitialsAvatar(label: label);
        }

        return ClipOval(
          child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFBBCFF1), Color(0xFF96B9E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
