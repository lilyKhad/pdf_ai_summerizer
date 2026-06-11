import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// datasources
import 'package:pdf_summerizer/features/auth/data/datasource/local/user_local_datasource.dart';
import 'package:pdf_summerizer/features/auth/data/datasource/remote/user_remote_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/local/document_local_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/groq_datasource.dart';
import 'package:pdf_summerizer/features/pdf/data/datasource/remote/supabase_datasource.dart';

// repositories
import 'package:pdf_summerizer/features/auth/data/repository/user_repoImpl.dart';
import 'package:pdf_summerizer/features/pdf/data/repository/document_repoImpl.dart';

// domain repositories (abstract)
import 'package:pdf_summerizer/features/auth/domain/repo/user_repo.dart';
import 'package:pdf_summerizer/features/pdf/domain/repository/document_repo.dart';

// ─────────────────────────────────────────
// CORE
// ─────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─────────────────────────────────────────
// AUTH DATASOURCES
// ─────────────────────────────────────────

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(
    supabase: ref.read(supabaseClientProvider),
  );
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSourceImpl();
});

// ─────────────────────────────────────────
// AUTH REPOSITORY
// ─────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
    localDataSource: ref.read(userLocalDataSourceProvider),
  );
});

// ─────────────────────────────────────────
// PDF DATASOURCES
// ─────────────────────────────────────────

final documentRemoteDataSourceProvider = Provider<DocumentRemoteDataSource>((ref) {
  return DocumentRemoteDataSourceImpl(
    supabase: ref.read(supabaseClientProvider),
  );
});

final documentLocalDataSourceProvider = Provider<DocumentLocalDataSource>((ref) {
  return DocumentLocalDataSourceImpl();
});

final groqDataSourceProvider = Provider<GroqDataSource>((ref) {       // ← renamed
  return GroqDataSourceImpl(
    apiKey: dotenv.env['GROQ_API_KEY'] ?? '',                          // ← GROQ_API_KEY
  );
});

// ─────────────────────────────────────────
// PDF REPOSITORY
// ─────────────────────────────────────────

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: ref.read(documentRemoteDataSourceProvider),
    localDataSource: ref.read(documentLocalDataSourceProvider),
    groqDataSource: ref.read(groqDataSourceProvider),                  // ← renamed param
  );
});