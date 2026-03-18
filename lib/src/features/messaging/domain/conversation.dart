import 'package:flutter/material.dart';

/// A single conversation entry shown in the Messages list.
/// Covers both individual (1-to-1) and group conversations.
class Conversation {
  const Conversation({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.initials,
    required this.avatarColor,
    required this.unread,
  });

  /// Display name — teacher name or group name.
  final String name;

  /// Preview of the last message.
  final String subtitle;

  /// Human-readable timestamp e.g. "9:41 AM", "Yesterday", "Mon".
  final String time;

  /// 1–2 letter initials shown inside the avatar circle.
  final String initials;

  /// Background colour for the avatar circle.
  final Color avatarColor;

  /// Number of unread messages. 0 = no badge shown.
  final int unread;
}
