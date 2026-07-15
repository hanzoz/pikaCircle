import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _linkedInController;
  late final TextEditingController _companyController;
  late final TextEditingController _industryController;

  DateTime? _dateOfBirth;
  String? _selectedGender;
  String? _selectedLocation;
  String? _selectedFavoriteVenue;
  Set<String> _selectedPlayDays = {};
  String? _selectedPlayTime;
  String? _selectedFormat;
  String? _selectedSalaryRange;
  Map<String, String> _sportSkills = {}; // {sport: skillLevel}

  bool _checkingUsername = false;
  bool _saving = false;
  String? _usernameError;
  String? _lastValidatedUsername;

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
    _usernameController.addListener(_handleUsernameChanged);
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

  Future<void> _onSavePressed() async {
    if (_saving || _checkingUsername) return;

    setState(() => _saving = true);
    final validUsername = await _validateUsername();
    if (!mounted) return;

    if (!validUsername) {
      setState(() => _saving = false);
      return;
    }

    setState(() => _saving = false);
    Navigator.pop(context);
  }

  void _selectDate() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: CupertinoDatePicker(
          initialDateTime: _dateOfBirth ?? DateTime.now(),
          minimumYear: 1950,
          maximumYear: DateTime.now().year,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime picked) {
            setState(() => _dateOfBirth = picked);
          },
        ),
      ),
    );
  }

  void _togglePlayDay(String day) {
    setState(() {
      if (_selectedPlayDays.contains(day)) {
        _selectedPlayDays.remove(day);
      } else {
        _selectedPlayDays.add(day);
      }
    });
  }

  void _showSportSkillDialog(String sport) {
    final levels = ['Beginner', 'Intermediate', 'Advanced'];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 32,
          scrollController: FixedExtentScrollController(
            initialItem: _sportSkills[sport] != null
                ? levels.indexOf(_sportSkills[sport]!)
                : 0,
          ),
          onSelectedItemChanged: (index) {
            setState(() => _sportSkills[sport] = levels[index]);
            Navigator.pop(context);
          },
          children: levels.map((level) => Center(child: Text(level))).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 44),
        child: const PikaAppBar(leading: PikaAppBarLeading.back, initials: 'P'),
      ),
      body: SafeArea(
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
                  _buildDropdown(
                    'Gender',
                    _selectedGender,
                    ['Male', 'Female', 'Other', 'Prefer not to say'],
                    (value) => setState(() => _selectedGender = value),
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
              // Location & Preferences Section
              _SectionCard(
                title: 'Location & Venues',
                children: [
                  _buildDropdown(
                    'Location',
                    _selectedLocation,
                    ['San Francisco, CA', 'New York, NY', 'Los Angeles, CA'],
                    (value) => setState(() => _selectedLocation = value),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Favorite Venue',
                    _selectedFavoriteVenue,
                    ['Court 1', 'Court 2', 'Court 3'],
                    (value) => setState(() => _selectedFavoriteVenue = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Play Preferences Section
              _SectionCard(
                title: 'Play Preferences',
                children: [
                  Text(
                    'Preferred Days',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D2230),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final day in [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ])
                        FilterChip(
                          label: Text(day),
                          selected: _selectedPlayDays.contains(day),
                          onSelected: (_) => _togglePlayDay(day),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preferred Time',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D2230),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final time in ['Morning', 'Afternoon', 'Night'])
                        FilterChip(
                          label: Text(time),
                          selected: _selectedPlayTime == time,
                          onSelected: (_) =>
                              setState(() => _selectedPlayTime = time),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preferred Format',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D2230),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final format in [
                        'Singles',
                        'Doubles',
                        'Mixed Doubles',
                      ])
                        FilterChip(
                          label: Text(format),
                          selected: _selectedFormat == format,
                          onSelected: (_) =>
                              setState(() => _selectedFormat = format),
                        ),
                    ],
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
                          message: 'LinkedIn verified badge',
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
                    _selectedSalaryRange,
                    [
                      '\$0 - \$50k',
                      '\$50k - \$100k',
                      '\$100k - \$150k',
                      '\$150k+',
                      'Prefer not to say',
                    ],
                    (value) => setState(() => _selectedSalaryRange = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Sports Background Section
              _SectionCard(
                title: 'Sports Background',
                children: [
                  for (final sport in [
                    'Pickleball',
                    'Tennis',
                    'Badminton',
                    'Table Tennis',
                    'Squash',
                    'Padel',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showSportSkillDialog(sport),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sport,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _sportSkills[sport] ?? 'Select level',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _sportSkills[sport] != null
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
                  color: const Color(0xFF1D2230),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                      ? '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 32,
          scrollController: FixedExtentScrollController(
            initialItem: selectedValue != null
                ? options.indexOf(selectedValue)
                : 0,
          ),
          onSelectedItemChanged: (index) {
            onChanged(options[index]);
            Navigator.pop(context);
          },
          children: options
              .map((option) => Center(child: Text(option)))
              .toList(),
        ),
      ),
    );
  }
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
