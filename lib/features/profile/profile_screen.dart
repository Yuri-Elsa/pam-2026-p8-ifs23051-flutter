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
  // ── Update Profile State ────────────
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  bool _profileLoading = false;

  // ── Change Password State ───────────
  final _passFormKey   = GlobalKey<FormState>();
  final _currPassCtrl  = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();
  bool _passLoading    = false;
  bool _showCurrPass   = false;
  bool _showNewPass    = false;
  bool _showConfPass   = false;

  // ── Photo State ─────────────────────
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

  // ── Foto Profil ─────────────────────
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
      );
      if (picked == null || !mounted) return;

      // Di mobile, cukup pakai File — tidak perlu baca bytes
      // Di web, tidak ada File sehingga harus pakai bytes
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
            message: 'Gagal memilih foto: $e',
            type: SnackBarType.error);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined),
                ),
                title: const Text('Ambil Foto'),
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

  // ── Update Profile ──────────────────
  Future<void> _submitProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _profileLoading = true);

    final success = await context.read<AuthProvider>().updateProfile(
      name:     _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _profileLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Profil berhasil diperbarui.'
          : context.read<AuthProvider>().errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );
  }

  // ── Change Password ─────────────────
  Future<void> _submitPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);

    final success = await context.read<AuthProvider>().updatePassword(
      currentPassword: _currPassCtrl.text.trim(),
      newPassword:     _newPassCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _passLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Kata sandi berhasil diubah.'
          : context.read<AuthProvider>().errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );

    if (success) {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confPassCtrl.clear();
    }
  }

  // ── Logout ─────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Keluar'),
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
    final provider    = context.watch<AuthProvider>();
    final user        = provider.user;
    final colorScheme = Theme.of(context).colorScheme;

    if (provider.status == AuthStatus.loading && user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    // Gunakan provider.photoUrl, BUKAN user.urlPhoto.
    // Alasannya: GET /users/me di backend TIDAK mengembalikan urlPhoto
    // (field urlPhoto tidak ada di UserResponse). provider.photoUrl
    // membangun URL dari userId + timestamp cache-buster secara manual.
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
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: colorScheme.primaryContainer,
                          // photoUrl berisi timestamp sebagai query param,
                          // sehingga setiap upload foto = URL baru = cache miss
                          // = CachedNetworkImage fetch ulang dari server.
                          child: photoUrl != null
                              ? ClipOval(
                            child: CachedNetworkImage(
                              // ValueKey memaksa widget rebuild total
                              // saat URL berubah (timestamp naik)
                              key: ValueKey(photoUrl),
                              imageUrl: photoUrl,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                              useOldImageOnUrlChange: false,
                              placeholder: (_, __) => Container(
                                width: 112,
                                height: 112,
                                color: colorScheme.primaryContainer,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _AvatarFallback(
                                name: user?.name ?? '',
                                colorScheme: colorScheme,
                              ),
                            ),
                          )
                              : _AvatarFallback(
                            name: user?.name ?? '',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ),
                      if (_photoUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
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
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: colorScheme.surface, width: 2.5),
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                size: 15, color: colorScheme.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user?.username ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk untuk ganti foto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Edit Profil ──
          _SectionCard(
            title: 'Edit Profil',
            icon: Icons.person_outline_rounded,
            child: Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username tidak boleh kosong.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _profileLoading ? null : _submitProfile,
                      icon: _profileLoading
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_profileLoading ? 'Menyimpan...' : 'Simpan Profil'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Ganti Kata Sandi ──
          _SectionCard(
            title: 'Ganti Kata Sandi',
            icon: Icons.lock_outline_rounded,
            child: Form(
              key: _passFormKey,
              child: Column(
                children: [
                  _PasswordField(
                    controller: _currPassCtrl,
                    label: 'Kata Sandi Saat Ini',
                    show: _showCurrPass,
                    onToggle: () => setState(() => _showCurrPass = !_showCurrPass),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Kata sandi saat ini diperlukan.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    controller: _newPassCtrl,
                    label: 'Kata Sandi Baru',
                    show: _showNewPass,
                    onToggle: () => setState(() => _showNewPass = !_showNewPass),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Minimal 6 karakter.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    controller: _confPassCtrl,
                    label: 'Konfirmasi Kata Sandi Baru',
                    show: _showConfPass,
                    onToggle: () => setState(() => _showConfPass = !_showConfPass),
                    validator: (v) => v != _newPassCtrl.text
                        ? 'Kata sandi tidak cocok.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _passLoading ? null : _submitPassword,
                      icon: _passLoading
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.key_rounded),
                      label: Text(_passLoading ? 'Mengubah...' : 'Ganti Kata Sandi'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Logout Button ──
          OutlinedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error),
            label: Text('Keluar dari Akun',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Helper Widget: Inisial nama sebagai fallback avatar ──────────
class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.colorScheme});
  final String name;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 38,
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String   title;
  final IconData icon;
  final Widget   child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController       controller;
  final String                      label;
  final bool                        show;
  final VoidCallback                onToggle;
  final String? Function(String?)   validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(show
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}