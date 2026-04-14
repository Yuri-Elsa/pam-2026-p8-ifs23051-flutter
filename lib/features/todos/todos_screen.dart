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
    final provider    = context.watch<TodoProvider>();
    final token       = context.read<AuthProvider>().authToken ?? '';
    final colorScheme = Theme.of(context).colorScheme;

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
        elevation: 4,
      ),
      body: Column(
        children: [
          // ── Filter Bar ──
          _FilterBar(
            selected: provider.filter,
            onSelected: (f) => context.read<TodoProvider>().setFilter(f),
            total: provider.totalTodos,
            done: provider.doneTodos,
            pending: provider.pendingTodos,
          ),

          // ── Content ──
          Expanded(
            child: switch (provider.status) {
              TodoStatus.loading when provider.todos.isEmpty =>
              const LoadingWidget(message: 'Memuat todo...'),
              TodoStatus.error when provider.todos.isEmpty =>
                  AppErrorWidget(
                      message: provider.errorMessage, onRetry: _loadData),
              _ => provider.todos.isEmpty
                  ? _EmptyState(filter: provider.filter)
                  : RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: provider.todos.length + (provider.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    if (i == provider.todos.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final todo = provider.todos[i];
                    return _TodoCard(
                      todo: todo,
                      index: i,
                      onTap: () => context
                          .push(RouteConstants.todosDetail(todo.id))
                          .then((_) => _loadData()),
                      onToggle: () async {
                        final success = await provider.editTodo(
                          authToken:   token,
                          todoId:      todo.id,
                          title:       todo.title,
                          description: todo.description,
                          isDone:      !todo.isDone,
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

// ── Filter Bar ──────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.total,
    required this.done,
    required this.pending,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onSelected;
  final int total;
  final int done;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _FilterChipItem(
            label: 'Semua ($total)',
            selected: selected == TodoFilter.all,
            onTap: () => onSelected(TodoFilter.all),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: 'Selesai ($done)',
            selected: selected == TodoFilter.done,
            onTap: () => onSelected(TodoFilter.done),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: 'Belum ($pending)',
            selected: selected == TodoFilter.pending,
            onTap: () => onSelected(TodoFilter.pending),
            color: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messages = {
      TodoFilter.all:     ('Belum ada todo', 'Ketuk + untuk menambahkan todo baru', Icons.inbox_outlined),
      TodoFilter.done:    ('Belum ada yang selesai', 'Tandai todo sebagai selesai', Icons.check_circle_outline),
      TodoFilter.pending: ('Semua sudah selesai!', 'Kamu telah menyelesaikan semua todo 🎉', Icons.celebration_outlined),
    };
    final (title, subtitle, icon) = messages[filter]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: colorScheme.outline.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Todo Card ──────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.index,
    required this.onTap,
    required this.onToggle,
  });

  final TodoModel todo;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = todo.isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF4CAF50).withOpacity(0.06)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF4CAF50).withOpacity(0.25)
                    : colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Toggle button
                  GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(isDone),
                        color: isDone ? const Color(0xFF4CAF50) : colorScheme.outline,
                        size: 28,
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
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: colorScheme.outline,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDone
                                ? colorScheme.onSurface.withOpacity(0.5)
                                : colorScheme.onSurface,
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
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: colorScheme.outline,
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