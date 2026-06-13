import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pdf_summerizer/core/injection/injection.dart';
import 'package:pdf_summerizer/features/flashcards/domain/entity/flashcard_entity.dart';

class FlashcardState {
  final List<FlashcardEntity> flashcards;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;

  const FlashcardState({
    this.flashcards = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => flashcards.isEmpty;
  bool get hasCards => flashcards.isNotEmpty;
  int get total => flashcards.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == flashcards.length - 1;

  FlashcardEntity? get currentCard =>
      flashcards.isEmpty ? null : flashcards[currentIndex];

  FlashcardState copyWith({
    List<FlashcardEntity>? flashcards,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FlashcardState(
      flashcards: flashcards ?? this.flashcards,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  final Ref _ref;
  final String documentId;

  FlashcardNotifier(this._ref, this.documentId)
      : super(const FlashcardState());

  Future<void> loadOrGenerate() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(flashcardRepositoryProvider);
      final saved = await repo.getSavedFlashcards(documentId);
      state = state.copyWith(
        flashcards: saved,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> generateFlashcards() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(flashcardRepositoryProvider);
      final cards = await repo.generateFlashcards(documentId);
      state = state.copyWith(
        flashcards: cards,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void flipCard() {
    if (state.currentCard == null) return;
    final updated = List<FlashcardEntity>.from(state.flashcards);
    updated[state.currentIndex] = state.currentCard!.copyWith(
      isAnswerVisible: !state.currentCard!.isAnswerVisible,
    );
    state = state.copyWith(flashcards: updated);
  }

  void nextCard() {
    if (state.isLast) return;
    _hideCurrentAnswer();
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void previousCard() {
    if (state.isFirst) return;
    _hideCurrentAnswer();
    state = state.copyWith(currentIndex: state.currentIndex - 1);
  }

  void _hideCurrentAnswer() {
    if (state.currentCard == null) return;
    final updated = List<FlashcardEntity>.from(state.flashcards);
    updated[state.currentIndex] =
        state.currentCard!.copyWith(isAnswerVisible: false);
    state = state.copyWith(flashcards: updated);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final flashcardProvider = StateNotifierProvider.family<
    FlashcardNotifier, FlashcardState, String>(
  (ref, documentId) => FlashcardNotifier(ref, documentId),
);