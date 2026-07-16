import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:appwrite/appwrite.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/profile/domain/entities/profile_edit_data.dart';
import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

final _editProfileSkillLevelProvider = FutureProvider.autoDispose
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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const double _maxFormWidth = 720;

  // --- Enum label <-> wire mappings (display labels, send wire values) ---
  static const Map<String, String> _genderLabelToWire = {
    'Male': 'male',
    'Female': 'female',
    'Non-binary': 'non_binary',
  };

  static const Map<String, String> _salaryLabelToWire = {
    'Below 3k': 'below_3k',
    '3k – 6k': '3k_6k',
    '6k – 10k': '6k_10k',
    '10k – 20k': '10k_20k',
    '20k+': '20k_plus',
    'Prefer not to say': 'prefer_not_to_say',
  };

  // Preferred days: display Monday..Sunday, wire monday..sunday.
  static const List<String> _dayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Preferred time slots: display Morning.., wire morning..
  static const List<String> _timeLabels = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
  ];

  // Sport level: display Beginner.., wire beginner..
  static const List<String> _levelLabels = [
    'Beginner',
    'Intermediate',
    'Competitive',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _linkedInController;
  late final TextEditingController _companyController;
  late final TextEditingController _industryController;
  late final TextEditingController _locationController;

  DateTime? _dateOfBirth;
  String? _selectedSkillLevel; // wire value
  String? _selectedGender; // wire value
  String? _selectedSalaryRange; // wire value

  final Set<String> _selectedPlayDays = {}; // wire values monday..sunday
  final Set<String> _selectedPlayTimes = {}; // wire values morning..night
  final Set<String> _selectedFormatIds = {}; // play_format ids
  final List<String> _selectedVenueIds = []; // ordered venue ids
  final Map<String, String> _sportLevels = {}; // {sportId: wire level}
  final Set<String> _pickleballSportIds =
      {}; // excluded from sports backgrounds

  bool _checkingUsername = false;
  bool _saving = false;
  String? _usernameError;
  String? _lastValidatedUsername;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _jobTitleController = TextEditingController();
    _linkedInController = TextEditingController();
    _companyController = TextEditingController();
    _industryController = TextEditingController();
    _locationController = TextEditingController();
    _usernameController.addListener(_handleUsernameChanged);
  }

  /// Populates all controllers and selection state from the loaded
  /// [ProfileEditData]. Runs once, guarded by [_populated].
  void _populateFromEditData(ProfileEditData data) {
    _populated = true;
    final user = data.user;

    _nameController.text = user.name;
    _usernameController.text = user.username ?? '';
    _bioController.text = user.bio ?? '';
    _jobTitleController.text = user.jobTitle ?? '';
    _linkedInController.text = user.linkedinProfileUrl ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _companyController.text = user.company ?? '';
    _industryController.text = user.industry ?? '';
    _locationController.text = user.locationLabel ?? '';

    if (user.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(user.dateOfBirth!);
    }
    _selectedSkillLevel = _normalizeSkillLevel(user.skillLevel);
    _selectedGender = user.gender;
    _selectedSalaryRange = user.salaryRange;

    _pickleballSportIds
      ..clear()
      ..addAll(
        data.sportOptions
            .where((sport) => _isPickleballSportName(sport.displayName))
            .map((sport) => sport.id),
      );

    // Set last validated username to avoid re-checking unchanged value.
    if (user.username != null && user.username!.isNotEmpty) {
      _lastValidatedUsername = user.username;
    }

    // Play preferences.
    final prefs = data.playPreferences;
    if (prefs != null) {
      _selectedPlayDays.addAll(prefs.preferredDays);
      _selectedPlayTimes.addAll(prefs.preferredTimeSlots);
      _selectedFormatIds.addAll(prefs.preferredFormatIds);
    }

    // Favourite venues, ordered by sort_order.
    final favourites = [...data.favouriteVenues]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _selectedVenueIds
      ..clear()
      ..addAll(favourites.map((f) => f.venueId));

    // Sports backgrounds -> {sportId: level} for those with a level set.
    for (final bg in data.sportsBackgrounds) {
      if (_pickleballSportIds.contains(bg.sportId)) {
        continue;
      }
      if (bg.level != null && bg.level!.isNotEmpty) {
        _sportLevels[bg.sportId] = bg.level!;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_handleUsernameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _linkedInController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleUsernameChanged() {
    final normalized = _normalizeUsername(_usernameController.text);
    if (_lastValidatedUsername == normalized && _usernameError == null) {
      return;
    }

    if (_usernameError != null || _lastValidatedUsername != null) {
      setState(() {
        _usernameError = null;
        _lastValidatedUsername = null;
      });
    }
  }

  String _normalizeUsername(String value) => value.trim().toLowerCase();

  Future<bool> _validateUsername({bool showFeedback = true}) async {
    final normalized = _normalizeUsername(_usernameController.text);

    if (normalized.isEmpty) {
      setState(() {
        _usernameError = 'Username is required.';
        _lastValidatedUsername = null;
      });
      return false;
    }

    if (_lastValidatedUsername == normalized && _usernameError == null) {
      return true;
    }

    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    final result = await ref
        .read(profileControllerProvider.notifier)
        .checkUsername(normalized);

    if (!mounted) return false;

    return result.fold(
      (failure) {
        setState(() {
          _checkingUsername = false;
          _lastValidatedUsername = null;
          _usernameError = 'Could not validate username. Please try again.';
        });
        if (showFeedback) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
        return false;
      },
      (availability) {
        final normalizedFromServer = _normalizeUsername(
          availability.normalized,
        );
        if (!availability.available) {
          setState(() {
            _checkingUsername = false;
            _lastValidatedUsername = null;
            _usernameError =
                availability.reason ?? 'This username is already taken.';
          });
          return false;
        }

        if (normalizedFromServer.isNotEmpty &&
            _usernameController.text.trim() != normalizedFromServer) {
          _usernameController
            ..text = normalizedFromServer
            ..selection = TextSelection.collapsed(
              offset: normalizedFromServer.length,
            );
        }

        setState(() {
          _checkingUsername = false;
          _lastValidatedUsername = normalizedFromServer.isEmpty
              ? normalized
              : normalizedFromServer;
          _usernameError = null;
        });
        return true;
      },
    );
  }

  String? _trimToNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String? _formattedDateOfBirth() {
    final dob = _dateOfBirth;
    if (dob == null) return null;
    return '${dob.year.toString().padLeft(4, '0')}-'
        '${dob.month.toString().padLeft(2, '0')}-'
        '${dob.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onSavePressed() async {
    if (_saving || _checkingUsername) return;

    setState(() => _saving = true);
    final validUsername = await _validateUsername();
    if (!mounted) return;

    if (!validUsername) {
      setState(() => _saving = false);
      return;
    }

    final payload = <String, Object?>{
      'profile': <String, Object?>{
        'name': _nameController.text.trim(),
        'username': _normalizeUsername(_usernameController.text),
        'skill_level': _selectedSkillLevel,
        'bio': _trimToNull(_bioController),
        'job_title': _trimToNull(_jobTitleController),
        'linkedin_profile_url': _trimToNull(_linkedInController),
        'gender': _selectedGender,
        'date_of_birth': _formattedDateOfBirth(),
        'phone_number': _trimToNull(_phoneController),
        'company': _trimToNull(_companyController),
        'industry': _trimToNull(_industryController),
        'salary_range': _selectedSalaryRange,
        'location_label': _trimToNull(_locationController),
      },
      'play_preferences': <String, Object?>{
        'preferred_time_slots': _selectedPlayTimes.toList(),
        'preferred_days': _selectedPlayDays.toList(),
        'preferred_format_ids': _selectedFormatIds.toList(),
        'notes': null,
      },
      'favourite_venues': <Map<String, Object?>>[
        for (var i = 0; i < _selectedVenueIds.length; i++)
          {'venue_id': _selectedVenueIds[i], 'sort_order': i},
      ],
      'sports_backgrounds': <Map<String, Object?>>[
        for (final entry in _sportLevels.entries)
          if (!_pickleballSportIds.contains(entry.key))
            {
              'sport_id': entry.key,
              'level': entry.value,
              'is_primary': false,
              'years_played': null,
              'notes': null,
            },
      ],
    };

    final failure = await ref
        .read(profileControllerProvider.notifier)
        .saveEditData(payload);

    if (!mounted) return;

    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      setState(() => _saving = false);
      return;
    }

    setState(() => _saving = false);
    Navigator.pop(context);
  }

  void _selectDate() async {
    var pendingDate = _dateOfBirth ?? DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      setState(() => _dateOfBirth = pendingDate);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: pendingDate,
                minimumYear: 1950,
                maximumYear: DateTime.now().year,
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (DateTime picked) {
                  pendingDate = picked;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleInSet(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  void _showSportLevelPicker(String sportId) {
    final currentWire = _sportLevels[sportId];
    final initialIndex = currentWire == null
        ? 0
        : _levelLabels.indexWhere((l) => l.toLowerCase() == currentWire);
    var pendingIndex = initialIndex < 0 ? 0 : initialIndex;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      setState(
                        () => _sportLevels[sportId] = _levelLabels[pendingIndex]
                            .toLowerCase(),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: pendingIndex,
                ),
                onSelectedItemChanged: (index) {
                  pendingIndex = index;
                },
                children: _levelLabels
                    .map((level) => Center(child: Text(level)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editDataAsync = ref.watch(profileEditDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 44),
        child: const PikaAppBar(leading: PikaAppBarLeading.back, initials: 'P'),
      ),
      body: SafeArea(
        child: editDataAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => _buildErrorState(context),
          data: (data) {
            final fallbackSkillLevelAsync = ref.watch(
              _editProfileSkillLevelProvider(data.user.id),
            );
            if (!_populated) {
              _populateFromEditData(data);
            }
            final fallbackSkillLevel = _normalizeSkillLevel(
              fallbackSkillLevelAsync.value,
            );
            if (_selectedSkillLevel == null && fallbackSkillLevel != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _selectedSkillLevel != null) return;
                setState(() => _selectedSkillLevel = fallbackSkillLevel);
              });
            }
            return _buildForm(context, data);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: Color(0xFFC63A3A),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load your profile',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D2230),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6F7482),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => ref.invalidate(profileEditDataProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfileEditData data) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final filteredSportOptions = data.sportOptions
        .where((sport) => !_isPickleballSportName(sport.displayName))
        .toList(growable: false);
    final paneLayout = _resolveFoldPaneLayout(context);
    final formWidth = paneLayout.width < _maxFormWidth
        ? paneLayout.width
        : _maxFormWidth;

    return Align(
      alignment: paneLayout.alignment,
      child: SizedBox(
        width: formWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Profile',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D2230),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep your profile up to date',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F7482),
                ),
              ),
              const SizedBox(height: 20),
              // Basic Information Section
              _SectionCard(
                title: 'Basic Information',
                children: [
                  _buildTextField('Name', _nameController),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Username',
                    _usernameController,
                    onEditingComplete: () =>
                        _validateUsername(showFeedback: false),
                    errorText: _usernameError,
                    suffix: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: CupertinoActivityIndicator(),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField('Date of Birth', _dateOfBirth, _selectDate),
                  const SizedBox(height: 12),
                  _buildSingleSelectChipGroup(
                    context,
                    title: 'Skill Level',
                    options: [
                      for (final label in _levelLabels)
                        _ChipOption(id: label.toLowerCase(), label: label),
                    ],
                    selectedId: _selectedSkillLevel,
                    onSelect: (id) => setState(() => _selectedSkillLevel = id),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Gender',
                    _labelForWire(_genderLabelToWire, _selectedGender),
                    _genderLabelToWire.keys.toList(),
                    (label) => setState(
                      () => _selectedGender = label == null
                          ? null
                          : _genderLabelToWire[label],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Phone Number', _phoneController),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Bio',
                    _bioController,
                    maxLines: 4,
                    hint: 'Tell us about yourself',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Location & Venues Section
              _SectionCard(
                title: 'Location & Venues',
                children: [
                  _buildTextField(
                    'Location',
                    _locationController,
                    hint: 'e.g. San Francisco, CA',
                  ),
                  const SizedBox(height: 12),
                  if (data.venueOptions.isEmpty)
                    Text(
                      'No venues available',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F7482),
                      ),
                    )
                  else
                    _buildDropdown(
                      'Favorite Venue',
                      _venueLabelFor(
                        _selectedVenueIds.isEmpty
                            ? null
                            : _selectedVenueIds.first,
                        data,
                      ),
                      [for (final venue in data.venueOptions) venue.name],
                      (venueName) {
                        final selectedVenueId = _venueIdFor(venueName, data);
                        setState(() {
                          _selectedVenueIds
                            ..clear()
                            ..addAll(
                              selectedVenueId == null ? [] : [selectedVenueId],
                            );
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Play Preferences Section
              _SectionCard(
                title: 'Play Preferences',
                children: [
                  _buildChipGroup(
                    context,
                    title: 'Preferred Days',
                    options: [
                      for (final label in _dayLabels)
                        _ChipOption(id: label.toLowerCase(), label: label),
                    ],
                    isSelected: _selectedPlayDays.contains,
                    onToggle: (wire) => _toggleInSet(_selectedPlayDays, wire),
                  ),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    context,
                    title: 'Preferred Time',
                    options: [
                      for (final label in _timeLabels)
                        _ChipOption(id: label.toLowerCase(), label: label),
                    ],
                    isSelected: _selectedPlayTimes.contains,
                    onToggle: (wire) => _toggleInSet(_selectedPlayTimes, wire),
                  ),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    context,
                    title: 'Preferred Format',
                    options: [
                      for (final format in data.formatOptions)
                        _ChipOption(id: format.id, label: format.displayName),
                    ],
                    isSelected: (id) => _selectedFormatIds.contains(id),
                    onToggle: (id) => _toggleInSet(_selectedFormatIds, id),
                    emptyText: 'No formats available',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Professional Information Section
              _SectionCard(
                title: 'Professional Information',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Job Title',
                          _jobTitleController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Tooltip(
                          message: 'LinkedIn verified',
                          triggerMode: TooltipTriggerMode.tap,
                          child: const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: Color(0xFF0A66C2),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('LinkedIn Profile', _linkedInController),
                  const SizedBox(height: 12),
                  _buildTextField('Company', _companyController),
                  const SizedBox(height: 12),
                  _buildTextField('Industry', _industryController),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Salary Range',
                    _labelForWire(_salaryLabelToWire, _selectedSalaryRange),
                    _salaryLabelToWire.keys.toList(),
                    (label) => setState(
                      () => _selectedSalaryRange = label == null
                          ? null
                          : _salaryLabelToWire[label],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Sports Background Section
              _SectionCard(
                title: 'Other Sports Background',
                children: [
                  if (filteredSportOptions.isEmpty)
                    Text(
                      'No additional sports available',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F7482),
                      ),
                    ),
                  for (final sport in filteredSportOptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showSportLevelPicker(sport.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sport.displayName,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _levelLabelFor(_sportLevels[sport.id]) ??
                                      'Select level',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _sportLevels[sport.id] != null
                                        ? const Color(0xFF1D2230)
                                        : const Color(0xFF6F7482),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: _saving || _checkingUsername
                      ? null
                      : _onSavePressed,
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  _FoldPaneLayout _resolveFoldPaneLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final displayFeatures = mediaQuery.displayFeatures;
    final verticalFold = displayFeatures.where((feature) {
      final typeName = feature.type.toString().toLowerCase();
      final isFoldOrHinge =
          typeName.contains('fold') || typeName.contains('hinge');
      if (!isFoldOrHinge) {
        return false;
      }
      final bounds = feature.bounds;
      if (bounds.width <= 0) return false;
      // Vertical folds split the screen into left/right panes.
      return bounds.height >= (screenSize.height * 0.8);
    });

    if (verticalFold.isEmpty) {
      return _FoldPaneLayout(
        width: screenSize.width,
        alignment: Alignment.topCenter,
      );
    }

    final hingeBounds = verticalFold.first.bounds;
    final leftPaneWidth = hingeBounds.left;
    final rightPaneWidth = screenSize.width - hingeBounds.right;
    final useRightPane = rightPaneWidth > leftPaneWidth;

    return _FoldPaneLayout(
      width: useRightPane ? rightPaneWidth : leftPaneWidth,
      alignment: useRightPane ? Alignment.topRight : Alignment.topLeft,
    );
  }

  /// Reverse-maps a stored [wire] value to its display label using [labelToWire].
  String? _labelForWire(Map<String, String> labelToWire, String? wire) {
    if (wire == null) return null;
    for (final entry in labelToWire.entries) {
      if (entry.value == wire) return entry.key;
    }
    return null;
  }

  /// Maps a wire level (beginner/intermediate/competitive) to its display label.
  String? _levelLabelFor(String? wire) {
    if (wire == null) return null;
    for (final label in _levelLabels) {
      if (label.toLowerCase() == wire) return label;
    }
    return null;
  }

  String? _normalizeSkillLevel(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final label in _levelLabels) {
      final wire = label.toLowerCase();
      if (wire == normalized) return wire;
    }
    return null;
  }

  String? _venueLabelFor(String? venueId, ProfileEditData data) {
    if (venueId == null) return null;
    for (final venue in data.venueOptions) {
      if (venue.id == venueId) return venue.name;
    }
    return null;
  }

  String? _venueIdFor(String? venueName, ProfileEditData data) {
    if (venueName == null) return null;
    for (final venue in data.venueOptions) {
      if (venue.name == venueName) return venue.id;
    }
    return null;
  }

  bool _isPickleballSportName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.contains('pickleball');
  }

  Widget _buildChipGroup(
    BuildContext context, {
    required String title,
    required List<_ChipOption> options,
    required bool Function(String id) isSelected,
    required void Function(String id) onToggle,
    String? emptyText,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D2230),
          ),
        ),
        const SizedBox(height: 8),
        if (options.isEmpty && emptyText != null)
          Text(
            emptyText,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6F7482),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.label),
                  selected: isSelected(option.id),
                  onSelected: (_) => onToggle(option.id),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSingleSelectChipGroup(
    BuildContext context, {
    required String title,
    required List<_ChipOption> options,
    required String? selectedId,
    required void Function(String id) onSelect,
    String? emptyText,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D2230),
          ),
        ),
        const SizedBox(height: 8),
        if (options.isEmpty && emptyText != null)
          Text(
            emptyText,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6F7482),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.label),
                  selected: selectedId == option.id,
                  onSelected: (_) => onSelect(option.id),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    String? errorText,
    Widget? suffix,
    VoidCallback? onEditingComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D2230),
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          placeholder: hint ?? label,
          maxLines: maxLines,
          suffix: suffix,
          onEditingComplete: onEditingComplete,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText == null
                  ? const Color(0xFFF0F1F5)
                  : const Color(0xFFC63A3A),
            ),
            borderRadius: BorderRadius.circular(12),
            color: CupertinoColors.white,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFC63A3A)),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D2230),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF0F1F5)),
              borderRadius: BorderRadius.circular(12),
              color: CupertinoColors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? _formatDateAsDayMonthYear(selectedDate)
                      : 'Select date',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(CupertinoIcons.calendar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateAsDayMonthYear(DateTime date) {
    const monthAbbreviations = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = monthAbbreviations[date.month - 1];
    return '$day $month ${date.year}';
  }

  Widget _buildDropdown(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D2230),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showCupertinoPickerMenu(
            options: options,
            selectedValue: selectedValue,
            onChanged: onChanged,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF0F1F5)),
              borderRadius: BorderRadius.circular(12),
              color: CupertinoColors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedValue ?? 'Select $label',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(CupertinoIcons.chevron_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoPickerMenu({
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    if (options.isEmpty) return;

    final initialIndex = selectedValue != null
        ? options.indexOf(selectedValue)
        : 0;
    var pendingIndex = initialIndex < 0 ? 0 : initialIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {
                      onChanged(options[pendingIndex]);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: pendingIndex,
                ),
                onSelectedItemChanged: (index) {
                  pendingIndex = index;
                },
                children: options
                    .map((option) => Center(child: Text(option)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable chip option with a stable [id] (wire value or entity id) and a
/// human-readable [label].
class _ChipOption {
  const _ChipOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _FoldPaneLayout {
  const _FoldPaneLayout({required this.width, required this.alignment});

  final double width;
  final Alignment alignment;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D2230),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
