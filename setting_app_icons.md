# What changed

## 1. Pending approvals no longer disappear after a decision
**File:** `lib/screens/admin/pending_approvals_page.dart` (+ `lib/models/user.dart`,
`lib/models/relationship.dart` for a new `copyWith`)

Before: approving/rejecting called `removeWhere(...)`, so the row vanished
from the list immediately.

Now: the row is updated in place — its status flips to **Approved** /
**Rejected** and it stays visible in the same tab, with:
- the status badge updated (green "Approved" / red "Rejected")
- a small check/cancel icon instead of the ">" arrow, since it's no longer
  actionable
- the row dimmed slightly (70% opacity) to show it's resolved
- tapping a resolved row shows "already approved/rejected" instead of
  reopening the approve/reject dialog

I left the **Notifications** page (`admin_notifications_page.dart`) as-is —
that one is a feed of "things waiting on you," so removing an item once
you've acted on it still makes sense there. Only the "Manage Users →
category list" (`pending_approvals_page.dart`) got the persistent-status
treatment.

## 2. Real logo on the profile page instead of a blue silhouette
**File:** `lib/screens/admin/admin_profile_page.dart`

The profile page called `AppLogoBadge(size: 88, filled: true)`. `filled:
true` runs the crest through a `ColorFiltered` that recolors every pixel
to solid indigo (`AppColors.primary`) — that's the "blue logo" you're
seeing, not a rendering bug with the asset itself. Changed it to
`AppLogoBadge(size: 88)` (`filled` defaults to `false`), which renders the
actual navy/gold crest artwork.

## 3. App icon
`assets/images/logo.png` isn't square and has "SCHOOL GUARDIAN 2026" text
baked in, which reads fine at 800px but turns to mush at 48px on a home
screen — so I generated two purpose-built square icons from it instead of
reusing it directly:

- `assets/images/app_icon.png` — 1024×1024, opaque white background, crest
  centered with padding. Use this as the base icon for iOS and older
  Android.
- `assets/images/app_icon_foreground.png` — 1024×1024, transparent
  background, crest centered in the ~66% "safe zone" Android adaptive
  icons require (Android crops/masks the outer edge into a circle/squircle
  depending on the launcher, so content outside that zone gets clipped).

**Important:** none of `pubspec.yaml`, `android/`, or `ios/` were in this
upload, so I couldn't wire these into the actual launcher config myself —
only `lib/`, `prisma/`, `src/`, `tests/`, and `assets/` were included. Here's
what to add once you drop these files in:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"

flutter:
  assets:
    - assets/images/logo.png
    - assets/images/app_icon.png
    - assets/images/app_icon_foreground.png
```

Then run:
```
flutter pub get
flutter pub run flutter_launcher_icons
```
That generates every required Android (`mipmap-*`) and iOS
(`AppIcon.appiconset`) size automatically — no manual resizing needed.

If `pubspec.yaml` already exists in your repo and already registers
`assets/images/logo.png` (the `AppLogoBadge` doc comment implies it does),
just add the `flutter_launcher_icons` block and the two new asset lines
above to it.