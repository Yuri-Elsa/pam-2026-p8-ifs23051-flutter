// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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
    final colorScheme   = Theme.of(context).colorScheme;
    final user          = context.watch<AuthProvider>().user;
    final provider      = context.watch<TodoProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark        = themeProvider.isDark;

    final total   = provider.totalTodos;
    final done    = provider.doneTodos;
    final pending = provider.pendingTodos;
    final progress = total > 0 ? done / total : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().authToken;
          if (token != null) {
            await context.read<TodoProvider>().loadTodos(authToken: token);
          }
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero Header ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?.name ?? '—'} 👋',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Kelola todo-mu hari ini',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.tertiary.withOpacity(0.5),
                      ]
                          : [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        bottom: 20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body Content ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Progress Card ──
                        _ProgressCard(
                          total: total,
                          done: done,
                          pending: pending,
                          progress: progress,
                        ),
                        const SizedBox(height: 20),

                        // ── Stat Cards Row ──
                        Row(
                          children: [
                            _StatCard(
                              label: 'Total',
                              value: total,
                              color: colorScheme.primary,
                              icon: Icons.list_alt_rounded,
                              bgColor: colorScheme.primaryContainer.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'Selesai',
                              value: done,
                              color: const Color(0xFF4CAF50),
                              icon: Icons.check_circle_rounded,
                              bgColor: const Color(0xFF4CAF50).withOpacity(0.1),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'Belum',
                              value: pending,
                              color: const Color(0xFFFF9800),
                              icon: Icons.pending_rounded,
                              bgColor: const Color(0xFFFF9800).withOpacity(0.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Akses Cepat ──
                        Text(
                          'Akses Cepat',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _QuickAccessCard(
                          icon: Icons.checklist_rounded,
                          title: 'Daftar Todo',
                          subtitle: 'Lihat dan kelola semua todo-mu',
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                          ),
                          onTap: () => context.go(RouteConstants.todos),
                        ),
                        const SizedBox(height: 10),
                        _QuickAccessCard(
                          icon: Icons.add_task_rounded,
                          title: 'Tambah Todo Baru',
                          subtitle: 'Buat tugas baru untuk diselesaikan',
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4CAF50),
                              const Color(0xFF4CAF50).withOpacity(0.7),
                            ],
                          ),
                          onTap: () => context.push(RouteConstants.todosAdd),
                        ),
                        const SizedBox(height: 10),
                        _QuickAccessCard(
                          icon: Icons.person_rounded,
                          title: 'Profil Saya',
                          subtitle: 'Kelola akun dan pengaturan',
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF9C27B0),
                              const Color(0xFF9C27B0).withOpacity(0.7),
                            ],
                          ),
                          onTap: () => context.go(RouteConstants.profile),
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
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.total,
    required this.done,
    required this.pending,
    required this.progress,
  });

  final int total;
  final int done;
  final int pending;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).toStringAsFixed(0);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress Todo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: colorScheme.primary,
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
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  total == 0
                      ? colorScheme.outline
                      : progress == 1.0
                      ? const Color(0xFF4CAF50)
                      : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ProgressLegend(
                  color: colorScheme.primary,
                  label: '$done dari $total selesai',
                ),
                const Spacer(),
                if (total > 0)
                  Text(
                    progress == 1.0 ? '🎉 Semua selesai!' : '$pending belum selesai',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.bgColor,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

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
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.85),
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