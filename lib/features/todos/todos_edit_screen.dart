// lib/features/todos/todos_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosEditScreen extends StatefulWidget {
  const TodosEditScreen({super.key, required this.todoId});
  final String todoId;

  @override
  State<TodosEditScreen> createState() => _TodosEditScreenState();
}

class _TodosEditScreenState extends State<TodosEditScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isDone        = false;
  bool _isLoading     = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().authToken ?? '';
      context.read<TodoProvider>().loadTodoById(
        authToken: token, todoId: widget.todoId,
      );
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _populateForm() {
    if (_isInitialized) return;
    final todo = context.read<TodoProvider>().selectedTodo;
    if (todo == null) return;
    _titleCtrl.text = todo.title;
    _descCtrl.text  = todo.description;
    _isDone         = todo.isDone;
    _isInitialized  = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token   = context.read<AuthProvider>().authToken ?? '';
    final success = await context.read<TodoProvider>().editTodo(
      authToken:   token,
      todoId:      widget.todoId,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isDone:      _isDone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showAppSnackBar(context,
          message: 'Todo berhasil diperbarui.', type: SnackBarType.success);
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context,
          message: context.read<TodoProvider>().errorMessage,
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.selectedTodo != null) _populateForm();

    return Scaffold(
      appBar: const TopAppBarWidget(
          title: 'Edit Todo', showBackButton: true, showThemeToggle: false),
      body: provider.selectedTodo == null
          ? const LoadingWidget(message: 'Memuat data...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Judul',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF9D6FFF)
                      : const Color(0xFF6C3DE1),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE8E0FF)
                      : const Color(0xFF1A1035),
                ),
                decoration: const InputDecoration(
                  labelText: 'Judul Todo',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul tidak boleh kosong.'
                    : null,
              ),
              const SizedBox(height: 20),

              Text(
                'Deskripsi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF9D6FFF)
                      : const Color(0xFF6C3DE1),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE8E0FF)
                      : const Color(0xFF1A1035),
                ),
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi tidak boleh kosong.'
                    : null,
              ),
              const SizedBox(height: 16),

              // Status toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? const Color(0xFF1A1535).withOpacity(0.8)
                      : const Color(0xFFF0EEFF).withOpacity(0.8),
                  border: Border.all(
                    color: const Color(0xFF6C3DE1).withOpacity(0.2),
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Status Todo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE8E0FF)
                          : const Color(0xFF1A1035),
                    ),
                  ),
                  subtitle: Text(
                    _isDone ? 'Sudah selesai' : 'Belum selesai',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9D6FFF)
                          : const Color(0xFF6C3DE1),
                      fontSize: 13,
                    ),
                  ),
                  value: _isDone,
                  onChanged: (v) => setState(() => _isDone = v),
                  activeColor: const Color(0xFF9D6FFF),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? null
                        : const LinearGradient(
                      colors: [
                        Color(0xFF3B1181),
                        Color(0xFF6C3DE1)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: _isLoading
                        ? const Color(0xFF3D2A6B).withOpacity(0.4)
                        : null,
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined,
                        color: Colors.white),
                    label: Text(
                      _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}