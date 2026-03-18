import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/messaging/domain/conversation.dart';

/// A single row in the conversation list.
/// Shows avatar, name, last message preview, timestamp, and unread badge.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      onTap: () {
        // Navigate to chat screen when built
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Timestamp + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: conversation.unread > 0
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
