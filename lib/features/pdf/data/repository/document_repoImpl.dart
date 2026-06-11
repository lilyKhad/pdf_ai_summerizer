import 'package:pdf_summerizer/features/pdf/data/datasource/local/document_local_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/groq_datasource.dart'; // Changed from gemini_datasource
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/supabase_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/model/document_module.dart';
import 'package:pdf_summerizer/features/pdf/domain/entity/pdf_document.dart';
import 'package:pdf_summerizer/features/pdf/domain/repository/document_repo.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;
  final GroqDataSource groqDataSource; // Changed from GeminiDataSource
  final DocumentLocalDataSource localDataSource;

  DocumentRepositoryImpl({
    required this.remoteDataSource,
    required this.groqDataSource, // Changed from geminiDataSource
    required this.localDataSource,
  });

  @override
  Future<DocumentEntity> addDocument(String filePath) async {
    final model = await remoteDataSource.uploadDocument(filePath);
    return model.toEntity();
  }

  @override
  Future<DocumentEntity> getDocument(String documentId) async {
    final model = await remoteDataSource.getDocument(documentId);
    return model.toEntity();
  }

  @override
  Future<List<DocumentEntity>> getAllDocuments() async {
    try {
      final models = await remoteDataSource.getAllDocuments();
      await localDataSource.cacheDocuments(models);
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      final cached = await localDataSource.getCachedDocuments();
      return cached.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await remoteDataSource.deleteDocument(documentId);
  }

  @override
  Future<DocumentEntity> summarizeDocument(String documentId) async {
    DocumentModel model = await remoteDataSource.getDocument(documentId);

    model = await remoteDataSource.updateDocument(
      model.copyWith(status: DocumentStatus.processing),
    );

    try {
      // Changed from geminiDataSource to groqDataSource
      final summary = await groqDataSource.summarizePdf(model.url);
      final updated = await remoteDataSource.updateDocument(
        model.copyWith(status: DocumentStatus.done, summary: summary),
      );
      return updated.toEntity();
    } catch (e) {
      await remoteDataSource.updateDocument(
        model.copyWith(status: DocumentStatus.error, errorMessage: e.toString()),
      );
      rethrow;
    }
  }
}