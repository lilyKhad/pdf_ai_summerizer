import 'dart:io';
import 'package:pdf_summerizer/features/pdf/data/model/document_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

abstract class DocumentRemoteDataSource {
  Future<DocumentModel> uploadDocument(String filePath);
  Future<List<DocumentModel>> getAllDocuments();
  Future<DocumentModel> getDocument(String documentId);
  Future<void> deleteDocument(String documentId);
  Future<DocumentModel> updateDocument(DocumentModel model);
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final SupabaseClient supabase;
  static const _bucket = 'pdfs';
  static const _table = 'documents';

  DocumentRemoteDataSourceImpl({required this.supabase});

  String get _userId => supabase.auth.currentUser!.id;

  @override
  Future<DocumentModel> uploadDocument(String filePath) async {
  final file = File(filePath);
  final originalName = p.basename(filePath);
  final documentId = const Uuid().v4();

  // sanitize filename: normalize accents + replace invalid chars
  final safeName = _sanitizeFileName(originalName);

  // include documentId in path to avoid duplicate filename collisions
  final storagePath = '$_userId/$documentId/$safeName';

  await supabase.storage.from(_bucket).upload(storagePath, file);

  final url = supabase.storage.from(_bucket).getPublicUrl(storagePath);

  final size = file.lengthSync() / (1024 * 1024);

  final response = await supabase.from(_table).insert({
    'id': documentId,
    'user_id': _userId,
    'name': originalName, // keep original name for display
    'url': url,
    'size': size,
    'status': 'idle',
    'uploaded_at': DateTime.now().toIso8601String(),
  }).select().single();

  return DocumentModel.fromJson(response);
}

String _sanitizeFileName(String fileName) {
  final normalized = fileName
      .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e')
      .replaceAll('à', 'a').replaceAll('â', 'a').replaceAll('ä', 'a')
      .replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
      .replaceAll('î', 'i').replaceAll('ï', 'i')
      .replaceAll('ô', 'o').replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('É', 'E').replaceAll('È', 'E').replaceAll('Ê', 'E')
      .replaceAll('À', 'A').replaceAll('Â', 'A')
      .replaceAll('Ù', 'U').replaceAll('Û', 'U')
      .replaceAll('Î', 'I').replaceAll('Ô', 'O')
      .replaceAll('Ç', 'C');

  // replace anything not alphanumeric, dash, underscore, or dot with underscore
  return normalized.replaceAll(RegExp(r'[^\w\-.]'), '_');
}

  @override
  Future<List<DocumentModel>> getAllDocuments() async {
    final response = await supabase
        .from(_table)
        .select()
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DocumentModel> getDocument(String documentId) async {
    final response = await supabase
        .from(_table)
        .select()
        .eq('id', documentId)
        .single();

    return DocumentModel.fromJson(response);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    // get doc first to find the storage path
    final doc = await getDocument(documentId);

    // extract storage path from URL: pdfs/{userId}/{fileName}
    final uri = Uri.parse(doc.url);
    final storagePath = uri.pathSegments
        .skipWhile((s) => s != _bucket)
        .skip(1)
        .join('/');

    // delete from storage
    await supabase.storage.from(_bucket).remove([storagePath]);

    // delete from DB
    await supabase.from(_table).delete().eq('id', documentId);
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel model) async {
    final response = await supabase
        .from(_table)
        .update({
          'status': model.status,
          'summary': model.summary,
          'error_message': model.errorMessage,
        })
        .eq('id', model.id)
        .select()
        .single();

    return DocumentModel.fromJson(response);
  }
}