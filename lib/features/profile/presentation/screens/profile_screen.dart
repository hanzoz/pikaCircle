import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:appwrite/appwrite.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pikacircle/features/profile/presentation/screens/settings_screen.dart';
import 'package:pikacircle/features/profile/presentation/widgets/profile_skill_graph_section.dart';
import 'package:pikacircle/shared/widgets/fold_aware_pane.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';
import 'package:pikacircle/shared/widgets/profile_avatar.dart';

final _profileSkillLevelProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, userId) async {
      if (userId.trim().isEmpty) return null;

      final tables = ref.watch(appwriteTablesDbProvider);
      final config = ref.watch(appwriteConfigProvider);

      String? relationId(Object? value) {
        if (value is Map) {
          final relationValue = value[r'$id'];
          final relation = relationValue?.toString().trim();
          return relation == null || relation.isEmpty ? null : relation;
        }
        final normalized = value?.toString().trim();
        if (normalized == null || normalized.isEmpty) return null;
        return normalized;
      }

      String? parseLevel(Map<String, dynamic> data) {
        final raw = data['level']?.toString().trim();
        if (raw == null || raw.isEmpty) return null;
        return raw;
      }

      try {
        final rows = await tables.listRows(
          databaseId: config.databaseId,
          tableId: TableIds.skills,
          queries: [Query.equal('user_id', userId), Query.limit(1)],
        );
        if (rows.rows.isNotEmpty) {
          return parseLevel(rows.rows.first.data);
        }

        for (final rowId in <String>[userId, 'skill_$userId']) {
          try {
            final row = await tables.getRow(
              databaseId: config.databaseId,
              tableId: TableIds.skills,
              rowId: rowId,
            );
            return parseLevel(row.data);
          } on AppwriteException catch (fallbackError) {
            if (fallbackError.code != 404) rethrow;
          }
        }

        final scanRows = await tables.listRows(
          databaseId: config.databaseId,
          tableId: TableIds.skills,
          queries: [Query.limit(200)],
        );
        for (final row in scanRows.rows) {
          final relatedUserId = relationId(row.data['user_id']);
          if (relatedUserId == userId || row.$id == userId) {
            return parseLevel(row.data);
          }
        }

        return null;
      } on AppwriteException catch (e) {
        if (e.code == 404) return null;
        rethrow;
      }
    });

/// Read-only account overview: name, email, membership, workflow, and wallet
/// balance. Renders a bespoke profile layout and reacts to the async profile
/// state (loading / error / signed-out / loaded).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _uploadingAvatar = false;

  Future<void> _onAvatarTap(AccountProfile profile) async {
    if (_uploadingAvatar) return;

    final source = await _showAvatarSourceSheet(context);
    if (source == null) return;

    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (pickedImage == null) return;

    final bytes = await pickedImage.readAsBytes();
    if (bytes.isEmpty || !mounted) return;

    final isDuplicate = await _isSameAsCurrentAvatar(
      selectedBytes: bytes,
      profile: profile,
    );
    if (!mounted) return;
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This image is already your avatar.')),
      );
      return;
    }

    setState(() => _uploadingAvatar = true);
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(
          bytes: bytes,
          fileName: _avatarFileNameFromPick(pickedImage.name),
        );

    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    final messenger = ScaffoldMessenger.of(context);
    if (failure == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<bool> _isSameAsCurrentAvatar({
    required Uint8List selectedBytes,
    required AccountProfile profile,
  }) async {
    final currentFileId = profile.user.profilePictureFileId?.trim();
    if (currentFileId == null || currentFileId.isEmpty) {
      return false;
    }

    final config = ref.read(appwriteConfigProvider);
    final storage = ref.read(appwriteStorageProvider);

    try {
      final currentBytes = await storage.getFileView(
        bucketId: config.avatarBucketId,
        fileId: currentFileId,
      );
      if (currentBytes.length != selectedBytes.length) {
        return false;
      }
      return listEquals(currentBytes, selectedBytes);
    } catch (_) {
      // If comparison cannot be performed (network/auth/transient error),
      // proceed with normal upload flow.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final appwriteConfig = ref.watch(appwriteConfigProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ProfileMessage(
          message: 'Could not load your profile.',
          icon: Icons.error_outline_rounded,
        ),
        data: (profile) {
          if (profile == null) {
            return const _ProfileMessage(
              message: 'Not signed in.',
              icon: Icons.person_off_rounded,
            );
          }
          return _ProfileDetails(
            profile: profile,
            avatarUrl: _resolveAvatarUrl(
              explicitUrl: profile.user.profilePictureUrl,
              fileId: profile.user.profilePictureFileId,
              endpoint: appwriteConfig.endpoint,
              projectId: appwriteConfig.projectId,
              bucketId: appwriteConfig.avatarBucketId,
            ),
            avatarFileId: profile.user.profilePictureFileId,
            avatarBucketId: appwriteConfig.avatarBucketId,
            storage: ref.watch(appwriteStorageProvider),
            uploadingAvatar: _uploadingAvatar,
            onAvatarTap: () => _onAvatarTap(profile),
          );
        },
      ),
    );
  }
}

