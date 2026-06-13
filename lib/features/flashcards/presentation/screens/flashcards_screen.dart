import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_summerizer/core/router/app_router.dart';
import 'package:pdf_summerizer/features/flashcards/presentation/providers/flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String documentId;

  const FlashcardScreen({super.key, required this.documentId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFrontVisible = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(flashcardProvider(widget.documentId).notifier)
          .loadOrGenerate();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    final notifier =
        ref.read(flashcardProvider(widget.documentId).notifier);
    if (_isFrontVisible) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFrontVisible = !_isFrontVisible);
    notifier.flipCard();
  }

  void _handleNext() {
    _flipController.reverse();
    setState(() => _isFrontVisible = true);
    ref.read(flashcardProvider(widget.documentId).notifier).nextCard();
  }

  void _handlePrev() {
    _flipController.reverse();
    setState(() => _isFrontVisible = true);
    ref.read(flashcardProvider(widget.documentId).notifier).previousCard();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardProvider(widget.documentId));

    ref.listen<FlashcardState>(flashcardProvider(widget.documentId),
        (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(next.errorMessage!)),
            ]),
          ),
        );
        ref
            .read(flashcardProvider(widget.documentId).notifier)
            .clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (state.hasCards)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.currentIndex + 1} / ${state.total}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(FlashcardState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 20),
            Text(
              'Generating flashcards…',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.style_outlined,
                  size: 32, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No flashcards yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Generate flashcards from this document',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(flashcardProvider(widget.documentId).notifier)
                  .generateFlashcards(),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Generate Flashcards'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final card = state.currentCard!;

    return Column(
      children: [
        // ── Progress bar ──
        LinearProgressIndicator(
          value: (state.currentIndex + 1) / state.total,
          color: AppTheme.accent,
          backgroundColor: AppTheme.surfaceAlt,
          minHeight: 3,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                // ── Flip hint ──
                const Text(
                  'Tap card to reveal answer',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Flip card ──
                Expanded(
                  child: GestureDetector(
                    onTap: _handleFlip,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * 3.14159;
                        final isFront = _flipAnimation.value < 0.5;

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: isFront
                              ? _CardFace(
                                  label: 'QUESTION',
                                  labelColor: AppTheme.accent,
                                  text: card.question,
                                  icon: Icons.help_outline_rounded,
                                )
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..rotateY(3.14159),
                                  child: _CardFace(
                                    label: 'ANSWER',
                                    labelColor: AppTheme.success,
                                    text: card.answer,
                                    icon: Icons.lightbulb_outline_rounded,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Navigation buttons ──
                Row(
                  children: [
                    // Prev
                    _NavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Prev',
                      onPressed: state.isFirst ? null : _handlePrev,
                    ),
                    const SizedBox(width: 12),
                    // Flip
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleFlip,
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _isFrontVisible
                              ? 'Reveal Answer'
                              : 'Hide Answer',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next
                    _NavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'Next',
                      onPressed: state.isLast ? null : _handleNext,
                      iconAfter: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Regenerate ──
                TextButton.icon(
                  onPressed: () {
                    _flipController.reverse();
                    setState(() => _isFrontVisible = true);
                    ref
                        .read(flashcardProvider(widget.documentId)
                            .notifier)
                        .generateFlashcards();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text(
                    'Regenerate',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Card face widget
// ─────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String text;
  final IconData icon;

  const _CardFace({
    required this.label,
    required this.labelColor,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Label chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: labelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: labelColor),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Card text
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Tap hint icon at bottom
            Icon(Icons.touch_app_outlined,
                size: 20, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Nav button (prev / next)
// ─────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool iconAfter;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAfter
          ? [
              Text(label,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(icon, size: 14),
            ]
          : [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: onPressed == null
            ? AppTheme.textSecondary
            : AppTheme.textPrimary,
        side: BorderSide(
            color: onPressed == null
                ? AppTheme.border.withOpacity(0.4)
                : AppTheme.border),
        backgroundColor: AppTheme.surfaceAlt,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: content,
    );
  }
}