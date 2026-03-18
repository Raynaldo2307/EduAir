import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// Messages tab – student view.
/// Design mirrors the Calendar/Attendance tab:
///   SafeArea → header → tabs + underline → search box → list
class StudentMessagesPage extends StatefulWidget {
  const StudentMessagesPage({super.key});

  @override
  State<StudentMessagesPage> createState() => _StudentMessagesPageState();
}

class _StudentMessagesPageState extends State<StudentMessagesPage> {
  /// 0 = Individual, 1 = Groups
  int _selectedTab = 0;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────── Demo data ───────────────────────

  static const _individuals = [
    _Conversation(
      name: 'Mr. Brown',
      subtitle: 'Please submit your assignment by Friday.',
      time: '9:41 AM',
      initials: 'MB',
      avatarColor: Color(0xFF1565C0),
      unread: 2,
    ),
    _Conversation(
      name: 'Ms. Clarke',
      subtitle: 'Good work on the last test!',
      time: 'Yesterday',
      initials: 'SC',
      avatarColor: Color(0xFF00695C),
      unread: 0,
    ),
    _Conversation(
      name: 'Mr. Williams',
      subtitle: 'Class is cancelled tomorrow.',
      time: 'Mon',
      initials: 'DW',
      avatarColor: Color(0xFF6A1B9A),
      unread: 1,
    ),
    _Conversation(
      name: 'Mrs. Thompson',
      subtitle: 'Don\'t forget your science project.',
      time: 'Sun',
      initials: 'AT',
      avatarColor: Color(0xFFAD1457),
      unread: 0,
    ),
    _Conversation(
      name: 'Principal Davis',
      subtitle: 'School assembly on Thursday at 9 AM.',
      time: 'Fri',
      initials: 'PD',
      avatarColor: Color(0xFF4E342E),
      unread: 0,
    ),
  ];

  static const _groups = [
    _Conversation(
      name: 'Form 4B – Class Group',
      subtitle: 'Mr. Brown: Reminder — exam next week.',
      time: '10:05 AM',
      initials: '4B',
      avatarColor: Color(0xFF0288D1),
      unread: 5,
    ),
    _Conversation(
      name: 'Mathematics Club',
      subtitle: 'Meeting rescheduled to 2:30 PM.',
      time: 'Yesterday',
      initials: 'MC',
      avatarColor: Color(0xFF2E7D32),
      unread: 0,
    ),
    _Conversation(
      name: 'IT Students 2026',
      subtitle: 'Ms. Clarke: Project files uploaded.',
      time: 'Mon',
      initials: 'IT',
      avatarColor: Color(0xFF4527A0),
      unread: 3,
    ),
    _Conversation(
      name: 'Papine High – Announcements',
      subtitle: 'Sports day is this Saturday!',
      time: 'Sun',
      initials: 'PA',
      avatarColor: Color(0xFFC62828),
      unread: 0,
    ),
  ];

  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTopTabs(),
            _buildTopTabUnderline(),
            const SizedBox(height: 12),
            _buildSearchBox(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Messages',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ─────────────────────── Tabs ───────────────────────

  Widget _buildTopTabs() {
    final inactiveColor = AppTheme.textPrimary.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                alignment: Alignment.center,
                height: 32,
                child: Text(
                  'Individual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedTab == 0
                        ? AppTheme.primaryColor
                        : inactiveColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                alignment: Alignment.center,
                height: 32,
                child: Text(
                  'Groups',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedTab == 1
                        ? AppTheme.primaryColor
                        : inactiveColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabUnderline() {
    final inactiveColor = AppTheme.outline.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 0
                    ? AppTheme.primaryColor
                    : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 1
                    ? AppTheme.primaryColor
                    : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Search box ───────────────────────

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(fontSize: 14, color: AppTheme.textOnWhite),
        decoration: InputDecoration(
          hintText: 'Search messages…',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppTheme.grey.withValues(alpha: 0.8),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppTheme.grey,
          ),
          filled: true,
          fillColor: AppTheme.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide(
              color: AppTheme.outline.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── List ───────────────────────

  Widget _buildList() {
    final source = _selectedTab == 0 ? _individuals : _groups;

    final filtered = _searchQuery.isEmpty
        ? source
        : source
            .where((c) =>
                c.name.toLowerCase().contains(_searchQuery) ||
                c.subtitle.toLowerCase().contains(_searchQuery))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No conversations found',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppTheme.outline.withValues(alpha: 0.25),
        indent: 72,
      ),
      itemBuilder: (context, index) => _ConversationTile(
        conversation: filtered[index],
      ),
    );
  }
}

// ─────────────────────── Tile ───────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      onTap: () {
        // TODO: push to chat screen when built
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: conversation.avatarColor,
              child: Text(
                conversation.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: conversation.unread > 0
                        ? AppTheme.primaryColor
                        : AppTheme.grey,
                    fontWeight: conversation.unread > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Model ───────────────────────

class _Conversation {
  const _Conversation({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.initials,
    required this.avatarColor,
    required this.unread,
  });

  final String name;
  final String subtitle;
  final String time;
  final String initials;
  final Color avatarColor;
  final int unread;
}
