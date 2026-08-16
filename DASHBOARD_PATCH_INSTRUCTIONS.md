# Minimal edit to dashboard_page.dart

Only 4 small, additive changes. Nothing in the API/auth layer is touched.

## 1. Add an import near the top (with the other imports)

```dart
import '../admin/pending_approvals_page.dart';
```

## 2. Give `_SectionSpec` an optional `onTap`

Find:
```dart
class _SectionSpec {
  const _SectionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
```

Replace with:
```dart
class _SectionSpec {
  const _SectionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final VoidCallback? onTap;
}
```

## 3. Wire the "Pending Approvals" admin card to navigate

Find (inside `_RoleSections._sections`, the `UserRole.admin` case):
```dart
      case UserRole.admin:
        return const [
          _SectionSpec(
            icon: Icons.fact_check_outlined,
            title: 'Pending Approvals',
            subtitle: 'Review and approve or reject new accounts.',
            route: 'GET /admin/accounts/pending, POST /admin/accounts/:id/approve',
          ),
```

Replace with (note: `_sections` can no longer be a `const` getter body once one entry needs a
non-const closure, so also drop the leading `const` on that one `return`):
```dart
      case UserRole.admin:
        return [
          _SectionSpec(
            icon: Icons.fact_check_outlined,
            title: 'Pending Approvals',
            subtitle: 'Review and approve or reject new accounts.',
            route: 'GET /admin/{role}/pending, PATCH /admin/{role}/:id/approve',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PendingApprovalsPage()),
            ),
          ),
```

This requires `_RoleSections.build` to have a `context` in scope where `_sections` is read —
it already does, since `_sections` is read inside `build(BuildContext context)`. If `_sections`
is a getter (not a method), turn it into a method taking `BuildContext context` instead, and
update the one call site (`_sections` -> `_sections(context)`) in `build`.

## 4. Make `_SectionCard` tappable

Find:
```dart
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.spec});

  final _SectionSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
```

Replace with:
```dart
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.spec});

  final _SectionSpec spec;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
```

Then find the closing of that `Container(...)` (the matching `);` right before the final
closing `}` of `build`) and wrap it:

```dart
    );

    if (spec.onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: spec.onTap,
      child: content,
    );
  }
}
```

(replacing the old bare `return Container(...);` ending).

That's the whole diff — every other card (Linked Students, My Profile, My Classes, Manage
Accounts, etc.) keeps `onTap: null` and renders exactly as before, un-tappable.
