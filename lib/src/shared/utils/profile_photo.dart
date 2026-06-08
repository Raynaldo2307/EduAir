import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:edu_air/src/core/app_providers.dart';

/// Shows the photo-source sheet, lets the user take or choose a photo, uploads
/// it, and updates the in-memory user so every avatar refreshes. Returns true on
/// a successful upload.
///
/// Single source of truth shared by Settings and the Profile page — so the flow
/// (and the theme-aware, dark-mode-correct sheet) lives in exactly one place.
Future<bool> pickAndUploadProfilePhoto(
  BuildContext context,
  WidgetRef ref,
) async {
  ImageSource? source;
  if (kIsWeb) {
    // No camera on web — go straight to the file picker.
    source = ImageSource.gallery;
  } else {
    source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Theme-aware so the sheet reads in light AND dark mode.
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: cs.surfaceContainerHighest,
                  leading: Icon(Icons.camera_alt_outlined, color: cs.onSurface),
                  title: Text('Take a photo', style: TextStyle(color: cs.onSurface)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: cs.surfaceContainerHighest,
                  leading: Icon(Icons.photo_library_outlined, color: cs.onSurface),
                  title: Text('Choose from gallery', style: TextStyle(color: cs.onSurface)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
  if (source == null || !context.mounted) return false;

  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (file == null) return false;

  try {
    final repo     = ref.read(uploadApiRepositoryProvider);
    final photoUrl = await repo.uploadProfilePhoto(file);

    // Update the in-memory user so the avatar refreshes immediately everywhere.
    final current = ref.read(userProvider);
    if (current != null) {
      ref.read(userProvider.notifier).state =
          current.copyWith(photoUrl: photoUrl);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return false;
  }
}
