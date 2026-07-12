/// The set of third-party OAuth providers the app supports for sign-in.
///
/// This is the domain-facing enum. The data layer maps these values onto
/// Appwrite's own `OAuthProvider` enum so the domain stays free of any SDK
/// dependency.
enum OAuthProvider { google, apple, facebook }
