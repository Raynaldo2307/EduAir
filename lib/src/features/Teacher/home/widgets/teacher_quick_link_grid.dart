import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// Reusable grid for quick actions on the dashboard
/// (used on both student + teacher side).
class QuickLinksGrid extends StatelessWidget {
  const QuickLinksGrid({super.key, required this.links});

  final List<QuickLinkItem> links;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: links.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 items per row
        crossAxisSpacing: 10, // space between items horizontally
        mainAxisSpacing: 10, // space between rows
        // Slightly more height per cell so icon + label fit comfortably
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final link = links[index];
        return QuickLinkItemWidget(item: link);
      },
    );
  }
}

class QuickLinkItemWidget extends StatelessWidget {
  const QuickLinkItemWidget({super.key, required this.item});

  final QuickLinkItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon tile
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          color: item.backgroundColor,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: Container(
            height: 64, // was 70 – slightly smaller to avoid overflow
            width: 64, // was 70
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 26, // was 28
              ),
            ),
          ),
        ),
        const SizedBox(height: 6), // was 8
        // Label
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12, // was 13 – a bit more compact
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class QuickLinkItem {
  const QuickLinkItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.iconColor = AppTheme.primaryColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
}
