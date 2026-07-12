import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Shared building blocks for the onboarding flow.
///
/// These re-skin the reference flow's plain-Material pieces into the app's
/// Liquid Glass language, sourcing every colour and text style from
/// `Theme.of(context)` so they track the brand-blue Material 3 theme rather
/// than inventing their own palette.

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold shell
// ─────────────────────────────────────────────────────────────────────────────

/// A glass scaffold shared by the onboarding sub-steps.
///
/// Mirrors the auth screens: [GlassScaffold] on the surface colour, an optional
/// [GlassAppBar] with a chevron-back [GlassIconButton], and a centred,
/// width-capped scroll body. Passing [onBack] renders the back affordance;
/// omitting it (the landing step) hides the app bar entirely.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.child,
    super.key,
    this.title,
    this.onBack,
    this.backEnabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final bool backEnabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassScaffold(
      backgroundColor: colorScheme.surface,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: onBack == null
          ? null
          : GlassAppBar(
              centerTitle: false,
              leading: GlassIconButton(
                icon: const Icon(CupertinoIcons.chevron_back),
                onPressed: backEnabled ? onBack : null,
                size: 40,
                useOwnLayer: true,
              ),
              title: title == null
                  ? null
                  : Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
      body: SafeArea(
        top: onBack == null,
        child: Center(
          child: SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography helpers
// ─────────────────────────────────────────────────────────────────────────────

/// The screen's leading headline + supporting line, left-aligned to match the
/// auth screens (`headlineSmall` w800 with a touch of negative tracking).
class OnboardingHeading extends StatelessWidget {
  const OnboardingHeading({
    required this.title,
    super.key,
    this.subtitle,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final crossAxis = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

/// The flow's primary call-to-action: a prominent glass button that swaps its
/// label for an [onPrimary]-tinted spinner while [isLoading].
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    required this.label,
    required this.onTap,
    super.key,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = enabled && !isLoading;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: active ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// A secondary, non-prominent glass button used for alternate paths
/// ("I already have an account", "New here?").
class OnboardingSecondaryButton extends StatelessWidget {
  const OnboardingSecondaryButton({
    required this.label,
    required this.onTap,
    super.key,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassButton.custom(
      onTap: enabled ? onTap : () {},
      enabled: enabled,
      height: 54,
      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// A "Continue with Google" glass button.
///
/// There's no brand asset in the app, so it uses a tasteful generic glyph
/// ([Icons.g_mobiledata_rounded]) inside a non-prominent glass button, disabled
/// while [enabled] is false (i.e. while another auth call is in flight).
class OnboardingGoogleButton extends StatelessWidget {
  const OnboardingGoogleButton({
    required this.onTap,
    super.key,
    this.enabled = true,
    this.label = 'Continue with Google',
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassButton.custom(
      onTap: enabled ? onTap : () {},
      enabled: enabled,
      height: 54,
      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.g_mobiledata_rounded,
            size: 28,
            color: colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dividers & inline error
// ─────────────────────────────────────────────────────────────────────────────

/// A centred "or continue with"-style divider that reads as part of the glass
/// surface (hairlines in [outlineVariant], label in [onSurfaceVariant]).
class OnboardingOrDivider extends StatelessWidget {
  const OnboardingOrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final line = colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}

/// An inline validation/error banner tinted from the theme's [error] role.
class OnboardingInlineError extends StatelessWidget {
  const OnboardingInlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            size: 18,
            color: colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress
// ─────────────────────────────────────────────────────────────────────────────

/// A segmented progress bar for the assessment: [total] pills, the first
/// [filled] rendered in [primary], the rest in [outlineVariant].
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.filled,
    required this.total,
    super.key,
  });

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 6,
              decoration: BoxDecoration(
                color: i < filled
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input
// ─────────────────────────────────────────────────────────────────────────────

/// A Material [TextField] styled as a translucent glass well.
///
/// A shared copy of the auth screens' private `_GlassInput`, kept as a Material
/// field (rather than [GlassTextField]) so the flow preserves `autofillHints`,
/// `keyboardType`, `obscureText`, `enabled`, `textCapitalization`, `onChanged`,
/// and `onSubmitted` semantics exactly. The soft fill, borderless rest state,
/// and primary focus ring make it read as part of the surrounding glass card.
class OnboardingGlassInput extends StatelessWidget {
  const OnboardingGlassInput({
    required this.controller,
    required this.enabled,
    super.key,
    this.keyboardType,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
  });

  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(14));

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: colorScheme.onSurface),
      cursorColor: colorScheme.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
