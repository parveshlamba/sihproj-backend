import 'dart:typed_data';
import 'declaration.dart';

/// Overall result of scanning one packaged commodity's label(s).
class ScanResult {
  final String scanId;

  /// Raw image bytes for the scanned label. Nullable because history
  /// items fetched from a backend later might carry a URL instead —
  /// see [productImageUrl].
  final Uint8List? productImageBytes;

  /// Remote URL for the image, used once real backend storage exists
  /// (e.g. items loaded from scan history rather than just captured).
  final String? productImageUrl;

  final String? productName;
  final List<Declaration> declarations;
  final DateTime scannedAt;

  /// Full raw text as extracted by OCR — useful for debugging misreads
  /// and for letting the officer see exactly what the model read.
  final String? rawOcrText;

  ScanResult({
    required this.scanId,
    this.productImageBytes,
    this.productImageUrl,
    this.productName,
    required this.declarations,
    required this.scannedAt,
    this.rawOcrText,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      scanId: json['scan_id'] as String,
      productImageUrl: json['product_image_url'] as String?,
      productName: json['product_name'] as String?,
      declarations: (json['declarations'] as List)
          .map((d) => Declaration.fromJson(d as Map<String, dynamic>))
          .toList(),
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'product_image_url': productImageUrl,
        'product_name': productName,
        'declarations': declarations.map((d) => d.toJson()).toList(),
        'scanned_at': scannedAt.toIso8601String(),
      };

  int get compliantCount => declarations.where((d) => d.status == 'compliant').length;
  int get nonCompliantCount => declarations.where((d) => d.status == 'non_compliant').length;
  int get missingCount => declarations.where((d) => d.status == 'missing').length;

  /// "compliant" only if every declaration is present and compliant.
  String get overallStatus {
    if (nonCompliantCount == 0 && missingCount == 0) return 'compliant';
    return 'non_compliant';
  }
}
