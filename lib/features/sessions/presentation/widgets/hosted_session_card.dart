import 'package:flutter/material.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';

class HostedSessionCard extends StatelessWidget {
  const HostedSessionCard({required this.session});

  final HostedSession session;

  @override
  Widget build(BuildContext context) {
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
          HostedSessionCardHeader(session: session),
          const SizedBox(height: 16),
          HostedSessionCardTitle(session: session),
          if (session.locationLine != null) ...[
            const SizedBox(height: 10),
            HostedSessionCardLocation(session: session),
          ],
          const SizedBox(height: 14),
          HostedSessionCardDescription(session: session),
          const SizedBox(height: 16),
          HostedSessionCardFooter(session: session),
        ],
      ),
    );
  }
}

class HostedSessionCardHeader extends StatelessWidget {
  const HostedSessionCardHeader({required this.session});

  final HostedSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SessionStatusChip(
          label: session.sessionTypeLabel,
          icon: Icons.sports_tennis_rounded,
          foregroundColor: colorScheme.tertiary,
          backgroundColor: colorScheme.tertiaryContainer,
        ),
        SessionStatusChip(
          label: session.skillLevelLabel,
          icon: Icons.bolt_rounded,
          foregroundColor: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer,
        ),
      ],
    );
  }
}

class HostedSessionCardTitle extends StatelessWidget {
  const HostedSessionCardTitle({required this.session});

  final HostedSession session;

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

class HostedSessionCardLocation extends StatelessWidget {
  const HostedSessionCardLocation({required this.session});

  final HostedSession session;

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

class HostedSessionCardDescription extends StatelessWidget {
  const HostedSessionCardDescription({required this.session});

  final HostedSession session;

  @override
  Widget build(BuildContext context) {
    return Text(
      session.excerpt,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
    );
  }
}

class HostedSessionCardFooter extends StatelessWidget {
  const HostedSessionCardFooter({required this.session});

  final HostedSession session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        SessionMetaLabel(
          icon: Icons.group_outlined,
          label: session.rosterLabel,
        ),
        if (session.durationLabel != null)
          SessionMetaLabel(
            icon: Icons.timelapse_rounded,
            label: session.durationLabel!,
          ),
      ],
    );
  }
}

class SessionStatusChip extends StatelessWidget {
  const SessionStatusChip({
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

class SessionMetaLabel extends StatelessWidget {
  const SessionMetaLabel({required this.icon, required this.label});

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
