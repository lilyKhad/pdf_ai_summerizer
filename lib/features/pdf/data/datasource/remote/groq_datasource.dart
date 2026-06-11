import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;  // ← add prefix
import 'package:pdfrx_engine/pdfrx_engine.dart' as pdfrx;        // ← add prefix

abstract class GroqDataSource {
  Future<String> summarizePdf(String fileUrl);
}

class GroqDataSourceImpl implements GroqDataSource {
  final String apiKey;

  // Text model for normal PDFs
  static const _textModel = 'llama-3.3-70b-versatile';
  // Vision model for scanned/image-based PDFs
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqDataSourceImpl({required this.apiKey});

  @override
  Future<String> summarizePdf(String fileUrl) async {
    // Step 1: Download PDF bytes
    final fileResponse = await http.get(Uri.parse(fileUrl));
    if (fileResponse.statusCode != 200) {
      throw Exception('Failed to download PDF from Supabase');
    }

    final pdfBytes = fileResponse.bodyBytes;

    // Step 2: Try text extraction first
    final extractedText = _extractText(pdfBytes);

    if (extractedText != null && extractedText.trim().length > 50) {
      // Normal PDF — use text model
      return await _summarizeWithText(extractedText);
    } else {
      // Scanned PDF — render first page as image, use vision model
      final pageImage = await _renderFirstPageAsImage(pdfBytes);
      return await _summarizeWithVision(pageImage);
    }
  }

  // ─── Text Extraction ───────────────────────────────────────────────────────

  String? _extractText(Uint8List pdfBytes) {
  try {
    final document = syncfusion.PdfDocument(inputBytes: pdfBytes);
    final extractor = syncfusion.PdfTextExtractor(document);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      buffer.writeln(text);
    }

    document.dispose();
    return buffer.toString();
  } catch (_) {
    return null;
  }
}

  // ─── Page Rendering (for scanned PDFs) ────────────────────────────────────

  

Future<String> _renderFirstPageAsImage(Uint8List pdfBytes) async {
  await pdfrx.pdfrxInitialize();

  final document = await pdfrx.PdfDocument.openData(pdfBytes);
  final page = document.pages[0];

  final pageImage = await page.render(
    width: (page.width * 2).toInt(),
    height: (page.height * 2).toInt(),
  );

  document.dispose();

  if (pageImage == null) throw Exception('Failed to render PDF page');

  return base64Encode(pageImage.pixels);
}
  // ─── Summarize via Text ────────────────────────────────────────────────────

  Future<String> _summarizeWithText(String text) async {
    final truncated = text.length > 15000
        ? '${text.substring(0, 15000)}...'
        : text;

    final body = jsonEncode({
      'model': _textModel,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a document summarizer. Provide clear and concise summaries.',
        },
        {
          'role': 'user',
          'content': _buildPrompt(truncated),
        }
      ],
      'temperature': 0.3,
      'max_tokens': 1024,
    });

    return await _callGroq(body);
  }

  // ─── Summarize via Vision ──────────────────────────────────────────────────

  Future<String> _summarizeWithVision(String base64Image) async {
    final body = jsonEncode({
      'model': _visionModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/png;base64,$base64Image',
              },
            },
            {
              'type': 'text',
              'text': _buildPrompt('(extracted from scanned PDF page image)'),
            }
          ],
        }
      ],
      'temperature': 0.3,
      'max_tokens': 1024,
    });

    return await _callGroq(body);
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────────

  String _buildPrompt(String content) => '''
Please provide a clear and concise summary of this document.

Structure your response with:
- A brief overview (2-3 sentences)
- Key points (bullet points)
- Main conclusion

Document content:
$content''';

  Future<String> _callGroq(String body) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode} — ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq returned no choices');
    }

    return choices[0]['message']['content'] as String;
  }
}