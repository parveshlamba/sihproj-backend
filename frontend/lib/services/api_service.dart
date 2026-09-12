import 'package:flutter/foundation.dart';
import 'package:legal_metrology_app/models/declaration.dart';
import 'package:legal_metrology_app/models/scan_result.dart';
import 'package:legal_metrology_app/services/compliance_engine.dart';
import 'package:legal_metrology_app/services/ocr_service.dart';

class ApiService {
  Future submitScan(
    Uint8List imageBytes, {
    String? imagePath,
    String fileName = 'label.jpg',
  }) async {
    if (kIsWeb || imagePath == null) {
      throw Exception(
        'Label scanning uses on-device OCR (Google ML Kit), which only runs '
        'on Android/iOS. Run this app on your phone via `flutter run` '
        '(not Chrome/web) to scan a real label.',
      );
    }

    final ocr = OcrService();
    try {
      final rawText = await ocr.recognizeText(imagePath);

      if (rawText.trim().isEmpty) {
        throw Exception(
          'No text could be read from this image. Try retaking the photo '
          'with better lighting, less glare, and the label filling the frame.',
        );
      }

      // Explicitly construct typed List
      final List<Declaration> declarations = 
          List<Declaration>.from(ComplianceEngine.evaluate(rawText));

      return ScanResult(
        scanId: 'SCAN-${DateTime.now().millisecondsSinceEpoch}',
        productImageBytes: imageBytes,
        scannedAt: DateTime.now(),
        declarations: declarations,
        rawOcrText: rawText,
      );
    } finally {
      ocr.dispose();
    }
  }
}