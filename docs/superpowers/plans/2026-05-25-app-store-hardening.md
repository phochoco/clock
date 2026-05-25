# App Store Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current App Store/Google Play clock-learning app safer to ship by fixing core learning correctness, child-directed ads configuration, privacy surfaces, and release verification blockers.

**Architecture:** Keep changes scoped to the existing Flutter app. Extract shared clock-answer validation into a small utility, harden AdMob initialization globally, add an in-app guardian/privacy surface, and clean release/analyzer blockers without broad rewrites.

**Tech Stack:** Flutter/Dart, google_mobile_ads, shared_preferences, platform iOS/Android project settings.

---

### Task 1: Clock Learning Correctness

**Files:**
- Create: `lib/utils/clock_answer_validator.dart`
- Create: `test/clock_answer_validator_test.dart`
- Modify: `lib/widgets/analog_clock.dart`
- Modify: `lib/screens/quiz_screen.dart`
- Modify: `lib/screens/story_mode_screen.dart`
- Modify: `lib/screens/time_attack_screen.dart`
- Modify: `lib/screens/daily_challenge_screen.dart`

- [ ] Add failing tests proving same-minute/wrong-hour answers are rejected and wraparound hour/minute answers are accepted.
- [ ] Implement `ClockAnswerValidator.isCorrect`.
- [ ] Add `AnalogClock.notifyInitialTime` so answer screens do not become answerable before a child touches the clock.
- [ ] Replace per-screen duplicated answer checks with the validator.

### Task 2: Child-Safe Ads And Privacy Surface

**Files:**
- Modify: `lib/services/ad_service.dart`
- Modify: `lib/screens/lobby_screen.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `privacy_policy.md`
- Modify: `docs/index.html`
- Modify: `docs/support.html`
- Modify: `pubspec.yaml`

- [ ] Configure AdMob request settings before SDK initialization with child-directed treatment and General max ad content rating.
- [ ] Remove unused ATT dependency unless explicit tracking is implemented.
- [ ] Add an in-app guardian/privacy dialog with no external child-facing link.
- [ ] Update privacy wording so AdMob third-party SDK handling is disclosed honestly.

### Task 3: Design And UX Stabilization

**Files:**
- Modify: `lib/screens/lobby_screen.dart`
- Modify: `lib/screens/game_mode_screen.dart`
- Modify: `lib/screens/reward_screen.dart`
- Modify: `lib/screens/playground_screen.dart`
- Modify: `lib/screens/time_snap_screen.dart`
- Modify: `lib/screens/story_mode_screen.dart`
- Modify: `lib/widgets/digital_display.dart`

- [ ] Remove negative letter spacing.
- [ ] Make primary clock and digital display sizes responsive on smaller screens.
- [ ] Replace commercial "purchase" wording with star-unlock wording.
- [ ] Make rewarded ads clearly guardian-facing.

### Task 4: Release Hygiene

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/gradle.properties`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Delete or exclude: root temporary analyzer files as appropriate.

- [ ] Restore suspicious iOS asset setting values.
- [ ] Revisit Android release settings and distinguish code issues from local toolchain issues.
- [ ] Remove temporary analyzer blockers and trailing whitespace.
- [ ] Run `flutter test`, `flutter analyze lib test`, `flutter build apk --release`, and `flutter build appbundle --release`.
