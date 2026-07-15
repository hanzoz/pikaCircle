import 'package:pikacircle/features/profile/domain/entities/favourite_venue.dart';
import 'package:pikacircle/features/profile/domain/entities/play_format_option.dart';
import 'package:pikacircle/features/profile/domain/entities/play_preferences.dart';
import 'package:pikacircle/features/profile/domain/entities/sport_option.dart';
import 'package:pikacircle/features/profile/domain/entities/sports_background.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/venue_option.dart';

/// The full aggregate the Edit Profile screen reads: the [UserProfile] plus
/// the user's play preferences, favourite venues, sports backgrounds, and the
/// catalog options needed to populate dropdowns.
///
/// Immutable value object with value equality. Domain-only: no Flutter or
/// Appwrite imports.
class ProfileEditData {
  const ProfileEditData({
    required this.user,
    this.playPreferences,
    this.favouriteVenues = const [],
    this.sportsBackgrounds = const [],
    this.venueOptions = const [],
    this.sportOptions = const [],
    this.formatOptions = const [],
  });

  final UserProfile user;
  final PlayPreferences? playPreferences;
  final List<FavouriteVenue> favouriteVenues;
  final List<SportsBackground> sportsBackgrounds;
  final List<VenueOption> venueOptions;
  final List<SportOption> sportOptions;
  final List<PlayFormatOption> formatOptions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileEditData &&
        other.user == user &&
        other.playPreferences == playPreferences &&
        _listEquals(other.favouriteVenues, favouriteVenues) &&
        _listEquals(other.sportsBackgrounds, sportsBackgrounds) &&
        _listEquals(other.venueOptions, venueOptions) &&
        _listEquals(other.sportOptions, sportOptions) &&
        _listEquals(other.formatOptions, formatOptions);
  }

  @override
  int get hashCode => Object.hash(
    user,
    playPreferences,
    Object.hashAll(favouriteVenues),
    Object.hashAll(sportsBackgrounds),
    Object.hashAll(venueOptions),
    Object.hashAll(sportOptions),
    Object.hashAll(formatOptions),
  );

  @override
  String toString() =>
      'ProfileEditData(user: $user, playPreferences: $playPreferences, '
      'favouriteVenues: ${favouriteVenues.length}, '
      'sportsBackgrounds: ${sportsBackgrounds.length}, '
      'venueOptions: ${venueOptions.length}, '
      'sportOptions: ${sportOptions.length}, '
      'formatOptions: ${formatOptions.length})';
}

/// Order-sensitive list equality used for value comparison of entity lists.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
