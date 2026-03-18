import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/messaging/application/conversations_provider.dart';
import 'package:edu_air/src/features/messaging/domain/conversation.dart';
import 'package:edu_air/src/features/messaging/widgets/conversation_tile.dart';

/// Messages tab – student view.
class StudentMessagesPage extends ConsumerStatefulWidget {
  const StudentMessagesPage({super.key});

  @override
  ConsumerState<StudentMessagesPage> createState() =>
      _StudentMessagesPageState();
}

class _StudentMessagesPageState extends ConsumerState<StudentMessagesPage> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildHeader(cs),
            const SizedBox(height: 12),
            _buildTopTabs(cs),
            _buildTopTabUnderline(cs),
            const SizedBox(height: 12),
            _buildSearchBox(cs, isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildList(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Messages',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildTopTabs(ColorScheme cs) {
    final inactiveColor = cs.onSurface.withValues(alpha: 0.5);

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
                    color: _selectedTab == 0 ? AppTheme.primaryColor : inactiveColor,
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
                    color: _selectedTab == 1 ? AppTheme.primaryColor : inactiveColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabUnderline(ColorScheme cs) {
    final inactiveColor = cs.outline.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 0 ? AppTheme.primaryColor : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 1 ? AppTheme.primaryColor : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: TextStyle(fontSize: 14, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search messages…',
          hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
          filled: true,
          fillColor: isDark ? AppTheme.darkCard : AppTheme.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildList(ColorScheme cs) {
    final List<Conversation> source = _selectedTab == 0
        ? ref.watch(individualConversationsProvider)
        : ref.watch(groupConversationsProvider);

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
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outline.withValues(alpha: 0.25),
        indent: 72,
      ),
      itemBuilder: (_, index) => ConversationTile(conversation: filtered[index]),
    );
  }
}
