// lib/features/todos/todos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../data/models/todo_model.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final token = context.read<AuthProvider>().authToken ?? '';
      context.read<TodoProvider>().loadMoreTodos(authToken: token);
    }
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken;
    if (token != null) context.read<TodoProvider>().loadTodos(authToken: token);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TodoProvider>();
    final token = context.read<AuthProvider>().authToken ?? '';

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (query) {
          context.read<TodoProvider>().updateSearchQuery(query);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push(RouteConstants.todosAdd)
            .then((_) => _loadData()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: const Color(0xFF6C3DE1),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Filter bar
          _NebulaFilterBar(
            selected: provider.filter,
            onSelected: (f) => context.read<TodoProvider>().setFilter(f),
            total: provider.totalTodos,
            done: provider.doneTodos,
            pending: provider.pendingTodos,
            isDark: isDark,
          ),

          // Content
          Expanded(
            child: switch (provider.status) {
              TodoStatus.loading when provider.todos.isEmpty =>
              const LoadingWidget(message: 'Memuat todo...'),
              TodoStatus.error when provider.todos.isEmpty =>
                  AppErrorWidget(
                      message: provider.errorMessage, onRetry: _loadData),
              _ => provider.todos.isEmpty
                  ? _NebulaEmptyState(filter: provider.filter, isDark: isDark)
                  : RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: provider.todos.length +
                      (provider.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    if (i == provider.todos.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF9D6FFF))),
                      );
                    }
                    final todo = provider.todos[i];
                    return _NebulaTodoCard(
                      todo: todo,
                      isDark: isDark,
                      onTap: () => context
                          .push(RouteConstants.todosDetail(todo.id))
                          .then((_) => _loadData()),
                      onToggle: () async {
                        final success = await provider.editTodo(
                          authToken: token,
                          todoId: todo.id,
                          title: todo.title,
                          description: todo.description,
                          isDone: !todo.isDone,
                        );
                        if (!success && mounted) {
                          showAppSnackBar(context,
                              message: provider.errorMessage,
                              type: SnackBarType.error);
                        }
                      },
                    );
                  },
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _NebulaFilterBar extends StatelessWidget {
  const _NebulaFilterBar({
    required this.selected,
    required this.onSelected,
    required this.total,
    required this.done,
    required this.pending,
    required this.isDark,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onSelected;
  final int total;
  final int done;
  final int pending;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0A1E) : const Color(0xFFF0EEFF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3DE1).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _NebulaFilterChip(
            label: 'Semua ($total)',
            selected: selected == TodoFilter.all,
            onTap: () => onSelected(TodoFilter.all),
            selectedColor: const Color(0xFF6C3DE1),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _NebulaFilterChip(
            label: 'Selesai ($done)',
            selected: selected == TodoFilter.done,
            onTap: () => onSelected(TodoFilter.done),
            selectedColor: const Color(0xFF0D9488),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _NebulaFilterChip(
            label: 'Belum ($pending)',
            selected: selected == TodoFilter.pending,
            onTap: () => onSelected(TodoFilter.pending),
            selectedColor: const Color(0xFFDB2777),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NebulaFilterChip extends StatelessWidget {
  const _NebulaFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [
            selectedColor,
            selectedColor.withOpacity(0.7),
          ])
              : null,
          color: selected
              ? null
              : (isDark
              ? const Color(0xFF1A1535)
              : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? selectedColor
                : selectedColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark
                ? selectedColor.withOpacity(0.9)
                : selectedColor),
            fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _NebulaEmptyState extends StatelessWidget {
  const _NebulaEmptyState({required this.filter, required this.isDark});
  final TodoFilter filter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final messages = {
      TodoFilter.all: (
      'Galaksi todo kosong',
      'Tambahkan bintang todo pertamamu',
      Icons.auto_awesome_outlined
      ),
      TodoFilter.done: (
      'Belum ada yang selesai',
      'Tandai todo sebagai selesai',
      Icons.check_circle_outline
      ),
      TodoFilter.pending: (
      'Semua sudah selesai!',
      'Kamu telah menaklukkan galaksi 🌌',
      Icons.celebration_outlined
      ),
    };
    final (title, subtitle, icon) = messages[filter]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C3DE1).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF6C3DE1).withOpacity(0.3),
                ),
              ),
              child: Icon(
                icon,
                size: 52,
                color: const Color(0xFF9D6FFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark
                    ? const Color(0xFFE8E0FF)
                    : const Color(0xFF1A1035),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF7A6AAF)
                    : const Color(0xFF8A7AAF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NebulaTodoCard extends StatelessWidget {
  const _NebulaTodoCard({
    required this.todo,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
  });

  final TodoModel todo;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDone = todo.isDone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? const Color(0xFF160F2E).withOpacity(0.9)
                : Colors.white.withOpacity(0.85),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF0D9488).withOpacity(isDark ? 0.3 : 0.25)
                  : const Color(0xFF6C3DE1).withOpacity(isDark ? 0.2 : 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Toggle
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isDone
                        ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey(true),
                      color: Color(0xFF0D9488),
                      size: 26,
                    )
                        : Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: const ValueKey(false),
                      color: const Color(0xFF9D6FFF).withOpacity(0.6),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          decoration:
                          isDone ? TextDecoration.lineThrough : null,
                          decorationColor:
                          const Color(0xFF9D6FFF).withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDone
                              ? (isDark
                              ? const Color(0xFF5A4A7A)
                              : const Color(0xFF8A7AAF))
                              : (isDark
                              ? const Color(0xFFE8E0FF)
                              : const Color(0xFF1A1035)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF6A5A9A)
                              : const Color(0xFF8A7AAF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark
                      ? const Color(0xFF5A4A7A)
                      : const Color(0xFF8A7AAF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}