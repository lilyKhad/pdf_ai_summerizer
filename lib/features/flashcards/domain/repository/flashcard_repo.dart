import 'package:pdf_summerizer/features/flashcards/domain/entity/flashcard_entity.dart';

abstract class FlashcardRepository {
  /// Generates flashcards from a document using Groq AI
  Future<List<FlashcardEntity>> generateFlashcards(String documentId);

  /// Saves generated flashcards locally (Hive or similar)
  Future<void> saveFlashcards(List<FlashcardEntity> flashcards);

  /// Loads previously saved flashcards for a document
  Future<List<FlashcardEntity>> getSavedFlashcards(String documentId);
}