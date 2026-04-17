// lib/features/profile/profile_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  bool _profileLoading = false;

  final _passFormKey   = GlobalKey<FormState>();
  final _currPassCtrl  = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();
  bool _passLoading    = false;
  bool _showCurrPass   = false;
  bool _showNewPass    = false;
  bool _showConfPass   = false;

  bool _photoUploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _userCtrl = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 512,
      );
      if (picked == null || !mounted) return;

      final Uint8List? bytes = kIsWeb ? await picked.readAsBytes() : null;
      setState(() => _photoUploading = true);

      final success = await context.read<AuthProvider>().updatePhoto(
        imageFile:     kIsWeb ? null : File(picked.path),
        imageBytes:    bytes,
        imageFilename: picked.name.isNotEmpty ? picked.name : 'photo.jpg',
      );

      if (!mounted) return;
      setState(() => _photoUploading = false);

      if (success) {
        showAppSnackBar(context,
            message: 'Foto profil berhasil diperbarui!',
            type: SnackBarType.success);
      } else {
        showAppSnackBar(context,
            message: context.read<AuthProvider>().errorMessage,
            type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _photoUploading = false);
        showAppSnackBar(context,
            message: 'Gagal memilih foto: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _pickPhoto() async {
    if (kIsWeb) {
      await _pickAndUploadPhoto(ImageSource.gallery);
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF160F2E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D6FFF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B1181), Color(0xFF6C3DE1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Colors.white),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFFE8E0FF)
                        : const Color(0xFF1A1035),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF831843), Color(0xFFDB2777)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white),
                ),
                title: Text(
                  'Ambil Foto',
                  style: TextStyle(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFFE8E0FF)
                        : const Color(0xFF1A1035),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _profileLoading = true);

    final success = await context.read<AuthProvider>().updateProfile(
      name: _nameCtrl.text.trim(), username: _userCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _profileLoading = false);

    showAppSnackBar(context,
        message: success
            ? 'Profil berhasil diperbarui.'
            : context.read<AuthProvider>().errorMessage,
        type: success ? SnackBarType.success : SnackBarType.error);
  }

  Future<void> _submitPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);

    final success = await context.read<AuthProvider>().updatePassword(
      currentPassword: _currPassCtrl.text.trim(),
      newPassword:     _newPassCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _passLoading = false);

    showAppSnackBar(context,
        message: success
            ? 'Kata sandi berhasil diubah.'
            : context.read<AuthProvider>().errorMessage,
        type: success ? SnackBarType.success : SnackBarType.error);

    if (success) {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confPassCtrl.clear();
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF160F2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar',
          style: TextStyle(
            color: isDark ? const Color(0xFFE8E0FF) : const Color(0xFF1A1035),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari akun?',
          style: TextStyle(
            color: isDark ? const Color(0xFFB09FD8) : const Color(0xFF5A4A7A),
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
              child: const Text('Keluar',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go(RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final user = provider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.status == AuthStatus.loading && user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    final photoUrl = provider.photoUrl;

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Profil Saya',
        showBackButton: false,
        menuItems: [
          TopAppBarMenuItem(
            text: 'Keluar',
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar Section ──
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _photoUploading ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      // Outer glow ring
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C3DE1),
                              Color(0xFFDB2777),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: isDark
                                ? const Color(0xFF160F2E)
                                : const Color(0xFFF0EEFF),
                            child: photoUrl != null
                                ? ClipOval(
                              child: CachedNetworkImage(
                                key: ValueKey(photoUrl),
                                imageUrl: photoUrl,
                                width: 116,
                                height: 116,
                                fit: BoxFit.cover,
                                useOldImageOnUrlChange: false,
                                placeholder: (_, __) => Container(
                                  width: 116,
                                  height: 116,
                                  color: isDark
                                      ? const Color(0xFF1A1535)
                                      : const Color(0xFFEFEBFF),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF9D6FFF),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) =>
                                    _AvatarFallback(
                                      name: user?.name ?? '',
                                      isDark: isDark,
                                    ),
                              ),
                            )
                                : _AvatarFallback(
                              name: user?.name ?? '',
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                      if (_photoUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (!_photoUploading)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C3DE1), Color(0xFF9D174D)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0E0A1E)
                                    : Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE8E0FF)
                        : const Color(0xFF1A1035),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user?.username ?? ''}',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9D6FFF)
                        : const Color(0xFF6C3DE1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk untuk ganti foto',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF6A5A9A)
                        : const Color(0xFF8A7AAF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Edit Profil ──
          _NebulaSectionCard(
            title: 'Edit Profil',
            icon: Icons.person_outline_rounded,
            gradientColors: const [Color(0xFF3B1181), Color(0xFF6C3DE1)],
            isDark: isDark,
            child: Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE8E0FF)
                          : const Color(0xFF1A1035),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _userCtrl,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE8E0FF)
                          : const Color(0xFF1A1035),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username tidak boleh kosong.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _profileLoading
                            ? null
                            : const LinearGradient(
                          colors: [Color(0xFF3B1181), Color(0xFF6C3DE1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: _profileLoading
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
                        onPressed:
                        _profileLoading ? null : _submitProfile,
                        icon: _profileLoading
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined,
                            color: Colors.white),
                        label: Text(
                          _profileLoading ? 'Menyimpan...' : 'Simpan Profil',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Ganti Kata Sandi ──
          _NebulaSectionCard(
            title: 'Ganti Kata Sandi',
            icon: Icons.lock_outline_rounded,
            gradientColors: const [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
            isDark: isDark,
            child: Form(
              key: _passFormKey,
              child: Column(
                children: [
                  _NebulaPasswordField(
                    controller: _currPassCtrl,
                    label: 'Kata Sandi Saat Ini',
                    show: _showCurrPass,
                    onToggle: () =>
                        setState(() => _showCurrPass = !_showCurrPass),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Kata sandi saat ini diperlukan.'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _NebulaPasswordField(
                    controller: _newPassCtrl,
                    label: 'Kata Sandi Baru',
                    show: _showNewPass,
                    onToggle: () =>
                        setState(() => _showNewPass = !_showNewPass),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Minimal 6 karakter.'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _NebulaPasswordField(
                    controller: _confPassCtrl,
                    label: 'Konfirmasi Kata Sandi Baru',
                    show: _showConfPass,
                    onToggle: () =>
                        setState(() => _showConfPass = !_showConfPass),
                    validator: (v) => v != _newPassCtrl.text
                        ? 'Kata sandi tidak cocok.'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _passLoading
                            ? null
                            : const LinearGradient(
                          colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        color: _passLoading
                            ? const Color(0xFF1E3A5F).withOpacity(0.4)
                            : null,
                      ),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _passLoading ? null : _submitPassword,
                        icon: _passLoading
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.key_rounded,
                            color: Colors.white),
                        label: Text(
                          _passLoading
                              ? 'Mengubah...'
                              : 'Ganti Kata Sandi',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Logout ──
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDB2777).withOpacity(0.5),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFDB2777)),
                    const SizedBox(width: 10),
                    Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: const Color(0xFFDB2777),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.isDark});
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF9D6FFF), Color(0xFFFF6EE7)],
          ).createShader(const Rect.fromLTWH(0, 0, 80, 80)),
      ),
    );
  }
}

class _NebulaSectionCard extends StatelessWidget {
  const _NebulaSectionCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? const Color(0xFF160F2E).withOpacity(0.9)
            : Colors.white.withOpacity(0.85),
        border: Border.all(
          color: gradientColors[0].withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFFE8E0FF)
                      : const Color(0xFF1A1035),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            height: 20,
            color: gradientColors[0].withOpacity(0.15),
          ),
          child,
        ],
      ),
    );
  }
}

class _NebulaPasswordField extends StatelessWidget {
  const _NebulaPasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
    required this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      style: TextStyle(
        color: isDark ? const Color(0xFFE8E0FF) : const Color(0xFF1A1035),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}