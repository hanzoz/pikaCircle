import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pikacircle/shared/widgets/pika_app_bar.dart';
import 'package:pikacircle/shared/widgets/session_avatar_list.dart';

class SessionDetailsData {
  const SessionDetailsData({
    required this.title,
    required this.description,
    required this.hostName,
    required this.dateLabel,
    required this.timeLabel,
    required this.durationLabel,
    required this.sessionType,
    required this.skillLevel,
    required this.sponsorName,
    required this.venue,
    required this.location,
    required this.creditCost,
    required this.refundAvailable,
    required this.refundWindowLabel,
    required this.confirmedParticipantNames,
    required this.confirmedParticipantCount,
    required this.waitlistedParticipantNames,
    required this.waitlistCount,
    required this.hostSkillLevel,
    required this.hostSkillRating,
  });

  final String title;
  final String description;
  final String hostName;
  final String dateLabel;
  final String timeLabel;
  final String durationLabel;
  final String sessionType;
  final String skillLevel;
  final String sponsorName;
  final String venue;
  final String location;
  final int creditCost;
  final bool refundAvailable;
  final String refundWindowLabel;
  final List<String> confirmedParticipantNames;
  final int confirmedParticipantCount;
  final List<String> waitlistedParticipantNames;
  final int waitlistCount;
  final String hostSkillLevel;
  final double? hostSkillRating;
}

class SessionDetailsPage extends StatelessWidget {
  const SessionDetailsPage({super.key, required this.data});

  final SessionDetailsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final appBarHeight = topInset + 44;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: PikaAppBar(
          leading: PikaAppBarLeading.back,
          initials: 'P',
          trailing: PikaNavButton(
            icon: CupertinoIcons.share,
            onTap: () async {
              final shareText =
                  '${data.title}\n${data.dateLabel} at ${data.timeLabel}\n${data.venue}, ${data.location}';
              await Clipboard.setData(ClipboardData(text: shareText));

              if (!context.mounted) return;

              final snackBar = const SnackBar(
                content: Text('Session details copied for sharing'),
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            },
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, appBarHeight + 8, 16, 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF0F1F5)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      data.title,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D2230),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      data.description,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFCC4A57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    child: Column(
                      children: <Widget>[
                        _DetailItem(label: 'Hosted by', value: data.hostName),
                        _DetailItem(label: 'Date', value: data.dateLabel),
                        _DetailItem(label: 'Time', value: data.timeLabel),
                        _DetailItem(
                          label: 'Duration',
                          value: data.durationLabel,
                        ),
                        _DetailItem(
                          label: 'Type of session',
                          value: data.sessionType,
                        ),
                        _DetailItem(
                          label: 'Skill level',
                          value: data.skillLevel,
                        ),
                        _DetailItem(
                          label: 'Session sponsored by',
                          value: data.sponsorName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'This session hosted at'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    child: Column(
                      children: <Widget>[
                        _DetailItem(label: 'Venue', value: data.venue),
                        _DetailItem(label: 'Location', value: data.location),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Confirmed participants'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    child: SessionAvatarList(
                      names: data.confirmedParticipantNames,
                      totalCount: data.confirmedParticipantCount,
                      avatarSize: 60,
                      gap: 12,
                      wrap: true,
                      scrollable: false,
                    ),
                  ),
                  if (data.waitlistCount > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Waitlisted participants'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: SessionAvatarList(
                        names: data.waitlistedParticipantNames,
                        totalCount: data.waitlistCount,
                        avatarSize: 60,
                        gap: 12,
                        wrap: true,
                        scrollable: false,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Meet your host'),
                  const SizedBox(height: 8),
                  _HostCard(data: data),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Things to know'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    child: Column(
                      children: <Widget>[
                        _DetailItem(
                          label: 'Credits cost',
                          value: '${data.creditCost}',
                        ),
                        _DetailItem(
                          label: 'Refund availability',
                          value: data.refundAvailable
                              ? 'Available'
                              : 'Not available',
                        ),
                        _DetailItem(
                          label: 'Refund window',
                          value: data.refundWindowLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1D2230),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6F7482),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D2230),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.data});

  final SessionDetailsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratingText = data.hostSkillRating == null
        ? 'N/A'
        : data.hostSkillRating!.toStringAsFixed(1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            SessionAvatar(name: data.hostName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data.hostName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skill level: ${data.hostSkillLevel}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Skill rating: $ratingText',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
