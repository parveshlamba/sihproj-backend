import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps Google ML Kit's on-device text recognizer.
///
/// Runs entirely on the phone — no backend or internet connection needed.
/// IMPORTANT: only works on Android/iOS builds. Guard with kIsWeb before calling.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Runs OCR on [imagePath] and returns structured, line-ordered extracted text.
  Future recognizeText(String imagePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Google ML Kit Text Recognition is not supported on Flutter Web.');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    return _processRecognizedText(recognizedText);
  }

  /// Groups text blocks and sorts lines top-to-bottom, left-to-right
  /// to preserve label reading order.
  String _processRecognizedText(RecognizedText recognizedText) {
    final StringBuffer buffer = StringBuffer();

    // Extract all individual lines across all text blocks
    final List lines = [];
    for (final TextBlock block in recognizedText.blocks) {
      lines.addAll(block.lines);
    }

    // Sort lines by Y-coordinate (top to bottom), then X-coordinate (left to right)
    lines.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;
      
      // If lines are roughly on the same vertical level (within 12px margin), sort left-to-right
      if ((aTop - bTop).abs() < 12) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return aTop.compareTo(bTop);
    });

    // Reconstruct clean text line-by-line
    for (final line in lines) {
      final text = line.text.trim();
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }

    return buffer.toString();
  }

  /// Call when done scanning to free native resources.
  void dispose() {
    _recognizer.close();
  }
}