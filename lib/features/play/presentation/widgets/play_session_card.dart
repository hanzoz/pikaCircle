import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';

class PlaySessionCard extends StatelessWidget {
  const PlaySessionCard({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlaySessionCardHeader(session: session),
          const SizedBox(height: 16),
          PlaySessionCardTitle(session: session),
          if (session.locationLine != null) ...[
            const SizedBox(height: 10),
            PlaySessionCardLocation(session: session),
          ],
          const SizedBox(height: 14),
          PlaySessionCardDescription(session: session),
          const SizedBox(height: 16),
          PlaySessionCardFooter(session: session),
        ],
      ),
    );
  }
}

class PlaySessionCardHeader extends StatelessWidget {
  const PlaySessionCardHeader({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PlayStatusChip(
          label: session.sessionTypeLabel,
          icon: Icons.sports_tennis_rounded,
          foregroundColor: colorScheme.tertiary,
          backgroundColor: colorScheme.tertiaryContainer,
        ),
        PlayStatusChip(
          label: session.skillLevelLabel,
          icon: Icons.bolt_rounded,
          foregroundColor: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer,
        ),
      ],
    );
  }
}

class PlaySessionCardTitle extends StatelessWidget {
  const PlaySessionCardTitle({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    return Text(
      session.title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class PlaySessionCardLocation extends StatelessWidget {
  const PlaySessionCardLocation({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            session.locationLine!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class PlaySessionCardDescription extends StatelessWidget {
  const PlaySessionCardDescription({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    return Text(
      session.excerpt,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
    );
  }
}

class PlaySessionCardFooter extends StatelessWidget {
  const PlaySessionCardFooter({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        PlayMetaLabel(icon: Icons.group_outlined, label: session.rosterLabel),
        if (session.durationLabel != null)
          PlayMetaLabel(
            icon: Icons.timelapse_rounded,
            label: session.durationLabel!,
          ),
      ],
    );
  }
}

class PlayStatusChip extends StatelessWidget {
  const PlayStatusChip({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayMetaLabel extends StatelessWidget {
  const PlayMetaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
