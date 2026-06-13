import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

/// A shared utility that extracts plain text from PDF bytes.
/// Used by both GroqDataSource (summarization) and
/// FlashcardRemoteDataSource (flashcard generation).
///
/// Think of it as a "PDF reader" tool that any datasource can borrow.
class PdfTextExtractor {
  const PdfTextExtractor();

  /// Tries to extract text from the PDF bytes.
  /// Returns null if the PDF is scanned/image-based (no text layer).
  /// Returns the extracted text string if successful.
  String? extractText(Uint8List pdfBytes) {
    try {
      final document = syncfusion.PdfDocument(inputBytes: pdfBytes);
      final extractor = syncfusion.PdfTextExtractor(document);
      final buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        buffer.writeln(text);
      }

      document.dispose();

      final result = buffer.toString();
      // If less than 50 chars it's basically empty — treat as no text layer
      return result.trim().length > 50 ? result : null;
    } catch (_) {
      return null;
    }
  }
}