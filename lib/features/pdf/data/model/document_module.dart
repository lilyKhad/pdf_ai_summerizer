import 'package:pdf_summerizer/features/pdf/domain/entity/pdf_document.dart';

class DocumentModel {
  final String id;
  final String name;
  final String url;
  final double size;
  final DateTime uploadedAt;
  final String status;        // stored as String in Supabase ("idle", "done"...)
  final String? summary;
  final String? errorMessage;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.uploadedAt,
    required this.status,
    this.summary,
    this.errorMessage,
  });

  // Supabase returns Map<String, dynamic>
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      size: (json['size'] as num).toDouble(),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      status: json['status'] as String,
      summary: json['summary'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  // When saving to Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'size': size,
      'uploaded_at': uploadedAt.toIso8601String(),
      'status': status,
      'summary': summary,
      'error_message': errorMessage,
    };
  }

  // Model → Entity (for domain/UI layer)
  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      name: name,
      url: url,
      size: size,
      uploadedAt: uploadedAt,
      status: DocumentStatus.values.firstWhere((e) => e.name == status),
      summary: summary,
      errorMessage: errorMessage,
    );
  }

  // Entity → Model (when you want to save an entity)
  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      name: entity.name,
      url: entity.url,
      size: entity.size,
      uploadedAt: entity.uploadedAt,
      status: entity.status.name,   // enum → String
      summary: entity.summary,
      errorMessage: entity.errorMessage,
    );
  }

  DocumentModel copyWith({
    String? id,
    String? name,
    String? url,
    double? size,
    DateTime? uploadedAt,
    DocumentStatus? status,
    String? summary,
    String? errorMessage,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status?.name ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}