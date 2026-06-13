import 'package:uuid/uuid.dart';
import 'package:pdf_summerizer/features/flashcards/domain/entity/flashcard_entity.dart';

class FlashcardModel {
  final String id;
  final String documentId;
  final String question;
  final String answer;

  FlashcardModel({
    required this.id,
    required this.documentId,
    required this.question,
    required this.answer,
  });

  // Used when parsing Groq AI response (no id or documentId in the response)
  factory FlashcardModel.fromGroqJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return FlashcardModel(
      id: const Uuid().v4(),         // ← generate id since Groq doesn't provide one
      documentId: documentId,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }

  // Used when loading from local storage (Hive/Supabase)
  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      // ← isAnswerVisible intentionally excluded: always starts hidden
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'question': question,
      'answer': answer,
      // ← isAnswerVisible intentionally excluded: UI state, not persisted
    };
  }

  // ─── Mappers ───────────────────────────────────────────────────────────────

  FlashcardEntity toEntity() {
    return FlashcardEntity(
      id: id,
      documentId: documentId,
      question: question,
      answer: answer,
      // isAnswerVisible defaults to false in the entity
    );
  }

  factory FlashcardModel.fromEntity(FlashcardEntity entity) {
    return FlashcardModel(
      id: entity.id,
      documentId: entity.documentId,
      question: entity.question,
      answer: entity.answer,
    );
  }
}