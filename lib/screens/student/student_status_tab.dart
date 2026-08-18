import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../widgets/bento_grid_section.dart';

/// Dedicated Status & Feature Modules Hub for Student Portal
class StudentStatusTab extends StatelessWidget {
  const StudentStatusTab({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(20),
      children: [
        // Bento Grid Section with all 5 Live Modules (GPA, Health, Calorie, Stress, etc.)
        BentoGridSection(user: user),
        const SizedBox(height: 24),
      ],
    );
  }
}
