import 'package:flutter/material.dart';

// ─── Cosmic Logo ───────────────────────────────

class CosmicLogo extends StatelessWidget {
  const CosmicLogo({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF9D6FFF).withOpacity(0.3)
                    : const Color(0xFF6C3DE1).withOpacity(0.2),
              ),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF9D6FFF).withOpacity(0.5)
                    : const Color(0xFF6C3DE1).withOpacity(0.35),
              ),
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF6C3DE1), const Color(0xFF9D174D)]
                    : [const Color(0xFF6C3DE1), const Color(0xFF9333EA)],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ───────────────────────────────

class NebulaCard extends StatelessWidget {
  const NebulaCard({
    super.key,
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? const Color(0xFF160F2E).withOpacity(0.85)
            : Colors.white.withOpacity(0.75),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D2A6B).withOpacity(0.6)
              : const Color(0xFF6C3DE1).withOpacity(0.15),
        ),
      ),
      child: child,
    );
  }
}

// ─── Button ───────────────────────────────

class NebulaButton extends StatelessWidget {
  const NebulaButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.isDark,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: onPressed == null
            ? null
            : LinearGradient(
          colors: isDark
              ? [const Color(0xFF6C3DE1), const Color(0xFFB91C8C)]
              : [const Color(0xFF5B21B6), const Color(0xFF9333EA)],
        ),
        color: onPressed == null
            ? (isDark
            ? const Color(0xFF3D2A6B).withOpacity(0.5)
            : Colors.grey.withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}