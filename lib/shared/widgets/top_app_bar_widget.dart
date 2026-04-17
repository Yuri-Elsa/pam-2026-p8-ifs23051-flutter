// lib/shared/widgets/top_app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TopAppBarMenuItem {
  const TopAppBarMenuItem({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

class TopAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.menuItems = const [],
    this.showThemeToggle = true,
    this.withSearch = false,
    this.onSearchChanged,
    this.searchHint = 'Cari...',
  });

  final String title;
  final bool showBackButton;
  final List<TopAppBarMenuItem> menuItems;
  final bool showThemeToggle;
  final bool withSearch;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<TopAppBarWidget> createState() => _TopAppBarWidgetState();
}

class _TopAppBarWidgetState extends State<TopAppBarWidget> {
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() => _isSearching = false);
    _searchCtrl.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    // Nebula-themed AppBar colors
    final appBarBg = isDark ? const Color(0xFF0E0A1E) : const Color(0xFFF0EEFF);
    final primaryColor =
    isDark ? const Color(0xFF9D6FFF) : const Color(0xFF6C3DE1);
    final titleColor =
    isDark ? const Color(0xFFE8E0FF) : const Color(0xFF1A1035);

    if (_isSearching) {
      return AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: _closeSearch,
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: titleColor),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: widget.onSearchChanged,
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: primaryColor),
              onPressed: () {
                _searchCtrl.clear();
                widget.onSearchChanged?.call('');
                setState(() {});
              },
            ),
        ],
      );
    }

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nebula dot accent
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  isDark ? const Color(0xFFFF6EE7) : const Color(0xFFDB2777),
                ],
              ),
            ),
          ),
          Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: titleColor,
            ),
          ),
        ],
      ),
      centerTitle: false,
      automaticallyImplyLeading: widget.showBackButton,
      iconTheme: IconThemeData(color: primaryColor),
      actions: [
        if (widget.withSearch)
          IconButton(
            icon: Icon(Icons.search, color: primaryColor),
            tooltip: 'Cari',
            onPressed: () => setState(() => _isSearching = true),
          ),
        if (widget.showThemeToggle)
          IconButton(
            icon: Icon(
              isDark ? Icons.auto_awesome_outlined : Icons.nights_stay_rounded,
              color: primaryColor,
            ),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        if (widget.menuItems.isNotEmpty)
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: primaryColor),
            color: isDark ? const Color(0xFF1A1535) : Colors.white,
            onSelected: (i) => widget.menuItems[i].onTap(),
            itemBuilder: (_) => List.generate(
              widget.menuItems.length,
                  (i) => PopupMenuItem<int>(
                value: i,
                child: Row(
                  children: [
                    Icon(
                      widget.menuItems[i].icon,
                      size: 20,
                      color: widget.menuItems[i].isDestructive
                          ? Theme.of(context).colorScheme.error
                          : primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.menuItems[i].text,
                      style: TextStyle(
                        color: widget.menuItems[i].isDestructive
                            ? Theme.of(context).colorScheme.error
                            : (isDark
                            ? const Color(0xFFE8E0FF)
                            : const Color(0xFF1A1035)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}