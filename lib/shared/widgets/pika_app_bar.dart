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
    this.onNotificationTap,
    this.onLeadingTap,
    this.safeArea = true,
  });

  /// Which button to show on the left.
  final PikaAppBarLeading leading;

  /// Initials displayed inside the profile avatar (e.g. "JD").
  /// Only used when [leading] is [PikaAppBarLeading.profile].
  final String? initials;

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
    required this.onTap,
  });

  final PikaAppBarLeading leading;
  final String? initials;
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
            : _ProfileAvatar(initials: initials),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.initials});

  final String? initials;

  @override
  Widget build(BuildContext context) {
    final label = (initials?.trim().isNotEmpty == true) ? initials! : 'P';
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
