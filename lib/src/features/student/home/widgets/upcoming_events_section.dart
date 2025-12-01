import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({
    super.key,
    required this.events,
    this.onViewAll,
  });

  final List<UpcomingEvent> events;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.26).clamp(190.0, 230.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(event: event, height: cardHeight);
            },
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.height,
  });

  final UpcomingEvent event;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        width: 190,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: height * 0.55,
                width: double.infinity,
                child: event.imageUrl != null
                    ? _buildEventImage(event)
                    : _EventFallback(color: event.fallbackColor),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// 👇 Helper: decides between network and asset image, safely
Widget _buildEventImage(UpcomingEvent event) {
  final path = event.imageUrl;

  // 1️⃣ If null or empty → show fallback
  if (path == null || path.isEmpty) {
    return _EventFallback(color: event.fallbackColor);
  }

  // 2️⃣ Decide if this is a network URL or asset path
  final isNetworkImage =
      path.startsWith('http://') || path.startsWith('https://');

  if (isNetworkImage) {
    // 🌐 Load from the internet
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _EventFallback(color: event.fallbackColor),
    );
  } else {
    // 📁 Load from assets
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _EventFallback(color: event.fallbackColor),
    );
  }
}

class _EventFallback extends StatelessWidget {
  const _EventFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.event_available, color: AppTheme.textPrimary),
      ),
    );
  }
}

class UpcomingEvent {
  const UpcomingEvent({
    required this.title,
    required this.dateLabel,
    this.imageUrl,
    this.fallbackColor = const Color(0xFFE1F5FE),
  });

  final String title;
  final String dateLabel;
  final String? imageUrl; // asset path OR network URL
  final Color fallbackColor;
}
