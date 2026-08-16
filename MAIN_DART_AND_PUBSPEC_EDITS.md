# Edits needed outside the new/replaced files

Two tiny, additive edits — nothing existing is removed or changed in behavior
except the one new route.

## 1. pubspec.yaml — add one dependency

Under `dependencies:`, alongside `http` and `flutter_secure_storage`, add:

```yaml
  shared_preferences: ^2.3.2
```

Then run `flutter pub get`.

(Used only to remember "onboarding intro already shown" — a boolean flag,
nothing sensitive, so `shared_preferences` is the right tool rather than
`flutter_secure_storage`.)

## 2. main.dart — register the onboarding route

Add this import near the other screen imports:

```dart
import 'screens/onboarding/onboarding_page.dart';
```

Then add one new `case` to the `onGenerateRoute` switch, right after the
`SessionCheckPage.routeName` case:

```dart
          case OnboardingPage.routeName:
            return MaterialPageRoute(builder: (_) => const OnboardingPage());
```

That's the entire diff to `main.dart` — `initialRoute` stays
`SessionCheckPage.routeName`, exactly as before. `SessionCheckPage` (replaced
in this drop) is what decides whether to send a first-time user to
`/onboarding` or straight to `/landing`.

## Files in this drop and what they touch

- `screens/onboarding/onboarding_data.dart` — new, standalone content.
- `screens/onboarding/onboarding_page.dart` — new, standalone screen.
- `screens/landing_page.dart` — **full replacement**. Same class name,
  same `routeName`, same `_selectRole` logic and navigation target — only
  the visuals changed (gradient hero band, trust-checkmark row, pill-shaped
  buttons). Drop-in replacement for your existing file.
- `screens/session_check_page.dart` — **full replacement**. Same class,
  same routeName, same `/auth/me` session-check logic — the only change is
  where it navigates to when there's no valid session (onboarding-once vs.
  straight to landing, instead of always straight to landing).

Nothing in `core/`, `services/`, or any backend file was touched.
