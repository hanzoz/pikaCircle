import 'env.dart';

/// Immutable, resolved Appwrite configuration for the client.
///
/// Built from [Env] at bootstrap and exposed through
/// `appwriteConfigProvider` so the rest of the app depends on this value
/// object instead of reading environment strings directly.
class AppwriteConfig {
  const AppwriteConfig({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.avatarBucketId,
    required this.announcementBucketId,
    required this.profileFunctionId,
    required this.sessionJoinFunctionId,
    required this.userPublicProfilesFunctionId,
  });

  factory AppwriteConfig.fromEnv() {
    return AppwriteConfig(
      endpoint: Env.appwriteEndpoint,
      projectId: Env.appwriteProjectId,
      databaseId: Env.appwriteDatabaseId,
      avatarBucketId: Env.avatarBucketId,
      announcementBucketId: Env.announcementBucketId,
      profileFunctionId: Env.profileFunctionId,
      sessionJoinFunctionId: Env.sessionJoinFunctionId,
      userPublicProfilesFunctionId: Env.userPublicProfilesFunctionId,
    );
  }

  final String endpoint;
  final String projectId;
  final String databaseId;
  final String avatarBucketId;
  final String announcementBucketId;
  final String profileFunctionId;
  final String sessionJoinFunctionId;
  final String userPublicProfilesFunctionId;

  /// The custom URL scheme the OAuth deep-link callback returns to.
  ///
  /// Appwrite mints native OAuth success/failure URLs of the form
  /// `appwrite-callback-<projectId>://...`, so this scheme must be registered
  /// natively (Android manifest + iOS `Info.plist`). See
  /// `docs/appwrite-google-oauth-setup.md`.
  String get oauthCallbackScheme => 'appwrite-callback-$projectId';

  /// Path segment appended to the callback scheme.
  String get oauthCallbackPath => 'auth-callback';

  /// Deep-link the OAuth flow redirects to on success. The `userId`/`secret`
  /// query params are parsed from the callback to create the session.
  String get oauthSuccessUrl =>
      '$oauthCallbackScheme://$oauthCallbackPath/success';

  /// Deep-link the OAuth flow redirects to on failure.
  String get oauthFailureUrl =>
      '$oauthCallbackScheme://$oauthCallbackPath/failure';

  Uri get _endpointUri => Uri.parse(endpoint);

  /// Builds the Appwrite OAuth2 **token** URL for [provider].
  ///
  /// This is the token flow (`/account/tokens/oauth2/{provider}`) — opening it
  /// in a browser returns to [oauthSuccessUrl] with `userId`/`secret`, which
  /// the caller exchanges via `Account.createSession`. Using the token flow
  /// (rather than the session flow) is what lets a native app complete OAuth
  /// through `flutter_web_auth_2`.
  Uri oauthTokenUrl({
    required String provider,
    List<String> scopes = const ['email', 'profile'],
  }) {
    final base = Uri.parse(
      _endpointUri.toString().replaceFirst(RegExp(r'/+$'), ''),
    );
    return base.replace(
      path: '${base.path}/account/tokens/oauth2/$provider',
      queryParameters: {
        'project': projectId,
        'success': oauthSuccessUrl,
        'failure': oauthFailureUrl,
        if (scopes.isNotEmpty) 'scopes[]': scopes,
      },
    );
  }
}