/// A centered glass card presenting a single status message (used for the
/// error and signed-out states).
class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FoldAwarePane(
      maxWidth: 420,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: const Color(0xFF2F3340)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF606676)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The loaded profile body: identity header plus a details card.
class _ProfileDetails extends ConsumerWidget {
  const _ProfileDetails({
    required this.profile,
    required this.avatarUrl,
    required this.avatarFileId,
    required this.avatarBucketId,
    required this.storage,
    required this.uploadingAvatar,
    required this.onAvatarTap,
  });

  final AccountProfile profile;
  final String? avatarUrl;
  final String? avatarFileId;
  final String avatarBucketId;
  final Storage storage;
  final bool uploadingAvatar;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final user = profile.user;
    final displayName = user.name.isEmpty ? 'Profilim' : user.name;
    final username = user.username?.trim().isNotEmpty == true
        ? '@${user.username!.trim()}'
        : user.email.isNotEmpty
        ? '@${user.email.split('@').first}'
        : '@pikacircle';
    final skillLevelState = ref.watch(_profileSkillLevelProvider(user.id));
    final skillLevelLabel = skillLevelState.when(
      data: _formatSkillLevel,
      loading: () => 'Loading...',
      error: (_, _) => 'Not set',
    );
    final membershipName = user.membershipLevelName ?? 'bronze';
    final hasPremium = membershipName.toLowerCase() != 'bronze';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PikaAppBar(
          leading: PikaAppBarLeading.back,
          initials: _initialsFromName(displayName),
          onSettingsTap: () => _openSettings(context),
          showNotificationButton: true,
        ),
        Expanded(
          child: FoldAwarePane(
            maxWidth: 420,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: uploadingAvatar ? null : onAvatarTap,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 114,
                            height: 114,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE8EEF9),
                                width: 2,
                              ),
                            ),
                            child: ProfileAvatar(
                              avatarUrl: avatarUrl,
                              avatarFileId: avatarFileId,
                              avatarBucketId: avatarBucketId,
                              storage: storage,
                              initials: _initialsFromName(displayName),
                              size: 102,
                              textStyle: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF23262D),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: uploadingAvatar
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.camera_fill,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FA),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFF0F1F5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: const Color(0xFF1D2230),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    username,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF6F7482),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Skill level: $skillLevelLabel',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: const Color(0xFF355AB7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF23262D),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasPremium
                                        ? CupertinoIcons.star_fill
                                        : CupertinoIcons.star,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _capitalize(membershipName),
                                    style: textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ProfileSkillGraphSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _openSettings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _formatSkillLevel(String? value) {
  if (value == null || value.isEmpty) return 'Not set';
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return 'Not set';

  final parts = normalized.split(RegExp(r'\s+'));
  return parts
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _initialsFromName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'P';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

Future<ImageSource?> _showAvatarSourceSheet(BuildContext context) {
  return showCupertinoModalPopup<ImageSource?>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          child: const Text('Select from library'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          child: const Text('Take photo'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(null),
        child: const Text('Cancel'),
      ),
    ),
  );
}

String _avatarFileNameFromPick(String rawName) {
  final trimmed = rawName.trim();
  if (trimmed.isNotEmpty) return trimmed;
  return 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
}

String? _resolveAvatarUrl({
  required String? explicitUrl,
  required String? fileId,
  required String endpoint,
  required String projectId,
  required String bucketId,
}) {
  final profileUrl = explicitUrl?.trim();
  if (profileUrl != null && profileUrl.isNotEmpty) {
    return profileUrl;
  }

  final normalizedFileId = fileId?.trim();
  if (normalizedFileId == null || normalizedFileId.isEmpty) {
    return null;
  }

  final endpointUri = Uri.parse(endpoint);
  final basePath = endpointUri.path.replaceFirst(RegExp(r'/+$'), '');
  final path =
      '$basePath/storage/buckets/$bucketId/files/$normalizedFileId/view';
  return endpointUri
      .replace(path: path, queryParameters: {'project': projectId})
      .toString();
}
