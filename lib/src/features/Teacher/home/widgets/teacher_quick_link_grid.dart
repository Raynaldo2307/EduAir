import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

/// Reusable grid for quick actions on the dashboard
/// (used on both student + teacher side).
class QuickLinksGrid extends StatelessWidget {
  const QuickLinksGrid({super.key, required this.links, this.onItemTap});

  /// All quick-link items to render in the grid.
  final List<QuickLinkItem> links;

  /// Optional parent-level tap handler.
  ///
  /// If this is provided (e.g. from TeacherHomeScreen), it will be called
  /// with `(context, item)` and *completely override* the item-level
  /// routeName / onTap behavior.
  final void Function(BuildContext context, QuickLinkItem item)? onItemTap;

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
        childAspectRatio: 0.78, // icon + label fits nicely
      ),
      itemBuilder: (context, index) {
        final link = links[index];
        return QuickLinkItemWidget(item: link, onTap: onItemTap);
      },
    );
  }
}

class QuickLinkItemWidget extends StatelessWidget {
  const QuickLinkItemWidget({super.key, required this.item, this.onTap});

  final QuickLinkItem item;

  /// Optional parent-level tap handler.
  /// If not null, this wins over the item’s own `routeName` / `onTap`.
  final void Function(BuildContext context, QuickLinkItem item)? onTap;

  /// Default behavior when no parent handler is passed.
  void _handleTapFallback(BuildContext context) {
    // 1) Custom handler on the item wins
    if (item.onTap != null) {
      item.onTap!(context);
      return;
    }

    // 2) Otherwise, use routeName if provided
    if (item.routeName != null) {
      Navigator.of(context).pushNamed(item.routeName!);
      return;
    }

    // 3) Else: nothing for now (could show "Coming soon" later)
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (onTap != null) {
          // Parent (e.g. TeacherHomeScreen) decides what happens
          onTap!(context, item);
        } else {
          // Fallback: item-level behavior
          _handleTapFallback(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon tile
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(16),
            color: isDark ? item.iconColor.withValues(alpha: 0.2) : item.backgroundColor,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(item.icon, color: item.iconColor, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
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
    this.routeName,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  /// Named route to navigate to when tapped (optional).
  final String? routeName;

  /// Custom tap handler (optional).
  /// If set, this is used instead of [routeName] when there is **no**
  /// parent `onItemTap` passed into [QuickLinksGrid].
  final void Function(BuildContext context)? onTap;
}
