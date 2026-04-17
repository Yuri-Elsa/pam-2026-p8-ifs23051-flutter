// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/nebula_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().authToken;
      if (token != null) {
        context.read<TodoProvider>().loadTodos(authToken: token);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<TodoProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final total = provider.totalTodos;
    final done = provider.doneTodos;
    final pending = provider.pendingTodos;
    final progress = total > 0 ? done / total : 0.0;

    // Nebula colors
    const nebulaViolet = Color(0xFF6C3DE1);
    const nebulaBlue = Color(0xFF0EA5E9);
    const nebulaPink = Color(0xFFDB2777);
    const nebulaTeal = Color(0xFF0D9488);

    return Scaffold(
      body: NebulaBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final token = context.read<AuthProvider>().authToken;
            if (token != null) {
              await context.read<TodoProvider>().loadTodos(authToken: token);
            }
          },
          child: CustomScrollView(
            slivers: [
              // ── Nebula AppBar ──
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: Icon(
                      themeProvider.isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                    tooltip: themeProvider.isDark ? 'Mode Terang' : 'Mode Gelap',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user?.name ?? '—'} ✨',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Jelajahi galaksi todo-mu',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3B1181),
                          Color(0xFF6C3DE1),
                          Color(0xFF9D174D),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Nebula cloud overlay in header
                        Positioned(
                          right: -40,
                          top: -30,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00D4FF).withOpacity(0.08),
                            ),
                          ),
                        ),
                        // Stars decoration
                        ..._headerStars(),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Card
                          _NebulaProgressCard(
                            total: total,
                            done: done,
                            pending: pending,
                            progress: progress,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // Stat Cards
                          Row(
                            children: [
                              _NebulaStatCard(
                                label: 'Total',
                                value: total,
                                primaryColor: nebulaViolet,
                                icon: Icons.auto_awesome_rounded,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _NebulaStatCard(
                                label: 'Selesai',
                                value: done,
                                primaryColor: nebulaTeal,
                                icon: Icons.check_circle_rounded,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _NebulaStatCard(
                                label: 'Belum',
                                value: pending,
                                primaryColor: nebulaPink,
                                icon: Icons.pending_rounded,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Section header
                          Text(
                            'Navigasi Cepat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFFE8E0FF)
                                  : const Color(0xFF1A1035),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick access cards
                          _NebulaQuickCard(
                            icon: Icons.checklist_rounded,
                            title: 'Daftar Todo',
                            subtitle: 'Lihat dan kelola semua todo-mu',
                            colors: const [Color(0xFF3B1181), Color(0xFF6C3DE1)],
                            onTap: () => context.go(RouteConstants.todos),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _NebulaQuickCard(
                            icon: Icons.add_task_rounded,
                            title: 'Tambah Todo Baru',
                            subtitle: 'Buat tugas baru di antariksa',
                            colors: const [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
                            onTap: () => context.push(RouteConstants.todosAdd),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _NebulaQuickCard(
                            icon: Icons.person_rounded,
                            title: 'Profil Saya',
                            subtitle: 'Pengaturan akun penjelajah',
                            colors: const [Color(0xFF831843), Color(0xFFDB2777)],
                            onTap: () => context.go(RouteConstants.profile),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _headerStars() {
    return [
      const Positioned(top: 30, right: 80, child: _StarDot(size: 2.5)),
      const Positioned(top: 50, right: 120, child: _StarDot(size: 1.5)),
      const Positioned(top: 25, right: 160, child: _StarDot(size: 2)),
      const Positioned(top: 70, right: 40, child: _StarDot(size: 1.8)),
      const Positioned(top: 40, left: 60, child: _StarDot(size: 1.5)),
      const Positioned(top: 65, left: 100, child: _StarDot(size: 2)),
      const Positioned(top: 20, left: 140, child: _StarDot(size: 1.2)),
    ];
  }
}

class _StarDot extends StatelessWidget {
  const _StarDot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }
}

class _NebulaProgressCard extends StatelessWidget {
  const _NebulaProgressCard({
    required this.total,
    required this.done,
    required this.pending,
    required this.progress,
    required this.isDark,
  });

  final int total;
  final int done;
  final int pending;
  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? const Color(0xFF160F2E).withOpacity(0.9)
            : Colors.white.withOpacity(0.8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D2A6B).withOpacity(0.5)
              : const Color(0xFF6C3DE1).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Kosmik',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFFE8E0FF)
                      : const Color(0xFF1A1035),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3DE1), Color(0xFF9D174D)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF3D2A6B)
                  : const Color(0xFFE0D8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9D6FFF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$done dari $total selesai',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF9D6FFF)
                      : const Color(0xFF6C3DE1),
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  progress == 1.0
                      ? '🌌 Semua selesai!'
                      : '$pending menunggu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF7A6AAF)
                        : const Color(0xFF8A7AAF),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NebulaStatCard extends StatelessWidget {
  const _NebulaStatCard({
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final int value;
  final Color primaryColor;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? const Color(0xFF160F2E).withOpacity(0.9)
              : Colors.white.withOpacity(0.8),
          border: Border.all(
            color: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: primaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NebulaQuickCard extends StatelessWidget {
  const _NebulaQuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}