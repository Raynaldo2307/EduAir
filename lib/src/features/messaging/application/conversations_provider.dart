import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/messaging/domain/conversation.dart';

/// Demo data — replace with a real API call when the messaging
/// endpoint is ready. Swap to a FutureProvider and call ApiClient
/// to load from the backend.

final individualConversationsProvider = Provider<List<Conversation>>((ref) {
  return const [
    Conversation(
      name: 'Mr. Brown',
      subtitle: 'Please submit your assignment by Friday.',
      time: '9:41 AM',
      initials: 'MB',
      avatarColor: Color(0xFF1565C0),
      unread: 2,
    ),
    Conversation(
      name: 'Ms. Clarke',
      subtitle: 'Good work on the last test!',
      time: 'Yesterday',
      initials: 'SC',
      avatarColor: Color(0xFF00695C),
      unread: 0,
    ),
    Conversation(
      name: 'Mr. Williams',
      subtitle: 'Class is cancelled tomorrow.',
      time: 'Mon',
      initials: 'DW',
      avatarColor: Color(0xFF6A1B9A),
      unread: 1,
    ),
    Conversation(
      name: 'Mrs. Thompson',
      subtitle: 'Don\'t forget your science project.',
      time: 'Sun',
      initials: 'AT',
      avatarColor: Color(0xFFAD1457),
      unread: 0,
    ),
    Conversation(
      name: 'Principal Davis',
      subtitle: 'School assembly on Thursday at 9 AM.',
      time: 'Fri',
      initials: 'PD',
      avatarColor: Color(0xFF4E342E),
      unread: 0,
    ),
  ];
});

final groupConversationsProvider = Provider<List<Conversation>>((ref) {
  return const [
    Conversation(
      name: 'Form 4B – Class Group',
      subtitle: 'Mr. Brown: Reminder — exam next week.',
      time: '10:05 AM',
      initials: '4B',
      avatarColor: Color(0xFF0288D1),
      unread: 5,
    ),
    Conversation(
      name: 'Mathematics Club',
      subtitle: 'Meeting rescheduled to 2:30 PM.',
      time: 'Yesterday',
      initials: 'MC',
      avatarColor: Color(0xFF2E7D32),
      unread: 0,
    ),
    Conversation(
      name: 'IT Students 2026',
      subtitle: 'Ms. Clarke: Project files uploaded.',
      time: 'Mon',
      initials: 'IT',
      avatarColor: Color(0xFF4527A0),
      unread: 3,
    ),
    Conversation(
      name: 'Papine High – Announcements',
      subtitle: 'Sports day is this Saturday!',
      time: 'Sun',
      initials: 'PA',
      avatarColor: Color(0xFFC62828),
      unread: 0,
    ),
  ];
});
