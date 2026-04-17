// lib/shared/widgets/bottom_nav_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';

class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget({super.key});

  static const _items = [
    _NavItem(RouteConstants.home,    'Home',   Icons.home_outlined,          Icons.home_rounded),
    _NavItem(RouteConstants.todos,   'Todos',  Icons.auto_awesome_outlined,  Icons.auto_awesome_rounded),
    _NavItem(RouteConstants.profile, 'Profil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0A1E) : const Color(0xFFF0EEFF),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF6C3DE1).withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (index) {
          if (index != selectedIndex) {
            context.go(_items[index].route);
          }
        },
        destinations: _items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon, this.activeIcon);
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}