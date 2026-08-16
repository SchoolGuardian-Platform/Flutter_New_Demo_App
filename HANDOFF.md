# SchoolGuardian Flutter app — this delivery

Scope: **Flutter app (`lib/` + `assets/`) only.** Nothing under `src/`,
`prisma/`, `tests/`, `package.json`, or the OpenAPI spec was touched, so
this can be merged without conflicting with the backend work in
Colab/another branch.

Per your instructions this was stopped at roughly the halfway point of
the full request — below is exactly what's done and what's left.

## 1. The core bug: "admin never sees the request" — FIXED

The pending-approval screen (`screens/admin/pending_approvals_page.dart`)
already existed and already called the right backend endpoints. The
actual bug was that **nothing linked to it**:

- It had no route registered in `main.dart`.
- The admin dashboard's "Pending Approvals" card was plain, non-tappable
  text.

Both are fixed:
- `main.dart` now routes `PendingApprovalsPage`, `AdminNotificationsPage`,
  `ManageUsersPage`, `AdminProfilePage`, and `ReportsPage`.
- Every admin dashboard card is now tappable and opens the real screen.
- The pending-approvals screen gained a 4th tab, **Guardian Links**, for
  `/admin/relationships/pending` — this existed on the backend but had no
  Flutter UI at all before.

## 2. Admin notifications — NEW

`AdminService.getPendingSummary()` fetches all four `GET .../pending`
endpoints in parallel and folds them into one `PendingSummary`. This
powers:
- A badge on the notification bell in the dashboard's app bar.
- `AdminNotificationsPage` — a real feed, one card per pending item,
  tapping one jumps straight to the right tab in Pending Approvals.

This intentionally does **not** depend on the OpenAPI spec's
`/notifications` endpoint — that one is marked
`x-implementation-status: planned` (not live yet). It'll keep working
unchanged once that endpoint ships.

## 3. Manage Users — NEW

`ManageUsersPage` is a hub showing live counts per category
(Students / Parents / Teachers / Guardian Links) with a tap-through to
each queue. **Scope note:** the backend has no "list all existing
accounts" endpoint yet (only pending + get-by-id + approve/reject), so
this currently focuses on what needs a decision. A searchable directory
of already-active accounts is a follow-up once that endpoint exists.

## 4. Admin profile — NEW

`AdminProfilePage` reuses `GET /auth/me` (already implemented, already
used elsewhere) — no backend change needed. Read-only for now; there's
no profile-edit endpoint yet.

## 5. Reports — NEW (scaffold)

`ReportsPage` lists the three report categories the OpenAPI spec
promises (academic / attendance / wellbeing). All three
`/reports/student/:id/*` endpoints are marked `planned` on the backend,
so this deliberately shows a "coming soon" state instead of firing
requests that would 404 today. Swapping in real data later is a small
change, not a rewrite.

## 6. Logo — swapped in

`widgets/app_logo.dart` now renders the actual crest artwork
(`assets/images/logo.png`) instead of a generic Material shield icon,
everywhere the app shows the brand mark (login, signup, dashboard app
bar, session-check splash, profile). Falls back to the old icon if the
asset ever fails to load, so a missing pubspec entry can't crash the app.

**You need to add this to your `pubspec.yaml`** (not included in this
delivery since no `pubspec.yaml` was uploaded to work from):
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png
```
If you're also setting this as the native app icon (home-screen icon),
that's a separate step using a package like `flutter_launcher_icons` —
not done here since it touches platform-native folders (`android/`,
`ios/`) that weren't part of this upload.

## 7. Visual redesign — partial

The dashboard and every new admin/reports screen now use the
**Kukie-referenced style** (`theme/kukie_accent.dart` — soft violet
accents, rounded cards, circular icon chips) that was previously only
applied to onboarding and the role-select landing page. Tappable
dashboard cards, the Manage Users hub, and the notification feed all use
it consistently now.

**Not yet redone in this pass** (this is most of the remaining ~50%):
- Sign-up, forgot-password, reset-password, account-rejected, and
  unauthorized screens are still on the original "Guardian Core" palette
  (`theme/app_theme.dart`) rather than the Kukie look.
- No unified decision yet on whether Kukie violet should fully replace
  the primary indigo in `app_theme.dart` globally, or stay a
  deliberately separate accent (see the original comment in
  `kukie_accent.dart` — worth a quick call before touching every screen,
  since it changes the brand color everywhere).

## Everything else from the original ask, not started this pass

- Parent/Student/Teacher "Linked Students / Guardians / Classes" cards
  still just name a route — no service layer built for
  `/parents/*` or `/students/*` yet (only used what already existed:
  `my-students`, `my-guardians`).
- Full native app-icon replacement (Android/iOS asset generation).

## Files touched or added

```
lib/main.dart                                  (routes registered)
lib/widgets/app_logo.dart                      (real crest asset)
lib/services/admin_service.dart                (+ relationships, + getPendingSummary)
lib/models/relationship.dart                   (new)
lib/screens/admin/pending_approvals_page.dart  (+ Guardian Links tab)
lib/screens/admin/admin_notifications_page.dart (new)
lib/screens/admin/manage_users_page.dart        (new)
lib/screens/admin/admin_profile_page.dart       (new)
lib/screens/reports/reports_page.dart           (new)
lib/screens/dashboard/dashboard_page.dart       (bell + wired cards + Kukie style)
assets/images/logo.png                          (new — the uploaded crest)
```
