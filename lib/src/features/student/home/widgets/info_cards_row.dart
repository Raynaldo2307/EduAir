import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// A horizontal row of "hero" info cards on the student home.
///
/// Each card is described by [InfoCardData].
class InfoCardsRow extends StatelessWidget {
  const InfoCardsRow({super.key, required this.cards});

  final List<InfoCardData> cards;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.22).clamp(150.0, 190.0).toDouble();

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _InfoCard(card: card);
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.card});

  final InfoCardData card;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 240,
        height: 160, // fixed height to avoid overflow
        decoration: BoxDecoration(
          color: card.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Text + CTA side ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  if (card.ctaLabel != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 32),
                        child: ElevatedButton(
                          onPressed: card.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            card.ctaLabel!,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Image side ─────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 100,
                width: 90,
                child:
                    (card.imageUrl != null && card.imageUrl!.trim().isNotEmpty)
                    ? _buildCardImage(card)
                    : _FallbackImage(color: card.backgroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decide whether to load from network or from assets, just like UpcomingEvent.
  Widget _buildCardImage(InfoCardData card) {
    final url = card.imageUrl!.trim();
    final isNetworkImage =
        url.startsWith('http://') || url.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _FallbackImage(color: card.backgroundColor),
      );
    } else {
      // Treat as asset path
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _FallbackImage(color: card.backgroundColor),
      );
    }
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Image.asset('assets/images/eduair_logo.png', fit: BoxFit.contain),
    );
  }
}

/// Simple data model for the hero info cards.
class InfoCardData {
  const InfoCardData({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.ctaLabel,
    this.onTap,
    this.backgroundColor = const Color(0xFFFDECEF),
  });

  final String title;
  final String subtitle;

  /// Can be **either** a full network URL (https://...) or an asset path
  /// like 'assets/images/home_hero_homework.png'.
  final String? imageUrl;

  final String? ctaLabel;
  final VoidCallback? onTap;
  final Color backgroundColor;
}
