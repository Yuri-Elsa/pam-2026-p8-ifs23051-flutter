// lib/features/todos/todos_add_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosAddScreen extends StatefulWidget {
  const TodosAddScreen({super.key});

  @override
  State<TodosAddScreen> createState() => _TodosAddScreenState();
}

class _TodosAddScreenState extends State<TodosAddScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token   = context.read<AuthProvider>().authToken ?? '';
    final success = await context.read<TodoProvider>().addTodo(
      authToken:   token,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showAppSnackBar(context,
          message: 'Todo berhasil ditambahkan!', type: SnackBarType.success);
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context,
          message: context.read<TodoProvider>().errorMessage,
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const TopAppBarWidget(
        title: 'Tambah Todo',
        showBackButton: true,
        showThemeToggle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hint banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B1181).withOpacity(0.15),
                      const Color(0xFF6C3DE1).withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF6C3DE1).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF9D6FFF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buat todo baru dan catat perjalanan kosmikmu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFB09FD8)
                              : const Color(0xFF5A4A7A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                  hintText: 'Contoh: Belajar Flutter...',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                textInputAction: TextInputAction.next,
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
                maxLines: 6,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE8E0FF)
                      : const Color(0xFF1A1035),
                ),
                decoration: const InputDecoration(
                  hintText: 'Jelaskan detail todo ini...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi tidak boleh kosong.'
                    : null,
              ),
              const SizedBox(height: 32),

              // Gradient button
              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? null
                        : const LinearGradient(
                      colors: [Color(0xFF3B1181), Color(0xFF6C3DE1)],
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
                        : const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white),
                    label: Text(
                      _isLoading ? 'Menyimpan...' : 'Tambahkan Todo',
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