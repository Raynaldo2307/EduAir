import 'package:flutter/material.dart';

class ExportSf4Button extends StatelessWidget {
  const ExportSf4Button({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.download_outlined, color: cs.primary),
        label: Text(
          'Export SF4 Report',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: cs.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
