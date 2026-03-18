import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// Simple data model for one row in the profile details card.
class ProfileField {
  const ProfileField({required this.label, required this.value});

  final String label;
  final String value;
}

/// Card that shows a vertical list of [ProfileField] rows.
class ProfileDetailsCard extends StatelessWidget {
  const ProfileDetailsCard({super.key, required this.fields});

  final List<ProfileField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _ProfileRow(
                label: fields[i].label,
                value: fields[i].value,
              ),
            ),
            if (i != fields.length - 1)
              Divider(
                height: 0,
                thickness: 0.6,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      height: 1.3,
    );

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
      height: 1.3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (left)
        Expanded(flex: 2, child: Text(label, style: labelStyle)),

        const SizedBox(width: 12),

        // Value (right)
        Expanded(
          flex: 3,
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: valueStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
