import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.hintText = 'Search anything...',
    this.onChanged,
    this.onTap,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: TextField(
        onChanged: onChanged,
        onTap: onTap,
        style: TextStyle(color: cs.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.45),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.darkCard : AppTheme.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
