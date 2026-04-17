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
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final token = context.read<AuthProvider>().authToken ?? '';
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
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF160F2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Todo',
          style: TextStyle(
            color: isDark ? const Color(0xFFE8E0FF) : const Color(0xFF1A1035),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus todo ini dari galaksimu?',
          style: TextStyle(
            color: isDark
                ? const Color(0xFFB09FD8)
                : const Color(0xFF5A4A7A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF9D6FFF)
                    : const Color(0xFF6C3DE1),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF831843), Color(0xFFDB2777)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child:
              const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
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
    final provider = context.watch<TodoProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      return const Scaffold(
          body: Center(child: Text('Data tidak ditemukan.')));
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
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0B3B), Color(0xFF2D1B69)],
                  )
                      : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEFEBFF), Color(0xFFE0D8FF)],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (todo.urlCover != null)
                      Image.network(
                        todo.urlCover!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 48, color: Color(0xFF9D6FFF)),
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 52, color: Color(0xFF9D6FFF)),
                          const SizedBox(height: 10),
                          Text(
                            'Ketuk untuk menambah cover',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF7A6AAF)
                                  : const Color(0xFF8A7AAF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    if (todo.urlCover != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6C3DE1),
                                Color(0xFF9D174D)
                              ],
                            ),
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
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: todo.isDone ? TextDecoration.lineThrough : null,
                      color: isDark
                          ? const Color(0xFFE8E0FF)
                          : const Color(0xFF1A1035),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: todo.isDone
                            ? [const Color(0xFF0C4A6E), const Color(0xFF0D9488)]
                            : [const Color(0xFF831843), const Color(0xFFDB2777)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          todo.isDone
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          todo.isDone ? 'Selesai' : 'Belum Selesai',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: isDark
                          ? const Color(0xFF9D6FFF)
                          : const Color(0xFF6C3DE1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0xFF1A1535).withOpacity(0.8)
                          : const Color(0xFFF0EEFF).withOpacity(0.8),
                      border: Border.all(
                        color: const Color(0xFF6C3DE1).withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      todo.description.isEmpty
                          ? 'Tidak ada deskripsi.'
                          : todo.description,
                      style: TextStyle(
                        height: 1.6,
                        color: todo.description.isEmpty
                            ? (isDark
                            ? const Color(0xFF5A4A7A)
                            : const Color(0xFF8A7AAF))
                            : (isDark
                            ? const Color(0xFFE8E0FF)
                            : const Color(0xFF1A1035)),
                        fontStyle: todo.description.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle done button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: todo.isDone
                              ? [const Color(0xFF831843), const Color(0xFFDB2777)]
                              : [const Color(0xFF065F46), const Color(0xFF0D9488)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final token =
                              context.read<AuthProvider>().authToken ?? '';
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
                          color: Colors.white,
                        ),
                        label: Text(
                          todo.isDone
                              ? 'Tandai Belum Selesai'
                              : 'Tandai Selesai',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
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