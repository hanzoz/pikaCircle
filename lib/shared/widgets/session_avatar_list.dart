import 'dart:math' as math;
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';

class SessionAvatarList extends StatelessWidget {
  const SessionAvatarList({
    super.key,
    required this.names,
    required this.totalCount,
    this.avatarUrls,
    this.avatarFileIds,
    this.avatarSize = 100,
    this.gap = 12,
    this.maxVisible,
    this.scrollable = true,
    this.wrap = false,
    this.emptyLabel = 'None',
  });

  final List<String> names;
  final int totalCount;
  final List<String?>? avatarUrls;
  final List<String?>? avatarFileIds;
  final double avatarSize;
  final double gap;
  final int? maxVisible;
  final bool scrollable;
  final bool wrap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) {
      return Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium);
    }

    final safeMaxVisible = maxVisible == null || maxVisible! <= 0
        ? totalCount
        : maxVisible!;
    final visibleCount = math.min(totalCount, safeMaxVisible);
    final knownVisible = math.min(names.length, visibleCount);
    final overflowCount = totalCount - visibleCount;

    final children = <Widget>[
      for (int i = 0; i < knownVisible; i++)
        SessionAvatar(
          name: names[i],
          imageUrl: avatarUrls != null && i < avatarUrls!.length
              ? avatarUrls![i]
              : null,
          avatarFileId: avatarFileIds != null && i < avatarFileIds!.length
              ? avatarFileIds![i]
              : null,
          size: avatarSize,
        ),
      for (int i = knownVisible; i < visibleCount; i++)
        _UnknownSessionAvatar(
          size: avatarSize,
          name: i < names.length ? names[i] : null,
        ),
      if (overflowCount > 0)
        _OverflowSessionAvatar(count: overflowCount, size: avatarSize),
    ];

    if (wrap) {
      return Wrap(spacing: gap, runSpacing: gap, children: children);
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: _withGap(children, gap),
    );

    if (!scrollable) {
      return SizedBox(height: avatarSize, child: row);
    }

    return SizedBox(
      height: avatarSize,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: row,
      ),
    );
  }

  List<Widget> _withGap(List<Widget> items, double spacing) {
    if (items.isEmpty) return const <Widget>[];
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i != items.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
}

class SessionAvatar extends ConsumerWidget {
  const SessionAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.avatarFileId,
    this.size = 100,
  });

  final String name;
  final String? imageUrl;
  final String? avatarFileId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = _nameInitials(name);
    final outerRadius = size / 2;
    final innerRadius = (size - 4) / 2;
    final avatarBucketId = ref.watch(appwriteConfigProvider).avatarBucketId;
    final storage = ref.watch(appwriteStorageProvider);

    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: _AvatarImageOrInitials(
        imageUrl: imageUrl,
        avatarFileId: avatarFileId,
        avatarBucketId: avatarBucketId,
        storage: storage,
        initials: initials,
        innerRadius: innerRadius,
      ),
    );
  }
}

String _nameInitials(String? value, {String fallback = 'P'}) {
  if (value == null) return fallback;

  final segments = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((String token) => token.isNotEmpty)
      .toList(growable: false);

  if (segments.isEmpty) return fallback;
  if (segments.length == 1) return segments.first[0].toUpperCase();
  return '${segments.first[0]}${segments.last[0]}'.toUpperCase();
}

class _AvatarImageOrInitials extends StatelessWidget {
  const _AvatarImageOrInitials({
    required this.imageUrl,
    required this.avatarFileId,
    required this.avatarBucketId,
    required this.storage,
    required this.initials,
    required this.innerRadius,
  });

  final String? imageUrl;
  final String? avatarFileId;
  final String avatarBucketId;
  final Storage storage;
  final String initials;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasUrl = normalizedUrl != null && normalizedUrl.isNotEmpty;

    if (!hasUrl) {
      return _AvatarFromStorageOrInitials(
        avatarFileId: avatarFileId,
        avatarBucketId: avatarBucketId,
        storage: storage,
        innerRadius: innerRadius,
        initials: initials,
      );
    }

    final diameter = innerRadius * 2;
    return ClipOval(
      child: Image.network(
        normalizedUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _AvatarFromStorageOrInitials(
            avatarFileId: avatarFileId,
            avatarBucketId: avatarBucketId,
            storage: storage,
            innerRadius: innerRadius,
            initials: initials,
          );
        },
      ),
    );
  }
}

class _AvatarFromStorageOrInitials extends StatelessWidget {
  const _AvatarFromStorageOrInitials({
    required this.avatarFileId,
    required this.avatarBucketId,
    required this.storage,
    required this.innerRadius,
    required this.initials,
  });

  final String? avatarFileId;
  final String avatarBucketId;
  final Storage storage;
  final double innerRadius;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final normalizedFileId = avatarFileId?.trim();
    if (normalizedFileId == null || normalizedFileId.isEmpty) {
      return _InitialsAvatar(innerRadius: innerRadius, initials: initials);
    }

    return FutureBuilder<Uint8List>(
      future: storage.getFileView(
        bucketId: avatarBucketId,
        fileId: normalizedFileId,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _InitialsAvatar(innerRadius: innerRadius, initials: initials);
        }

        final diameter = innerRadius * 2;
        return ClipOval(
          child: Image.memory(
            bytes,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.innerRadius, required this.initials});

  final double innerRadius;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: innerRadius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OverflowSessionAvatar extends StatelessWidget {
  const _OverflowSessionAvatar({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final outerRadius = size / 2;
    final innerRadius = (size - 4) / 2;

    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnknownSessionAvatar extends StatelessWidget {
  const _UnknownSessionAvatar({required this.size, this.name});

  final double size;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initials = _nameInitials(name);
    final outerRadius = size / 2;
    final innerRadius = (size - 4) / 2;

    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
