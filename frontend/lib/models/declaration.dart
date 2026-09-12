/// Represents a single mandatory declaration field checked under
/// the Legal Metrology (Packaged Commodities) Rules, 2011
/// e.g. MRP, Net Quantity, Mfg Date, Manufacturer Address, Consumer Care.
class Declaration {
  final String type; // "mrp", "net_quantity", "mfg_date", "address", "consumer_care", "country_of_origin"
  final String label; // human-readable name shown in UI
  final bool isPresent;
  final bool isCompliant;
  final String? extractedText;
  final double? confidenceScore; // 0.0 - 1.0, from OCR/detection model
  final String? ruleReference; // e.g. "Rule 6(1)(a)"
  final String? issue; // human-readable reason for non-compliance, null if compliant

  Declaration({
    required this.type,
    required this.label,
    required this.isPresent,
    required this.isCompliant,
    this.extractedText,
    this.confidenceScore,
    this.ruleReference,
    this.issue,
  });

  factory Declaration.fromJson(Map<String, dynamic> json) {
    return Declaration(
      type: json['type'] as String,
      label: json['label'] as String,
      isPresent: json['is_present'] as bool,
      isCompliant: json['is_compliant'] as bool,
      extractedText: json['extracted_text'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      ruleReference: json['rule_reference'] as String?,
      issue: json['issue'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'is_present': isPresent,
        'is_compliant': isCompliant,
        'extracted_text': extractedText,
        'confidence_score': confidenceScore,
        'rule_reference': ruleReference,
        'issue': issue,
      };

  /// "compliant" | "non_compliant" | "missing"
  String get status {
    if (!isPresent) return 'missing';
    return isCompliant ? 'compliant' : 'non_compliant';
  }
}
