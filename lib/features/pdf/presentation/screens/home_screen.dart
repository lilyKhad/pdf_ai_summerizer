import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_summerizer/core/router/app_router.dart';
import 'package:pdf_summerizer/features/auth/presentation/providers/auth_provider.dart';
import 'package:pdf_summerizer/features/pdf/domain/entity/pdf_document.dart';
import 'package:pdf_summerizer/features/pdf/presentation/providers/document_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load once, safely, after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentProvider.notifier).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final auth = ref.watch(authProvider);

    // Show errors from the document provider as snackbars
    ref.listen<DocumentState>(documentProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(next.errorMessage!)),
            ]),
          ),
        );
        ref.read(documentProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Summarizer'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 5),
                Text(
                  auth.user?.email.split('@').first ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: _buildBody(context, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isLoading ? null : () => _pickAndUpload(context),
        icon: state.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded, size: 20),
        label: Text(
          state.isLoading ? 'Uploading…' : 'Upload PDF',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DocumentState state) {
    // Still on first load — show spinner only
    if (!state.hasLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    // Loaded, empty list
    if (state.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined,
                  size: 32, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No documents yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a PDF to get an AI summary',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Has documents
    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      onRefresh: () =>
          ref.read(documentProvider.notifier).loadDocuments(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _DocumentTile(doc: state.documents[index]);
        },
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    await ref
        .read(documentProvider.notifier)
        .addDocument(result.files.single.path!);
  }
}

// ─────────────────────────────────────────
// Document tile (unchanged logic, same design)
// ─────────────────────────────────────────

class _DocumentTile extends ConsumerWidget {
  final DocumentEntity doc;
  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: doc.isDone
            ? () => Navigator.pushNamed(context, '/summary',
                arguments: doc.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${doc.size.toStringAsFixed(2)} MB',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (doc.isProcessing) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.accent),
          ),
        ),
      );
    }

    final (icon, color) = doc.isDone
        ? (Icons.check_circle_rounded, AppTheme.success)
        : doc.hasError
            ? (Icons.error_rounded, AppTheme.error)
            : (Icons.picture_as_pdf_outlined, AppTheme.textSecondary);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (doc.isDone)
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary),
        if (!doc.isDone && !doc.isProcessing)
          IconButton(
            icon: Icon(
              doc.hasError
                  ? Icons.refresh_rounded
                  : Icons.auto_awesome_rounded,
              color:
                  doc.hasError ? AppTheme.error : AppTheme.accent,
              size: 20,
            ),
            tooltip: doc.hasError ? 'Retry' : 'Summarize',
            onPressed: () => ref
                .read(documentProvider.notifier)
                .summarizeDocument(doc.id),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppTheme.textSecondary, size: 20),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('Delete document',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove "${doc.name}"? This can\'t be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(documentProvider.notifier)
          .deleteDocument(doc.id);
    }
  }
}
