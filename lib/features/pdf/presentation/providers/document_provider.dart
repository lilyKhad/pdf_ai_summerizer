import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pdf_summerizer/core/injection/injection.dart';
import 'package:pdf_summerizer/features/pdf/domain/entity/pdf_document.dart';
import 'package:pdf_summerizer/features/pdf/domain/repository/document_repo.dart';

// ─────────────────────────────────────────
// STATE
// ─────────────────────────────────────────

class DocumentState {
  final List<DocumentEntity> documents;
  final bool isLoading;
  final bool hasLoaded;      // ← NEW: true once the first load completes
  final String? errorMessage;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  DocumentState copyWith({
    List<DocumentEntity>? documents,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────

class DocumentNotifier extends StateNotifier<DocumentState> {
  final DocumentRepository _repository;

  DocumentNotifier(this._repository) : super(const DocumentState());

  Future<void> loadDocuments() async {
    // Guard: never fire a second load while one is already running
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final docs = await _repository.getAllDocuments();
      state = state.copyWith(
        documents: docs,
        isLoading: false,
        hasLoaded: true,  // mark as loaded regardless of list size
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'Failed to load documents: ${e.toString()}',
      );
    }
  }

  Future<void> addDocument(String filePath) async {
    // Don't block the whole list — just show a temporary uploading entry
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newDoc = await _repository.addDocument(filePath);
      state = state.copyWith(
        documents: [newDoc, ...state.documents],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Upload failed: ${e.toString()}',
      );
    }
  }

  Future<void> summarizeDocument(String documentId) async {
    _updateDocumentInList(
        documentId, (doc) => doc.copyWith(status: DocumentStatus.processing));

    try {
      final updated = await _repository.summarizeDocument(documentId);
      _updateDocumentInList(documentId, (_) => updated);
    } catch (e) {
      _updateDocumentInList(
          documentId,
          (doc) => doc.copyWith(
                status: DocumentStatus.error,
                errorMessage: 'Summarization failed: ${e.toString()}',
              ));
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
      state = state.copyWith(
        documents: state.documents.where((d) => d.id != documentId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to delete: ${e.toString()}');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _updateDocumentInList(
    String documentId,
    DocumentEntity Function(DocumentEntity) update,
  ) {
    state = state.copyWith(
      documents: state.documents.map((doc) {
        return doc.id == documentId ? update(doc) : doc;
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────

final documentProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier(ref.read(documentRepositoryProvider));
});

final documentsListProvider = Provider<List<DocumentEntity>>((ref) {
  return ref.watch(documentProvider).documents;
});

final documentByIdProvider =
    Provider.family<DocumentEntity?, String>((ref, id) {
  return ref.watch(documentsListProvider).where((d) => d.id == id).firstOrNull;
});
