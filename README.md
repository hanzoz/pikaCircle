# PikaCircle

PikaCircle is a Flutter app for discovering pickleball sessions, joining hosted and non-hosted games, managing player profiles, and supporting wallet, reputation, and membership flows.

## UI Design

PikaCircle follows a Material-inspired UI direction focused on simplicity, ease of use, intuitive navigation, clear visual hierarchy, and fluid animations and transitions.

## Product Guidelines

- Offline-first: the app should keep working without an internet connection and sync when connectivity returns.
- Responsive design: the app should work well across different screen sizes and orientations.
- Accessibility: the app should follow Flutter accessibility best practices.
- Performance: the app should minimize load times and keep interactions smooth.
- Security: the app should follow best practices for user data and authentication handling.

## Tech Stack

- Flutter
- Dart
- AutoRoute for navigation
- Provider for state management
- Flutter Secure Storage for sensitive local storage
- Freezed for immutable models and unions
- Bloc Test and Mockito for testing
- Flutter Lints for linting

## Core App Pages

- Onboarding
- Login
- Signup
- Home
- Sessions
- Sessions details
- Play
- Play details
- Wallet
- Profile
- Profile settings
- Profile edit
- Profile referral
- Find
- Messages
- Notifications

## Offline Behavior

- Home feed: cached and readable offline.
- Play and Sessions: require connectivity.
- Messages: cached history readable offline; sending is queued until online.
- Wallet: read-only offline; transactions require connectivity.

## Important Docs

These documents are the main references for how the app is supposed to work:

- [Product plan and MVP scope](docs/planning.md)
- [Database schema and Appwrite data model](docs/database.md)
- [Session lifecycle and join flow](docs/app%20workflows/session-workflow.md)
- [Gamification, reputation, rewards, and progression](docs/app%20workflows/gamification-system-plan.md)
- [User and host registration workflow](docs/app%20workflows/user-and-host-registration-workflow.md)

## Integration Docs

- [LinkedIn integration plan](docs/integration%20planning/linkedin-implementation.md)
- [DUPR integration plan](docs/integration%20planning/dupr-implementation.md)
- [PB Vision future integration plan](docs/integration%20planning/pb-vision-implementation.md)

## Appwrite Operational Docs

- [Google OAuth setup](docs/appwrite-google-oauth-setup.md)
- [Google OAuth troubleshooting](docs/appwrite-google-oauth-troubleshooting.md)
- [TLS certificate fix and production cleanup](docs/appwrite-tls-certificate-fix.md)

## Getting Started

1. Install Flutter and verify the toolchain with `flutter doctor`.
2. Install project dependencies with `flutter pub get`.
3. Configure Appwrite for your environment.
4. Run the app with `flutter run`.

For general Flutter documentation, see [docs.flutter.dev](https://docs.flutter.dev/).
