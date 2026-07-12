import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:pikacircle/core/error/failure.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/features/onboarding/presentation/controllers/onboarding_flow_controller.dart';
import 'package:pikacircle/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// The guided, multi-step onboarding flow shown to signed-out users.
///
/// Replaces the plain landing / sign-in / sign-up screens with a single driver
/// that cross-fades between steps via an [AnimatedSwitcher]. Step + quiz +
/// chosen-skill state lives in [onboardingFlowControllerProvider]; the actual
/// auth side effects are delegated to [authControllerProvider]. On success we
/// do nothing — a go_router redirect swaps in the app shell automatically.
class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      onboardingFlowControllerProvider.select((s) => s.step),
    );
    final flow = ref.read(onboardingFlowControllerProvider.notifier);

    return AnimatedSwitcher(
      duration: Duration.zero,
      child: switch (step) {
        OnboardingStep.landing => _LandingStep(
          key: const ValueKey('landing'),
          onStartTest: flow.startLevelTest,
          onLogin: flow.showLogin,
        ),
        OnboardingStep.levelTest => _LevelTestStep(
          // Re-keyed per question so each swaps with its own transition.
          key: ValueKey(
            'quiz-${ref.watch(onboardingFlowControllerProvider.select((s) => s.currentQuestion))}',
          ),
          onAnswer: flow.answerQuestion,
          onBack: flow.back,
        ),
        OnboardingStep.levelResult => _LevelResultStep(
          key: const ValueKey('result'),
          onContinue: flow.proceedToSignUp,
          onBack: flow.back,
        ),
        OnboardingStep.signUp => _SignUpStep(
          key: const ValueKey('signup'),
          onBack: flow.back,
        ),
        OnboardingStep.login => _LoginStep(
          key: const ValueKey('login'),
          onBack: flow.back,
          onForgotPassword: flow.showForgotPassword,
        ),
        OnboardingStep.forgotPassword => _ForgotPasswordStep(
          key: const ValueKey('forgot'),
          onBack: flow.back,
        ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 · Landing
// ─────────────────────────────────────────────────────────────────────────────

class _LandingStep extends StatelessWidget {
  const _LandingStep({
    required this.onStartTest,
    required this.onLogin,
    super.key,
  });

  final VoidCallback onStartTest;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OnboardingScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand mark on a floating glass tile — mirrors landing_screen.dart.
          Align(
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              shape: const LiquidRoundedSuperellipse(borderRadius: 32),
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'PikaCircle',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'What level of pickleball player are you… really?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Take our 5-question assessment and we'll match you to the right circle.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          OnboardingPrimaryButton(label: 'Find my circle', onTap: onStartTest),
          const SizedBox(height: 14),
          OnboardingSecondaryButton(
            label: 'I already have an account',
            onTap: onLogin,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 · Level test
// ─────────────────────────────────────────────────────────────────────────────

class _LevelTestStep extends ConsumerWidget {
  const _LevelTestStep({
    required this.onAnswer,
    required this.onBack,
    super.key,
  });

  final ValueChanged<int> onAnswer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final index = ref.watch(
      onboardingFlowControllerProvider.select((s) => s.currentQuestion),
    );
    final total = onboardingQuestions.length;
    final question = onboardingQuestions[index];

    return OnboardingScaffold(
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingProgressBar(filled: index + 1, total: total),
          const SizedBox(height: 12),
          Text(
            '${index + 1} of $total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Text(
              question.prompt,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < question.options.length; i++) ...[
            _AnswerTile(
              letter: _letters[i],
              label: question.options[i],
              onTap: () => onAnswer(i),
            ),
            if (i < question.options.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  static const _letters = ['A', 'B', 'C', 'D'];
}

/// A tappable glass answer tile: an accent letter badge + the option label.
///
/// [GlassCard] has no tap handling, so it's wrapped in an [InkWell] sized to a
/// comfortable (>=48px) target. The badge uses a low-alpha primary fill so the
/// letter reads as a brand accent without fighting the glass.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.letter,
    required this.label,
    required this.onTap,
  });

  final String letter;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const shape = LiquidRoundedSuperellipse(borderRadius: 20);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          shape: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    letter,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 · Level result
// ─────────────────────────────────────────────────────────────────────────────

class _LevelResultStep extends ConsumerWidget {
  const _LevelResultStep({
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tier = ref.watch(
      onboardingFlowControllerProvider.select((s) => s.tier),
    );
    final accent = _tierAccent(tier, colorScheme);

    return OnboardingScaffold(
      onBack: onBack,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Circular tier badge.
          Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(
                color: accent.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
            child: Icon(_tierIcon(tier), size: 60, color: accent),
          ),
          const SizedBox(height: 28),
          Text(
            _tierHeadline(tier),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          // Level pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              'Level ${tier.tier} · ${tier.label}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _tierBody(tier),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OnboardingPrimaryButton(
              label: 'Create my account',
              onTap: onContinue,
            ),
          ),
        ],
      ),
    );
  }

  /// Tasteful, blue-anchored accents per tier — brighter and cooler as the
  /// tier climbs, staying within the glass system (no pinks).
  Color _tierAccent(PlayerTier tier, ColorScheme scheme) {
    return switch (tier) {
      PlayerTier.openPlay => const Color(
        0xFF0E9F6E,
      ), // fresh green — starting out
      PlayerTier.socialCircle => scheme.primary, // brand blue
      PlayerTier.competitiveCircle => const Color(0xFF6366F1), // indigo
      PlayerTier.eliteCircle => const Color(
        0xFF8B5CF6,
      ), // violet — matches shell
    };
  }

  IconData _tierIcon(PlayerTier tier) {
    return switch (tier) {
      PlayerTier.openPlay => Icons.sports_tennis_rounded,
      PlayerTier.socialCircle => Icons.groups_rounded,
      PlayerTier.competitiveCircle => Icons.emoji_events_rounded,
      PlayerTier.eliteCircle => Icons.star_rounded,
    };
  }

  String _tierHeadline(PlayerTier tier) {
    return switch (tier) {
      PlayerTier.openPlay => "You're just getting\nstarted — and that's great.",
      PlayerTier.socialCircle => "You're a solid social\nplayer.",
      PlayerTier.competitiveCircle => "You're playing below\nyour real level.",
      PlayerTier.eliteCircle => "You're playing at an\nelite level.",
    };
  }

  String _tierBody(PlayerTier tier) {
    return switch (tier) {
      PlayerTier.openPlay =>
        "Get into better games with PikaCircle. We'll match you into Open Play so every session helps you level up.",
      PlayerTier.socialCircle =>
        "Get into better games with PikaCircle. We'll match you with your Social Circle so every session counts.",
      PlayerTier.competitiveCircle =>
        "Get into better games with PikaCircle. We'll match you into a Competitive Circle so every session counts.",
      PlayerTier.eliteCircle =>
        "Get into better games with PikaCircle. We'll match you into the Elite Circle against players who push you.",
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 · Sign up
// ─────────────────────────────────────────────────────────────────────────────

class _SignUpStep extends ConsumerStatefulWidget {
  const _SignUpStep({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<_SignUpStep> createState() => _SignUpStepState();
}

class _SignUpStepState extends ConsumerState<_SignUpStep> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 8;

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();
    final skillLevel = ref.read(onboardingFlowControllerProvider).skillLevel;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          skillLevel: skillLevel,
        );
    _handleFailure(failure);
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    final skillLevel = ref.read(onboardingFlowControllerProvider).skillLevel;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(skillLevel: skillLevel);
    _handleFailure(failure);
  }

  void _handleFailure(Failure? failure) {
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
    // On success the router redirect swaps to the shell automatically.
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return OnboardingScaffold(
      title: 'Create account',
      onBack: widget.onBack,
      backEnabled: !isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingHeading(
            title: 'Get into better games',
            subtitle:
                "Create your account and we'll match you into the right circle.",
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            shape: const LiquidRoundedSuperellipse(borderRadius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassFormField(
                  label: 'Name',
                  child: OnboardingGlassInput(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    enabled: !isLoading,
                    onChanged: (_) => setState(() {}),
                    hintText: 'Your name',
                  ),
                ),
                const SizedBox(height: 20),
                GlassFormField(
                  label: 'Email',
                  child: OnboardingGlassInput(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !isLoading,
                    onChanged: (_) => setState(() {}),
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 20),
                GlassFormField(
                  label: 'Password',
                  helperText: 'At least 8 characters.',
                  child: OnboardingGlassInput(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !isLoading,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) =>
                        (isLoading || !_canSubmit) ? null : _submitEmail(),
                    hintText: 'Create a password',
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 20),
            OnboardingInlineError(message: _error!),
          ],
          const SizedBox(height: 24),
          OnboardingPrimaryButton(
            label: 'Get into better games',
            onTap: _submitEmail,
            enabled: _canSubmit,
            isLoading: isLoading,
          ),
          const SizedBox(height: 20),
          const OnboardingOrDivider(label: 'or continue with'),
          const SizedBox(height: 20),
          OnboardingGoogleButton(onTap: _submitGoogle, enabled: !isLoading),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 · Login
// ─────────────────────────────────────────────────────────────────────────────

class _LoginStep extends ConsumerStatefulWidget {
  const _LoginStep({
    required this.onBack,
    required this.onForgotPassword,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<_LoginStep> createState() => _LoginStepState();
}

class _LoginStepState extends ConsumerState<_LoginStep> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    _handleFailure(failure);
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(skillLevel: 'beginner');
    _handleFailure(failure);
  }

  void _handleFailure(Failure? failure) {
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
    // On success the router redirect swaps to the shell automatically.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return OnboardingScaffold(
      title: 'Sign in',
      onBack: widget.onBack,
      backEnabled: !isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingHeading(
            title: 'Welcome back',
            subtitle: 'Sign in to get back to your circle.',
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            shape: const LiquidRoundedSuperellipse(borderRadius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassFormField(
                  label: 'Email',
                  child: OnboardingGlassInput(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !isLoading,
                    onChanged: (_) => setState(() {}),
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 20),
                GlassFormField(
                  label: 'Password',
                  child: OnboardingGlassInput(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    enabled: !isLoading,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) =>
                        (isLoading || !_canSubmit) ? null : _submitEmail(),
                    hintText: 'Your password',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : widget.onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'I forgot my password',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            OnboardingInlineError(message: _error!),
          ],
          const SizedBox(height: 20),
          OnboardingPrimaryButton(
            label: 'Sign in',
            onTap: _submitEmail,
            enabled: _canSubmit,
            isLoading: isLoading,
          ),
          const SizedBox(height: 20),
          const OnboardingOrDivider(label: 'or'),
          const SizedBox(height: 20),
          OnboardingGoogleButton(onTap: _submitGoogle, enabled: !isLoading),
          const SizedBox(height: 20),
          Center(
            child: OnboardingSecondaryButton(
              label: 'New here? Find my circle first',
              onTap: isLoading
                  ? () {}
                  : ref
                        .read(onboardingFlowControllerProvider.notifier)
                        .showLanding,
              enabled: !isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 · Forgot password
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordStep extends ConsumerStatefulWidget {
  const _ForgotPasswordStep({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<_ForgotPasswordStep> createState() =>
      _ForgotPasswordStepState();
}

class _ForgotPasswordStepState extends ConsumerState<_ForgotPasswordStep> {
  final _emailController = TextEditingController();
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _emailController.text.trim().isNotEmpty;

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final failure = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordRecovery(_emailController.text.trim());

    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    setState(() {
      _sent = true;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return OnboardingScaffold(
      title: 'Reset password',
      onBack: widget.onBack,
      backEnabled: !isLoading,
      child: _sent
          ? _SentConfirmation(onBack: widget.onBack)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OnboardingHeading(
                  title: 'Forgot your password?',
                  subtitle:
                      "Enter your email and we'll send you a link to reset it.",
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                  child: GlassFormField(
                    label: 'Email',
                    child: OnboardingGlassInput(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      enabled: !isLoading,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) =>
                          (isLoading || !_canSubmit) ? null : _send(),
                      hintText: 'you@example.com',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  OnboardingInlineError(message: _error!),
                ],
                const SizedBox(height: 24),
                OnboardingPrimaryButton(
                  label: 'Send reset link',
                  onTap: _send,
                  enabled: _canSubmit,
                  isLoading: isLoading,
                ),
              ],
            ),
    );
  }
}

/// The "check your inbox" state shown after a recovery email is sent.
class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Align(
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            shape: const LiquidRoundedSuperellipse(borderRadius: 28),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 56,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent you a password reset link. Check your spam folder if you don't see it.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OnboardingPrimaryButton(
            label: 'Back to sign in',
            onTap: onBack,
          ),
        ),
      ],
    );
  }
}
