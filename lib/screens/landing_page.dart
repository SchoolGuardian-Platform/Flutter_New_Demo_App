import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// "Select your role" landing screen styled to match the official SchoolGuardian
/// design system (AppTheme, AppColors, Plus Jakarta Sans, Bento cards, soft shadows).
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const routeName = '/landing';

  void _selectRole(BuildContext context, UserRole role) {
    Navigator.of(context).pushNamed('/login', arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.surfaceContainerLow,
              AppColors.primarySoftBg,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Navigation Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppWordmark(),
                  ],
                ),
              ),

              // Main Body Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.sm),

                          // Hero Card Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                                width: 1,
                              ),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Column(
                              children: [
                                // Top Hero Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs + 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoftBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Unified School Portal',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Hero Main Headline
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      letterSpacing: -0.5,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'A Safer, Smarter\n',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'School Community',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                Text(
                                  'Connect, monitor, and support learning in a '
                                  'secure environment. Select your role below to '
                                  'get to your dashboard.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Role Selection Header
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  'Who are you?',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Role Cards List
                          for (final role in UserRole.values) ...[
                            _RoleCard(
                              role: role,
                              highlighted: role == UserRole.parent,
                              onTap: () => _selectRole(context, role),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          const SizedBox(height: AppSpacing.lg),

                          // Security Badge Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: AppColors.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Role-based access & end-to-end encryption',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.role,
    required this.onTap,
    this.highlighted = false,
  });

  final UserRole role;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isHighlighted = widget.highlighted || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: isHighlighted ? 1.8 : 1,
                ),
                boxShadow: isHighlighted
                    ? AppColors.cardShadow
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppColors.primary
                          : AppColors.primarySoftBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.role.icon,
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.role.label,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            if (widget.highlighted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoftBg,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'Popular',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.role.description,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppColors.primarySoftBg
                          : AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: isHighlighted
                          ? AppColors.primary
                          : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
