import 'package:flutter/material.dart';
import '../theme/kukie_accent.dart';

class PortalSidebar extends StatelessWidget {
  const PortalSidebar({
    super.key,
    required this.selectedRoute,
    required this.userName,
    required this.userRole,
    required this.onSelectRoute,
  });

  final String selectedRoute;
  final String userName;
  final String userRole;
  final ValueChanged<String> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KukieAccent.violetTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: KukieAccent.violet, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'UniConnect',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'MENU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          // Menu Items List
          Expanded(
            child: ListView(
              children: [
                _navItem('Dashboard', Icons.grid_view_rounded, '/dashboard'),
                _navItem('Schedule', Icons.calendar_today_outlined, '/schedule'),
                _navItem('Portfolio', Icons.folder_open_outlined, '/portfolio'),
                _navItem('Resources', Icons.menu_book_outlined, '/resources'),
                _navItem('Forum', Icons.chat_bubble_outline, '/forum'),
                _navItem('Settings', Icons.settings_outlined, '/settings'),
              ],
            ),
          ),

          // Collapsible/Floating Profile Card at Bottom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: KukieAccent.violetTint,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: KukieAccent.violet,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, String route) {
    final isSelected = selectedRoute == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () => onSelectRoute(route),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? KukieAccent.violetTint : Colors.transparent,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? KukieAccent.violet : const Color(0xFF6B7280),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? KukieAccent.violet : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
