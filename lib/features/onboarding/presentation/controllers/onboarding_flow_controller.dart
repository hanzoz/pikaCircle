import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The discrete screens the guided onboarding walks a signed-out user through.
///
/// The happy path is `landing → levelTest → levelResult → signUp`. A separate
/// returning-user path branches to `login`, which can itself open
/// `forgotPassword`. Every sub-step exposes a back affordance that pops one
/// level toward [landing].
enum OnboardingStep { landing, levelTest, levelResult, signUp, login, forgotPassword }

/// The four skill circles a player can be matched into, derived from the
/// five-question assessment.
///
/// [tier] is the 1-based rank shown in the UI ("Level 1"), [label] is the
/// circle's display name, and [skillLevel] is the value handed to the auth
/// controller on sign-up (`beginner` | `intermediate` | `competitive`).
enum PlayerTier {
  openPlay(tier: 1, label: 'Open Play', skillLevel: 'beginner'),
  socialCircle(tier: 2, label: 'Social Circle', skillLevel: 'beginner'),
  competitiveCircle(tier: 3, label: 'Competitive Circle', skillLevel: 'intermediate'),
  eliteCircle(tier: 4, label: 'Elite Circle', skillLevel: 'competitive');

  const PlayerTier({
    required this.tier,
    required this.label,
    required this.skillLevel,
  });

  final int tier;
  final String label;
  final String skillLevel;
}

/// A single assessment question and its four ordered answers.
///
/// Answers are ordered from lowest (index 0) to highest (index 3) skill signal;
/// the flow averages the chosen indices to place the player in a [PlayerTier].
@immutable
class OnboardingQuestion {
  const OnboardingQuestion({required this.prompt, required this.options});

  final String prompt;
  final List<String> options;
}

/// The verbatim five-question level assessment.
const List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    prompt: 'How long have you been playing pickleball?',
    options: [
      'Less than 3 months',
      '3 – 12 months',
      '1 – 3 years',
      'I play competitively',
    ],
  ),
  OnboardingQuestion(
    prompt: 'How often do you win games?',
    options: [
      'Rarely — still learning the basics',
      'About half the time',
      'Often — I compete to win',
      'Consistently at a high level',
    ],
  ),
  OnboardingQuestion(
    prompt: 'What type of players do you usually play with?',
    options: [
      'Anyone willing to play',
      'Friends at a similar level',
      'Intermediate or competitive players',
      'Serious players at competitive events',
    ],
  ),
  OnboardingQuestion(
    prompt: 'Do you get invited to games or do you join open sessions?',
    options: [
      "I join open sessions and whoever's available",
      'I occasionally get invited',
      "I'm often invited to curated games",
      'I organise or host my own games',
    ],
  ),
  OnboardingQuestion(
    prompt: 'How consistent is your performance?',
    options: [
      'Very inconsistent — still finding my game',
      'Fairly consistent with room to grow',
      'Consistent across different opponents',
      'Highly consistent — even under pressure',
    ],
  ),
];

/// Immutable snapshot of where the user is in the onboarding flow.
@immutable
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = OnboardingStep.landing,
    this.currentQuestion = 0,
    this.answers = const <int>[],
    this.skillLevel = 'beginner',
  });

  /// The screen currently on show.
  final OnboardingStep step;

  /// Index into [onboardingQuestions] of the question being asked.
  final int currentQuestion;

  /// The chosen answer index (0..3) for each answered question, in order.
  final List<int> answers;

  /// The skill level that will be sent on sign-up. Pre-filled from the
  /// assessment result but overridable via the sign-up skill selector.
  final String skillLevel;

  /// The tier the player's answers place them in. Defaults to the entry tier
  /// before any questions are answered.
  PlayerTier get tier {
    if (answers.isEmpty) return PlayerTier.openPlay;
    final average = answers.reduce((a, b) => a + b) / answers.length;
    if (average < 1.5) return PlayerTier.openPlay;
    if (average < 2.5) return PlayerTier.socialCircle;
    if (average < 3.5) return PlayerTier.competitiveCircle;
    return PlayerTier.eliteCircle;
  }

  OnboardingFlowState copyWith({
    OnboardingStep? step,
    int? currentQuestion,
    List<int>? answers,
    String? skillLevel,
  }) {
    return OnboardingFlowState(
      step: step ?? this.step,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      answers: answers ?? this.answers,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }
}

/// Drives step + quiz + chosen-skill state for the onboarding flow.
///
/// Intentionally local to the onboarding feature — it owns none of the auth
/// side effects (those live in `authControllerProvider`). It only records where
/// the user is and what they've picked so the screens can render and the
/// sign-up call can be handed the right `skillLevel`.
class OnboardingFlowController extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() => const OnboardingFlowState();

  /// Begin the five-question assessment from the first question.
  void startLevelTest() {
    state = const OnboardingFlowState(step: OnboardingStep.levelTest);
  }

  /// Show the returning-user login screen.
  void showLogin() {
    state = state.copyWith(step: OnboardingStep.login);
  }

  /// Return to the brand landing screen, clearing any assessment progress.
  void showLanding() {
    state = const OnboardingFlowState();
  }

  /// Open the password-recovery screen from login.
  void showForgotPassword() {
    state = state.copyWith(step: OnboardingStep.forgotPassword);
  }

  /// Record an answer (0..3) and advance — to the next question, or to the
  /// result screen once the final question is answered.
  void answerQuestion(int optionIndex) {
    if (state.step != OnboardingStep.levelTest) return;
    if (state.currentQuestion >= onboardingQuestions.length) return;

    final answers = [...state.answers, optionIndex];
    final isLast = state.currentQuestion >= onboardingQuestions.length - 1;

    state = state.copyWith(
      answers: answers,
      currentQuestion: isLast ? state.currentQuestion : state.currentQuestion + 1,
      step: isLast ? OnboardingStep.levelResult : OnboardingStep.levelTest,
    );
  }

  /// Step off the result screen into account creation, seeding the skill
  /// selector from the computed tier.
  void proceedToSignUp() {
    state = state.copyWith(
      step: OnboardingStep.signUp,
      skillLevel: state.tier.skillLevel,
    );
  }

  /// Override the skill level from the sign-up selector.
  void setSkillLevel(String skillLevel) {
    if (skillLevel == state.skillLevel) return;
    state = state.copyWith(skillLevel: skillLevel);
  }

  /// Go back one level toward [OnboardingStep.landing]. Used by the back
  /// affordance on the sub-steps.
  void back() {
    switch (state.step) {
      case OnboardingStep.forgotPassword:
        state = state.copyWith(step: OnboardingStep.login);
      case OnboardingStep.login:
      case OnboardingStep.levelTest:
      case OnboardingStep.levelResult:
        showLanding();
      case OnboardingStep.signUp:
        state = state.copyWith(step: OnboardingStep.levelResult);
      case OnboardingStep.landing:
        break;
    }
  }
}

/// Onboarding step + quiz + chosen-skill state.
///
/// Read the final chosen skill level with:
/// `ref.read(onboardingFlowControllerProvider).skillLevel`.
final onboardingFlowControllerProvider =
    NotifierProvider<OnboardingFlowController, OnboardingFlowState>(
  OnboardingFlowController.new,
);
