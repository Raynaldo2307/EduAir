import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// A horizontal "hero" carousel on the student home.
/// Uses a PageView with auto-slide + entrance animation.
class InfoCardsRow extends StatefulWidget {
  const InfoCardsRow({super.key, required this.cards});

  final List<InfoCardData> cards;

  @override
  State<InfoCardsRow> createState() => _InfoCardsRowState();
}

class _InfoCardsRowState extends State<InfoCardsRow> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Each page takes ~88% of the width so you see a bit of the next card.
    _pageController = PageController(viewportFraction: 0.88);

    // Auto-slide every 4 seconds if there is more than 1 card.
    if (widget.cards.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || widget.cards.isEmpty) return;

        final nextPage = (_currentPage + 1) % widget.cards.length;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        );

        setState(() => _currentPage = nextPage);
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.20).clamp(150.0, 185.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppTheme.heroStripBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.cards.length,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) {
            final card = widget.cards[index];

            // Base card UI.
            final baseCard = _InfoCard(card: card);

            // Animations:
            // - small fade in
            // - slide up a bit
            // - slight scale pop
            final animatedCard = baseCard
                .animate(delay: (index * 120).ms) // stagger a little
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .slide(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                )
                .scale(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                );

            // Padding gives space between pink and blue cards.
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 4 : 8, // a bit more on first card
                right: 8,
              ),
              child: Center(child: animatedCard),
            );
          },
        ),
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
        width: double.infinity, // fills the PageView viewport
        //height: 155,
        decoration: BoxDecoration(
          color: card.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Text + CTA side ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  //const Spacer(),
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
                              horizontal: 15,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            card.ctaLabel!,
                            // You had this as black; keeping it for now.
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 2.1),

            // ── Image side ──────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
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

  /// Decide whether to load from network or assets, just like UpcomingEvent.
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
    this.backgroundColor = const Color(0xFFFDECEE),
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
