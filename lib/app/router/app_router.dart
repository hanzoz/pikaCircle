import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pikacircle/app/router/routes.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_state.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:pikacircle/features/shell/presentation/screens/main_shell.dart';

/// Bridges a Riverpod provider to [GoRouter.refreshListenable] so navigation
/// re-evaluates `redirect` whenever the watched value changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// The app router. Redirects based on authentication state:
/// - unknown (still resolving the session) → stay put, splash-like
/// - unauthenticated → the guided onboarding flow
/// - authenticated → the main shell
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.shell,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.value?.status ?? AuthStatus.unknown;

      // While the session is still resolving, don't bounce the user around.
      if (status == AuthStatus.unknown) return null;

      final isAuthed = status == AuthStatus.authenticated;
      final onOnboarding = state.matchedLocation == Routes.onboarding;

      if (!isAuthed && !onOnboarding) return Routes.onboarding;
      if (isAuthed && onOnboarding) return Routes.shell;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.shell,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
    ],
  );
});
