class DocumentEntity {
  final String id;
  final String name;
  final String url;
  final double size;
  final DateTime uploadedAt;
  final DocumentStatus status;
  final String? summary;
  final String? errorMessage;
  
  const DocumentEntity({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.uploadedAt,
    this.status = DocumentStatus.idle,
    this.summary,
    this.errorMessage,
  });

  // 1. copyWith — immutable updates
  DocumentEntity copyWith({
    String? id,
    String? name,
    String? url,
    double? size,
    DateTime? uploadedAt,
    DocumentStatus? status,
    String? summary,
    String? errorMessage,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // 2. Equality — so Riverpod/Provider detects changes correctly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          summary == other.summary;

  @override
  int get hashCode => Object.hash(id, status, summary);

  // 3. Convenience getters — avoid scattered status checks in UI
  bool get isProcessing => status == DocumentStatus.processing;
  bool get isDone => status == DocumentStatus.done;
  bool get hasError => status == DocumentStatus.error;
  bool get hasSummary => summary != null && summary!.isNotEmpty;
}
enum DocumentStatus { idle, processing, done, error }