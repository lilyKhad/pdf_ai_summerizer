import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// datasources — auth
import 'package:pdf_summerizer/features/auth/data/datasource/local/user_local_datasource.dart';
import 'package:pdf_summerizer/features/auth/data/datasource/remote/user_remote_datasource.dart';

// datasources — pdf
import 'package:pdf_summerizer/features/pdf/data/datasource/local/document_local_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/groq_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/supabase_datasource.dart';

// datasources — flashcards
import 'package:pdf_summerizer/features/flashcards/data/datasources/flashcard_datasource.dart';

// repositories
import 'package:pdf_summerizer/features/auth/data/repository/user_repoImpl.dart';
import 'package:pdf_summerizer/features/pdf/data/repository/document_repoImpl.dart';
import 'package:pdf_summerizer/features/flashcards/data/repository/flashcard_repoImpl.dart';

// domain repositories (abstract)
import 'package:pdf_summerizer/features/auth/domain/repo/user_repo.dart';
import 'package:pdf_summerizer/features/pdf/domain/repository/document_repo.dart';
import 'package:pdf_summerizer/features/flashcards/domain/repository/flashcard_repo.dart';

// ─────────────────────────────────────────
// CORE
// ─────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(supabase: ref.read(supabaseClientProvider));
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSourceImpl();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
    localDataSource: ref.read(userLocalDataSourceProvider),
  );
});

// ─────────────────────────────────────────
// PDF
// ─────────────────────────────────────────

final documentRemoteDataSourceProvider = Provider<DocumentRemoteDataSource>((ref) {
  return DocumentRemoteDataSourceImpl(supabase: ref.read(supabaseClientProvider));
});

final documentLocalDataSourceProvider = Provider<DocumentLocalDataSource>((ref) {
  return DocumentLocalDataSourceImpl();
});

final groqDataSourceProvider = Provider<GroqDataSource>((ref) {
  return GroqDataSourceImpl(apiKey: dotenv.env['GROQ_API_KEY'] ?? '');
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: ref.read(documentRemoteDataSourceProvider),
    localDataSource: ref.read(documentLocalDataSourceProvider),
    groqDataSource: ref.read(groqDataSourceProvider),
  );
});

// ─────────────────────────────────────────
// FLASHCARDS
// ─────────────────────────────────────────

final flashcardRemoteDataSourceProvider = Provider<FlashcardRemoteDataSource>((ref) {
  return FlashcardRemoteDataSourceImpl(
    apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
  );
});

final flashcardLocalDataSourceProvider = Provider<FlashcardLocalDataSource>((ref) {
  return FlashcardLocalDataSourceImpl();
});

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepositoryImpl(
    remoteDataSource: ref.read(flashcardRemoteDataSourceProvider),
    localDataSource: ref.read(flashcardLocalDataSourceProvider),
    documentRemoteDataSource: ref.read(documentRemoteDataSourceProvider),
  );
});