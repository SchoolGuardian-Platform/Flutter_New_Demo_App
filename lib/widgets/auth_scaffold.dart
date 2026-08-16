import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Common page chrome for every auth screen: soft gradient background,
/// centered content column with a max width (so it looks right on tablet /
/// desktop as well as mobile), and consistent outer padding.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.fromLTRB(20, 32, 20, 32),
    this.showBackButton = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.background,
              Color(0xFFF1F6F1),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
              if (showBackButton)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White, rounded, soft-shadowed card used to contain form content — the
/// central "Level 1" surface described in the design system.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}
