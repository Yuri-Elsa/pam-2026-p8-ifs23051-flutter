// lib/features/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/nebula_background.dart';
import '../../shared/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().register(
      name: _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      showAppSnackBar(
        context,
        message: 'Register berhasil!',
        type: SnackBarType.success,
      );
      context.go(RouteConstants.login);
    } else {
      showAppSnackBar(
        context,
        message: context.read<AuthProvider>().errorMessage,
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NebulaBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CosmicLogo(isDark: isDark),
                  const SizedBox(height: 24),

                  NebulaCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Nama'),
                          validator: (v) =>
                          v!.isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _userCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Username'),
                          validator: (v) =>
                          v!.isEmpty ? 'Username wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass),
                            ),
                          ),
                          validator: (v) => v!.length < 6
                              ? 'Minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: !_showConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(
                                          () => _showConfirm = !_showConfirm),
                            ),
                          ),
                          validator: (v) =>
                          v != _passCtrl.text ? 'Tidak cocok' : null,
                        ),
                        const SizedBox(height: 20),

                        NebulaButton(
                          onPressed: _isLoading ? null : _submit,
                          isLoading: _isLoading,
                          label: 'Daftar',
                          loadingLabel: 'Loading...',
                          icon: Icons.person_add,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => context.go(RouteConstants.login),
                    child: const Text('Sudah punya akun? Login'),
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