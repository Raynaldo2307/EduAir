import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// A horizontal row of "hero" info cards on the student home.
///
/// Each card is described by [InfoCardData].
class InfoCardsRow extends StatefulWidget {
  const InfoCardsRow({super.key, required this.cards});

  final List<InfoCardData> cards;

  @override
  State<InfoCardsRow> createState() => _InfoCardsRowState();
}

class _InfoCardsRowState extends State<InfoCardsRow> {
  late final PageController _pageController;
  Timer? _autoSildeTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // show a the next card
    _pageController = PageController(viewportFraction: 0.88);

    //Auto-slide every 4 seceonds
    if (widget.cards.length > 1) {
      _autoSildeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || widget.cards.isEmpty) return;
        setState(() {
          _currentPage = (_currentPage + 1) % widget.cards.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSildeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.20).clamp(150.0, 185.0).toDouble();

    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: cardHeight,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.cards.length,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },

          itemBuilder: (context, index) {
            final card = widget.cards[index];
            // base card UI
            final baseCard = _InfoCard(card: card);

            // Animate each card:
            // - small fade in
            // - tiny scale-up "pop"
            // - staggered with index-based delay
            final animatedCard = baseCard
                .animate(
                  delay: (index * 120).ms, // stagger each card
                )
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                //slide bit from the bottom
                .slide(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .scale(
                  begin: const Offset(095, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                );

            // Center keeps the cards nicely aligned vertically
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 4 : 8, // a bit on the very first card
                right: 8, // space before the next card
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode: darken the pastel so it fits the dark surface
    final cardColor = isDark
        ? Color.lerp(card.backgroundColor, Colors.black, 0.55)!
        : card.backgroundColor;

    // Text color: white on dark, textPrimary on light
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
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
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
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
                              horizontal: 15,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            card.ctaLabel!,
                            // You had this as black; keeping that,
                            // but you *could* change to white for more contrast.
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

            // ── Image side ─────────────────────────────────────────────────────
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
