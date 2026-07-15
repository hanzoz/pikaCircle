/// Canonical Appwrite TablesDB table IDs.
///
/// Mirrors the MVP active schema documented in `docs/database.md`. Using these
/// constants avoids stringly-typed table names scattered across data sources.
abstract final class TableIds {
  // Identity & profile
  static const String users = 'users';
  static const String skills = 'skills';
  static const String wallet = 'wallet';
  static const String membershipLevels = 'membership_levels';

  // Sessions
  static const String sessions = 'sessions';
  static const String sessionParticipants = 'session_participants';
  static const String sessionHostActions = 'session_host_actions';
  static const String sessionAccessCodes = 'session_access_codes';

  // Discovery / catalog
  static const String venues = 'venues';
  static const String sponsors = 'sponsors';
  static const String announcements = 'announcements';
  static const String sports = 'sports';
  static const String playFormats = 'play_formats';

  // Play preferences & backgrounds
  static const String userPlayPreferences = 'user_play_preferences';
  static const String userFavouriteVenues = 'user_favourite_venues';
  static const String userSportsBackgrounds = 'user_sports_backgrounds';

  // Wallet / commerce
  static const String creditPacks = 'credit_packs';
  static const String transactions = 'transactions';
}
