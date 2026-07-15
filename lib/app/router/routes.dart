/// Route path + name constants for the app router.
abstract final class Routes {
  /// The guided signed-out experience (landing → assessment → sign-up, plus
  /// login / forgot-password sub-steps), all driven by one screen.
  static const String onboarding = '/onboarding';
  static const String shell = '/';
  static const String editProfile = '/edit-profile';
  static const String preferences = '/preferences';
}
