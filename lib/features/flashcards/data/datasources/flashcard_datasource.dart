import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx_engine/pdfrx_engine.dart' as pdfrx;
import 'package:pdf_summerizer/core/utils/pdf_text_extractor.dart';
import 'package:pdf_summerizer/features/flashcards/data/model/flashcard_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT CONTRACTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class FlashcardRemoteDataSource {
  Future<List<FlashcardModel>> generateFlashcards({
    required String documentId,
    required String pdfUrl,
  });
}

abstract class FlashcardLocalDataSource {
  Future<void> saveFlashcards(List<FlashcardModel> flashcards);
  Future<List<FlashcardModel>> getFlashcards(String documentId);
  Future<void> deleteFlashcards(String documentId);
}

// ─────────────────────────────────────────────────────────────────────────────
// GROQ IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardRemoteDataSourceImpl implements FlashcardRemoteDataSource {
  final String apiKey;
  final PdfTextExtractor _pdfExtractor;

  static const _textModel = 'llama-3.3-70b-versatile';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  FlashcardRemoteDataSourceImpl({
    required this.apiKey,
    PdfTextExtractor? pdfExtractor,
  }) : _pdfExtractor = pdfExtractor ?? const PdfTextExtractor();

  @override
  Future<List<FlashcardModel>> generateFlashcards({
    required String documentId,
    required String pdfUrl,
  }) async {
    final fileResponse = await http.get(Uri.parse(pdfUrl));
    if (fileResponse.statusCode != 200) {
      throw Exception('Failed to download PDF for flashcard generation');
    }

    final pdfBytes = fileResponse.bodyBytes;
    final extractedText = _pdfExtractor.extractText(pdfBytes);

    final String rawResponse;
    if (extractedText != null) {
      rawResponse = await _generateWithText(extractedText);
    } else {
      final base64Image = await _renderFirstPageAsImage(pdfBytes);
      rawResponse = await _generateWithVision(base64Image);
    }

    return _parseFlashcards(rawResponse, documentId);
  }

  Future<String> _generateWithText(String text) async {
    final truncated = text.length > 12000
        ? '${text.substring(0, 12000)}...'
        : text;

    final body = jsonEncode({
      'model': _textModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a flashcard generator. You only respond with valid JSON arrays. '
              'No markdown, no explanation, no code blocks. Raw JSON only.',
        },
        {'role': 'user', 'content': _buildTextPrompt(truncated)},
      ],
      'temperature': 0.4,
      'max_tokens': 2048,
    });

    return await _callGroq(body);
  }

  Future<String> _generateWithVision(String base64Image) async {
    final body = jsonEncode({
      'model': _visionModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$base64Image'},
            },
            {'type': 'text', 'text': _buildVisionPrompt()},
          ],
        }
      ],
      'temperature': 0.4,
      'max_tokens': 2048,
    });

    return await _callGroq(body);
  }

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

  String _buildTextPrompt(String content) => '''
Based on the document below, generate between 8 and 12 flashcards covering the most important concepts, facts, and ideas.

IMPORTANT RULES:
- Return ONLY a valid JSON array. Nothing else.
- No markdown, no code block, no explanation before or after.
- Each item must have exactly two fields: "question" and "answer".
- Questions should test understanding, not just memory.
- Answers should be concise (1-3 sentences max).

Example format:
[
  {"question": "What is X?", "answer": "X is ..."},
  {"question": "Why does Y happen?", "answer": "Because ..."}
]

Document:
$content''';

  String _buildVisionPrompt() => '''
Look at this document page and generate between 8 and 12 flashcards from its content.

IMPORTANT RULES:
- Return ONLY a valid JSON array. Nothing else.
- No markdown, no code block, no explanation.
- Each item must have exactly: "question" and "answer".

Example:
[
  {"question": "What is X?", "answer": "X is ..."}
]''';

  List<FlashcardModel> _parseFlashcards(String rawResponse, String documentId) {
    final cleaned = rawResponse
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final List<dynamic> parsed = jsonDecode(cleaned);
    return parsed
        .map((item) => FlashcardModel.fromGroqJson(
              item as Map<String, dynamic>,
              documentId,
            ))
        .toList();
  }

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
      throw Exception(
          'Groq flashcard error: ${response.statusCode} — ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq returned no choices for flashcards');
    }

    return choices[0]['message']['content'] as String;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  static const _boxName = 'flashcards_box';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  @override
  Future<void> saveFlashcards(List<FlashcardModel> flashcards) async {
    if (flashcards.isEmpty) return;
    final box = await _openBox();
    final key = 'fc_${flashcards.first.documentId}';
    final value = jsonEncode(flashcards.map((f) => f.toJson()).toList());
    await box.put(key, value);
  }

  @override
  Future<List<FlashcardModel>> getFlashcards(String documentId) async {
    final box = await _openBox();
    final raw = box.get('fc_$documentId') as String?;
    if (raw == null) return [];
    final List<dynamic> parsed = jsonDecode(raw);
    return parsed
        .map((item) => FlashcardModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteFlashcards(String documentId) async {
    final box = await _openBox();
    await box.delete('fc_$documentId');
  }
}