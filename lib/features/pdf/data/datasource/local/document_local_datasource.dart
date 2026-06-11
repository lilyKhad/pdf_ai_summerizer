import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pdf_summerizer/features/pdf/data/model/document_module.dart';

abstract class DocumentLocalDataSource {
  Future<void> cacheDocuments(List<DocumentModel> models);
  Future<List<DocumentModel>> getCachedDocuments();
  Future<void> clearCache();
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  static const _boxName = 'documents_box';
  static const _documentsKey = 'cached_documents';

  @override
  Future<void> cacheDocuments(List<DocumentModel> models) async {
    final box = await Hive.openBox(_boxName);
    final encoded = models.map((m) => jsonEncode(m.toJson())).toList();
    await box.put(_documentsKey, encoded);
  }

  @override
  Future<List<DocumentModel>> getCachedDocuments() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_documentsKey);
    if (raw == null) return [];
    final list = (raw as List).cast<String>();
    return list
        .map((e) => DocumentModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_documentsKey);
  }
}