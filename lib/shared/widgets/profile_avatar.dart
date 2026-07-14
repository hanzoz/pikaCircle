import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.initials,
    this.avatarUrl,
    this.avatarFileId,
    this.avatarBucketId,
    this.storage,
    this.size = 44,
    this.textStyle,
  });

  final String? initials;
  final String? avatarUrl;
  final String? avatarFileId;
  final String? avatarBucketId;
  final Storage? storage;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final label = (initials?.trim().isNotEmpty == true)
        ? initials!.trim()
        : 'P';
    final resolvedAvatarUrl = avatarUrl?.trim();

    if (resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolvedAvatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _AvatarFromStorageOrFallback(
            avatarFileId: avatarFileId,
            avatarBucketId: avatarBucketId,
            storage: storage,
            label: label,
            size: size,
            textStyle: textStyle,
          ),
        ),
      );
    }

    return _AvatarFromStorageOrFallback(
      avatarFileId: avatarFileId,
      avatarBucketId: avatarBucketId,
      storage: storage,
      label: label,
      size: size,
      textStyle: textStyle,
    );
  }
}

class _AvatarFromStorageOrFallback extends StatelessWidget {
  const _AvatarFromStorageOrFallback({
    required this.avatarFileId,
    required this.avatarBucketId,
    required this.storage,
    required this.label,
    required this.size,
    required this.textStyle,
  });

  final String? avatarFileId;
  final String? avatarBucketId;
  final Storage? storage;
  final String label;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final normalizedFileId = avatarFileId?.trim();
    final normalizedBucketId = avatarBucketId?.trim();
    if (normalizedFileId == null ||
        normalizedFileId.isEmpty ||
        normalizedBucketId == null ||
        normalizedBucketId.isEmpty ||
        storage == null) {
      return _InitialsAvatar(label: label, textStyle: textStyle);
    }

    return FutureBuilder<Uint8List>(
      future: storage!.getFileView(
        bucketId: normalizedBucketId,
        fileId: normalizedFileId,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _InitialsAvatar(label: label, textStyle: textStyle);
        }

        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.label, this.textStyle});

  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.secondary,
      ),
      child: Center(
        child: Text(
          label,
          style:
              textStyle ??
              Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
