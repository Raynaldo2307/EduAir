import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

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
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final link = links[index];
        return QuickLinkItemWidget(item: link);
      },
    );
  }
}

class QuickLinkItemWidget extends StatelessWidget {
  const QuickLinkItemWidget({super.key, required this.item, this.onTap});

  final QuickLinkItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // WHY: In dark mode, light pastel backgrounds look washed out and jarring.
    // We use a tinted version of the icon colour instead — same pattern as the teacher home.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(16),
            color: isDark ? item.iconColor.withValues(alpha: 0.2) : item.backgroundColor,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(item.icon, color: item.iconColor, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickLinkItem {
  const QuickLinkItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.iconColor = AppTheme.primaryColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
}
