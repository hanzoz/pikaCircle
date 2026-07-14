import 'package:flutter/material.dart';

class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({
    required this.title,
    required this.excerpt,
    required this.sessionTypeLabel,
    required this.skillLevelLabel,
    required this.rosterLabel,
    this.locationLine,
    this.durationLabel,
    super.key,
  });

  final String title;
  final String excerpt;
  final String sessionTypeLabel;
  final String skillLevelLabel;
  final String rosterLabel;
  final String? locationLine;
  final String? durationLabel;

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
          _SessionInfoCardHeader(
            sessionTypeLabel: sessionTypeLabel,
            skillLevelLabel: skillLevelLabel,
          ),
          const SizedBox(height: 16),
          _SessionInfoCardTitle(title: title),
          if (locationLine != null) ...[
            const SizedBox(height: 10),
            _SessionInfoCardLocation(locationLine: locationLine!),
          ],
          const SizedBox(height: 14),
          _SessionInfoCardDescription(excerpt: excerpt),
          const SizedBox(height: 16),
          _SessionInfoCardFooter(
            rosterLabel: rosterLabel,
            durationLabel: durationLabel,
          ),
        ],
      ),
    );
  }
}

class _SessionInfoCardHeader extends StatelessWidget {
  const _SessionInfoCardHeader({
    required this.sessionTypeLabel,
    required this.skillLevelLabel,
  });

  final String sessionTypeLabel;
  final String skillLevelLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SessionStatusChip(
          label: sessionTypeLabel,
          icon: Icons.sports_tennis_rounded,
          foregroundColor: colorScheme.tertiary,
          backgroundColor: colorScheme.tertiaryContainer,
        ),
        _SessionStatusChip(
          label: skillLevelLabel,
          icon: Icons.bolt_rounded,
          foregroundColor: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer,
        ),
      ],
    );
  }
}

class _SessionInfoCardTitle extends StatelessWidget {
  const _SessionInfoCardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SessionInfoCardLocation extends StatelessWidget {
  const _SessionInfoCardLocation({required this.locationLine});

  final String locationLine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            locationLine,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionInfoCardDescription extends StatelessWidget {
  const _SessionInfoCardDescription({required this.excerpt});

  final String excerpt;

  @override
  Widget build(BuildContext context) {
    return Text(
      excerpt,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
    );
  }
}

class _SessionInfoCardFooter extends StatelessWidget {
  const _SessionInfoCardFooter({
    required this.rosterLabel,
    required this.durationLabel,
  });

  final String rosterLabel;
  final String? durationLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _SessionMetaLabel(icon: Icons.group_outlined, label: rosterLabel),
        if (durationLabel != null)
          _SessionMetaLabel(
            icon: Icons.timelapse_rounded,
            label: durationLabel!,
          ),
      ],
    );
  }
}

class _SessionStatusChip extends StatelessWidget {
  const _SessionStatusChip({
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

class _SessionMetaLabel extends StatelessWidget {
  const _SessionMetaLabel({required this.icon, required this.label});

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
