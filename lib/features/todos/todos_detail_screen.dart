// lib/features/todos/todos_detail_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosDetailScreen extends StatefulWidget {
  const TodosDetailScreen({super.key, required this.todoId});
  final String todoId;

  @override
  State<TodosDetailScreen> createState() => _TodosDetailScreenState();
}

class _TodosDetailScreenState extends State<TodosDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken ?? '';
    context.read<TodoProvider>().loadTodoById(
      authToken: token, todoId: widget.todoId,
    );
  }

  Future<void> _pickCover() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final token    = context.read<AuthProvider>().authToken ?? '';
      final provider = context.read<TodoProvider>();

      final success = await provider.updateCover(
        authToken:     token,
        todoId:        widget.todoId,
        imageFile:     kIsWeb ? null : File(picked.path),
        imageBytes:    bytes,
        imageFilename: picked.name.isNotEmpty ? picked.name : 'cover.jpg',
      );

      if (!mounted) return;
      if (success) {
        showAppSnackBar(context,
            message: 'Cover berhasil diperbarui.', type: SnackBarType.success);
      } else {
        showAppSnackBar(context,
            message: provider.errorMessage, type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: 'Gagal memilih gambar: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Todo'),
        content: const Text('Apakah kamu yakin ingin menghapus todo ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final token = context.read<AuthProvider>().authToken ?? '';
      final success = await context.read<TodoProvider>().removeTodo(
        authToken: token, todoId: widget.todoId,
      );
      if (success && mounted) {
        showAppSnackBar(context,
            message: 'Todo berhasil dihapus.', type: SnackBarType.success);
        context.go(RouteConstants.todos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<TodoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (provider.status == TodoStatus.loading ||
        provider.status == TodoStatus.initial) {
      return const Scaffold(body: LoadingWidget());
    }

    if (provider.status == TodoStatus.error) {
      return Scaffold(
        body: AppErrorWidget(message: provider.errorMessage, onRetry: _loadData),
      );
    }

    final todo = provider.selectedTodo;
    if (todo == null) {
      return const Scaffold(body: Center(child: Text('Data tidak ditemukan.')));
    }

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Detail Todo',
        showBackButton: true,
        menuItems: [
          TopAppBarMenuItem(
            text: 'Edit',
            icon: Icons.edit_outlined,
            onTap: () async {
              final edited = await context.push<bool>(
                RouteConstants.todosEdit(todo.id),
              );
              if (edited == true && mounted) _loadData();
            },
          ),
          TopAppBarMenuItem(
            text: 'Hapus',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover ──
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 220,
                color: colorScheme.primaryContainer.withOpacity(0.4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (todo.urlCover != null)
                      Image.network(
                        todo.urlCover!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 48),
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 52, color: colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          Text(
                            'Ketuk untuk menambah cover',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                    // Edit overlay
                    if (todo.urlCover != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Ganti Cover',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Text(
                    todo.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: todo.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Status Badge ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: todo.isDone
                              ? const Color(0xFF4CAF50).withOpacity(0.12)
                              : const Color(0xFFFF9800).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: todo.isDone
                                ? const Color(0xFF4CAF50).withOpacity(0.4)
                                : const Color(0xFFFF9800).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              todo.isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              size: 16,
                              color: todo.isDone
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              todo.isDone ? 'Selesai' : 'Belum Selesai',
                              style: TextStyle(
                                color: todo.isDone
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF9800),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──
                  Text(
                    'Deskripsi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      todo.description.isEmpty ? 'Tidak ada deskripsi.' : todo.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: todo.description.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        fontStyle: todo.description.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Toggle Done Button ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final token = context.read<AuthProvider>().authToken ?? '';
                        await context.read<TodoProvider>().editTodo(
                          authToken:   token,
                          todoId:      todo.id,
                          title:       todo.title,
                          description: todo.description,
                          isDone:      !todo.isDone,
                        );
                      },
                      icon: Icon(
                        todo.isDone
                            ? Icons.radio_button_unchecked_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      label: Text(
                        todo.isDone ? 'Tandai Belum Selesai' : 'Tandai Selesai',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: todo.isDone
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}