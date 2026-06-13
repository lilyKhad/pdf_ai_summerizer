import 'package:pdf_summerizer/features/flashcards/data/datasources/flashcard_datasource.dart';
import 'package:pdf_summerizer/features/flashcards/data/model/flashcard_model.dart';
import 'package:pdf_summerizer/features/flashcards/domain/entity/flashcard_entity.dart';
import 'package:pdf_summerizer/features/flashcards/domain/repository/flashcard_repo.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/supabase_datasource.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardRemoteDataSource remoteDataSource;
  final FlashcardLocalDataSource localDataSource;
  final DocumentRemoteDataSource documentRemoteDataSource;

  FlashcardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.documentRemoteDataSource,
  });

  @override
  Future<List<FlashcardEntity>> generateFlashcards(String documentId) async {
    // Step 1: Check Hive first — if cards exist, no need to call Groq
    final cached = await localDataSource.getFlashcards(documentId);
    if (cached.isNotEmpty) {
      return cached.map((m) => m.toEntity()).toList();
    }

    // Step 2: Get the document to retrieve its original PDF URL
    final doc = await documentRemoteDataSource.getDocument(documentId);

    // Step 3: Call Groq with the real PDF URL (not the summary!)
    final models = await remoteDataSource.generateFlashcards(
      documentId: documentId,
      pdfUrl: doc.url,
    );

    // Step 4: Save to Hive so next time it's instant
    await localDataSource.saveFlashcards(models);

    // Step 5: Return as domain entities
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveFlashcards(List<FlashcardEntity> flashcards) async {
    final models = flashcards.map((e) => FlashcardModel.fromEntity(e)).toList();
    await localDataSource.saveFlashcards(models);
  }

  @override
  Future<List<FlashcardEntity>> getSavedFlashcards(String documentId) async {
    final models = await localDataSource.getFlashcards(documentId);
    return models.map((m) => m.toEntity()).toList();
  }
}
