class FlashcardEntity {
  final String id;
  final String documentId;
  final String question;
  final String answer;
  final bool isAnswerVisible; // ← UI state lives here

  const FlashcardEntity({
    required this.id,
    required this.documentId,
    required this.question,
    required this.answer,
    this.isAnswerVisible = false, // hidden by default
  });

  FlashcardEntity copyWith({bool? isAnswerVisible}) {
    return FlashcardEntity(
      id: id,
      documentId: documentId,
      question: question,
      answer: answer,
      isAnswerVisible: isAnswerVisible ?? this.isAnswerVisible,
    );
  }
}