import 'package:pdf_summerizer/features/pdf/domain/entity/pdf_document.dart';

abstract class DocumentRepository {
  // CRUD
  Future<DocumentEntity> addDocument(String filePath);
  Future<DocumentEntity> getDocument(String documentId);
  Future<List<DocumentEntity>> getAllDocuments();
  Future<void> deleteDocument(String documentId);

  // Gemini
  Future<DocumentEntity> summarizeDocument(String documentId);
}