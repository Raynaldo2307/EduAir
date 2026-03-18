import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.onEditProfile,
    this.onEditPhoto,
 
  // 👇 soft-coded defaults instead of magic numbers
    this.avatarSize = 90,
 
  });

  final String name;
  final String subtitle;
  final String? photoUrl;

  // Called when the user taps the little pencil next to their name.
  final VoidCallback? onEditProfile;

  // Called when the user taps the camera icon on the avatar.
  final VoidCallback? onEditPhoto;

  // allow parent screens to override size if needed
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Avatar =. camera button
        Stack(
          clipBehavior: Clip.none,
          children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration:  BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _DefaultAvatar(),
                )
              : const _DefaultAvatar(),
        ),
        
        // Small camera icon in bottom-right
        if (onEditPhoto != null)
        Positioned(
          right : -2,
          bottom : -2,
          child : Material(
            color: Colors.transparent,
            child: InkWell(
            onTap: onEditPhoto,
            borderRadius: BorderRadius.circular(16),
            child:Container( 
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:Colors.black.withValues(alpha:0.18),
                    blurRadius: 6,
                    offset: const Offset (0,3),
                  ),
                ],
              ),
              child: const Icon ( 
                Icons.camera_alt_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          ),
        ),
          ],
        ),

        const SizedBox(height: 12),

        // Name + Edit Icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
        Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      
       if (onEditProfile != null) ...[
         const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:onEditProfile,
            child:const Padding(
              padding : EdgeInsets.all(4.0),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
          ),
          ),
          ),
       ],
          ],
        ),

        const SizedBox(height: 4),

        // Subtitle (Grade • Class • ID)
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            // slightly darker than pure grey so it’s easier to read
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.12),
      child: const Icon(
        Icons.person_outline,
        color: AppTheme.primaryColor,
        size: 40,
      ),
    );
  }
}
