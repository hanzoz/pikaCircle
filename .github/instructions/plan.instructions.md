# PikaCircle flutter app

## UI Design

The UI design for the PikaCircle app is inspired by the Material Design guidelines, with a focus on simplicity and ease of use. The app features a clean and modern interface, with intuitive navigation and clear visual hierarchy. The color scheme is based on a combination of vibrant and muted colors, creating a visually appealing and engaging experience for users. The app also incorporates animations and transitions to enhance the user experience and make interactions feel more fluid and responsive.

## Tech Stack

- Flutter
- Dart
- AppWrite (Self-hosted backend, refer to .env)
- AutoRoute (for navigation)
- Provider (for state management)
- Flutter Secure Storage (for secure storage of sensitive data)
- Freezed (for immutable data classes and unions)
- Bloc Test (for testing)
- Mockito (for mocking in tests)
- Flutter Lints (for linting)

! Offline first approach: The app should be designed to work without an internet connection, syncing data when a connection is available.
! Responsive design: The app should work well on a variety of screen sizes and orientations.
! Accessibility: The app should be accessible to users with disabilities, following best practices for accessibility in Flutter.
! Performance: The app should be optimized for performance, minimizing load times and ensuring smooth interactions.
! Security: The app should follow best practices for security, especially when handling user data and authentication

## Pages

The app will consist of several pages, including:

- **onboarding**: A series of screens that introduce new users to the app and its features.
- **login**: A screen where existing users sign in using Apple, Google, or LinkedIn OAuth.
- **signup**: A screen where new users can create an account with Apple, Google & LinkedIn.
- **home**: The main screen of the app, where users can see their feed and interact with posts.
- **sessions**: A screen visible only to users with the Host role, where they can view, edit, and cancel their active sessions.
- **sessions:details**: A screen where hosts can view details about a specific session, including the participants, chat, and session settings.
- **play**: A screen for non-host participants to view the sessions they have joined and are currently active.
- **play:details**: A screen where users can view details about a specific session, including the host, participants, and chat.
- **wallet**: A screen where users can view their wallet balance and transaction history.
- **profile**: A screen where users manage their personal information and access profile sub-pages. Navigation to messages, notifications, and settings is handled via their respective dedicated pages listed below.
- **profile:settings**: A screen where users can adjust their app settings, such as notification preferences and account settings.
- **profile:edit**: A screen where users can edit their profile information, such as their name, profile picture, and bio.
- **profile:referral**: A screen where users can view their referral code and share it with others to earn rewards.
- **find**: A screen where users can search for other sessions.
- **messages**: A screen where users can view their messages and conversations with other users.
- **notifications**: A screen where users can view their notifications and manage their notification preferences.

## Offline Behavior

Specify per-page offline support:

- **home** feed: cached and readable offline.
- **play** / **sessions**: require connectivity.
- **messages**: cached history readable offline; sending queued until online.
- **wallet**: read-only offline; transactions require connectivity.
