import 'package:flutter/material.dart';

/// Reusable avatar used across the app.
///
/// - If [photoUrl] is set → shows the user's photo.
/// - Otherwise → shows [initials] in a deterministic colour circle,
///   the same way WhatsApp assigns a colour to each contact.
///
/// Usage:
///   UserAvatar(initials: user.initials, radius: 24)
///   UserAvatar(initials: user.initials, photoUrl: user.photoUrl, radius: 40)
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.radius = 24,
  });

  final String initials;
  final String? photoUrl;
  final double radius;

  // ── WhatsApp-style colour palette ──
  // Each unique name always maps to the same colour because
  // we hash the character codes — no randomness, no database needed.
  static const _palette = [
    Color(0xFF1565C0), // blue
    Color(0xFF00695C), // teal
    Color(0xFF6A1B9A), // purple
    Color(0xFFAD1457), // pink
    Color(0xFF4E342E), // brown
    Color(0xFF2E7D32), // green
    Color(0xFF0277BD), // light blue
    Color(0xFF558B2F), // olive
    Color(0xFF9C27B0), // purple accent
    Color(0xFFE65100), // orange
  ];

  Color _colorFor(String text) {
    final hash = text.codeUnits.fold(0, (sum, code) => sum + code);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
        // Falls back to initials if the image fails to load
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFor(initials),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }
}
