import '../models/declaration.dart';

/// Automated Rule-Based Engine enforcing Legal Metrology (Packaged Commodities) Rules
class ComplianceEngine {
  static List evaluate(String rawText, {double? packageWeightGrams}) {
    final text = _normalizeOcrText(rawText);

    // Rule 26(a): Exemption check for small packages <= 10g/10ml
    if (packageWeightGrams != null && packageWeightGrams <= 10) {
      return [
        Declaration(
          type: 'exemption_26a',
          label: 'Small Package Exemption [Rule 26(a)]',
          isPresent: true,
          isCompliant: true,
          extractedText: '${packageWeightGrams}g',
          ruleReference: 'Rule 26(a)',
          issue: null,
        )
      ];
    }

    return [
      _checkManufacturerDetails(text), // R6_1_A / R10
      _checkNetQuantity(text),          // R6_1_C / R13
      _checkMfgDate(text),              // R6_1_D
      _checkMrpAndUsp(text),            // R6_1_E / R6_11
      _checkConsumerCare(text),         // R6_2
      _checkCountryOfOrigin(text),      // Rule 6(1)(aa)
    ];
  }

  /// Cleans OCR artifacts and flattens line breaks for uninterrupted pattern matching
  static String _normalizeOcrText(String raw) {
    return raw
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\b(MRB|M\.R\.B|MRP)\b', caseSensitive: false), 'MRP')
        .replaceAll(RegExp(r'\b(Rs\.|RS|₹)\b'), 'Rs. ');
  }

  /// R6_1_A & R10: Manufacturer, Packer, or Importer Name and Address
  static Declaration _checkManufacturerDetails(String text) {
    final hasAddressKeyword = RegExp(
      r'(mfd\s+by|manufactured\s+by|packed\s+by|marketed\s+by|imported\s+by|pvt\.?\s*ltd|private\s+limited)',
      caseSensitive: false,
    ).hasMatch(text);

    final hasPincode = RegExp(r'\b\d{6}\b').hasMatch(text);

    if (hasAddressKeyword && hasPincode) {
      return Declaration(
        type: 'address',
        label: 'Manufacturer / Packer Address',
        isPresent: true,
        isCompliant: true,
        confidenceScore: 0.85,
        ruleReference: 'Rule 6(1)(a) / Rule 10',
      );
    }

    return Declaration(
      type: 'address',
      label: 'Manufacturer / Packer Address',
      isPresent: hasAddressKeyword || hasPincode,
      isCompliant: false,
      confidenceScore: (hasAddressKeyword || hasPincode) ? 0.45 : 0.0,
      ruleReference: 'Rule 6(1)(a) / Rule 10',
      issue: 'Incomplete address details. Legal Metrology requires company name, address, and 6-digit PIN code.',
    );
  }

  /// R6_1_C & R13: Net Quantity & Approved Units
  static Declaration _checkNetQuantity(String text) {
    final qtyRegex = RegExp(
      r'(?:net\s*(?:qty|quantity|wt|weight)?[^\d]{0,10})?(\b\d+(?:\.\d+)?\s*(?:g|gm|grams?|kg|kilograms?|ml|millilitres?|l|litres?|N|U)\b)',
      caseSensitive: false,
    );

    final match = qtyRegex.firstMatch(text);

    if (match != null) {
      return Declaration(
        type: 'net_quantity',
        label: 'Net Quantity',
        isPresent: true,
        isCompliant: true,
        extractedText: match.group(0)?.trim(),
        confidenceScore: 0.90,
        ruleReference: 'Rule 6(1)(c) / Rule 13',
      );
    }

    return Declaration(
      type: 'net_quantity',
      label: 'Net Quantity',
      isPresent: false,
      isCompliant: false,
      ruleReference: 'Rule 6(1)(c) / Rule 13',
      issue: 'Net quantity declaration missing or missing standard metric units (g, kg, ml, l, N, U).',
    );
  }

  /// R6_1_D: Date of Manufacture or Packing
  static Declaration _checkMfgDate(String text) {
    final dateRegex = RegExp(
      r'(?:MFG|MFD|Mfg\.?\s*Date|Manufactured|PKD|Pkd\.?\s*Date|Packed)[^\d]{0,12}'
      r'(\d{1,2}[\/\-.]\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-.]?\d{2,4})',
      caseSensitive: false,
    );

    final match = dateRegex.firstMatch(text);

    if (match == null) {
      return Declaration(
        type: 'mfg_date',
        label: 'Date of Manufacture / Packing',
        isPresent: false,
        isCompliant: false,
        ruleReference: 'Rule 6(1)(d)',
        issue: 'Month and year of manufacture/packing not detected on package.',
      );
    }

    return Declaration(
      type: 'mfg_date',
      label: 'Date of Manufacture / Packing',
      isPresent: true,
      isCompliant: true,
      extractedText: match.group(0)?.trim(),
      confidenceScore: 0.88,
      ruleReference: 'Rule 6(1)(d)',
    );
  }

  /// R6_1_E & Rule 6(11): MRP ("Inclusive of all taxes") and Unit Sale Price (USP)
  static Declaration _checkMrpAndUsp(String text) {
    final mrpRegex = RegExp(
      r'(?:MRP|Maximum\s+Retail\s+Price)[^\d₹]{0,15}(?:Rs\.\s*|₹\s*|INR\s*)?([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final match = mrpRegex.firstMatch(text);

    if (match == null) {
      return Declaration(
        type: 'mrp',
        label: 'Maximum Retail Price (MRP)',
        isPresent: false,
        isCompliant: false,
        ruleReference: 'Rule 6(1)(e)',
        issue: 'MRP declaration not detected on label.',
      );
    }

    // Verify proximity clause within a 100-character window
    final matchStart = match.start;
    final contextWindow = text.substring(
      (matchStart - 20).clamp(0, text.length),
      (matchStart + 80).clamp(0, text.length),
    );

    final hasTaxClause = RegExp(
      r'(inclusive\s+of\s+all\s+taxes|incl\.?\s*of\s*all\s*taxes|incl\.?\s*taxes)',
      caseSensitive: false,
    ).hasMatch(contextWindow);

    final hasUsp = RegExp(
      r'(?:unit\s*sale\s*price|usp)[^\d]{0,10}(?:Rs\.\s*|₹\s*)?[\d.]+\s*(?:per|\/)\s*(?:g|gm|kg|ml|l|N|U)',
      caseSensitive: false,
    ).hasMatch(text);

    final isFullyCompliant = hasTaxClause && hasUsp;

    return Declaration(
      type: 'mrp',
      label: 'Maximum Retail Price (MRP) & Unit Sale Price',
      isPresent: true,
      isCompliant: isFullyCompliant,
      extractedText: match.group(0)?.trim(),
      confidenceScore: isFullyCompliant ? 0.92 : 0.60,
      ruleReference: 'Rule 6(1)(e) & Rule 6(11)',
      issue: !hasTaxClause
          ? 'MRP missing mandatory "inclusive of all taxes" clause.'
          : (!hasUsp ? 'Unit Sale Price (USP e.g., ₹/g or ₹/ml) missing.' : null),
    );
  }

  /// R6_2: Consumer Complaint Details
  static Declaration _checkConsumerCare(String text) {
    final emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
    final phoneRegex = RegExp(r'(?:\+91[-\s]?)?\b[6-9]\d{9}\b|1800[-\s]?\d{2,3}[-\s]?\d{4}');

    final hasEmail = emailRegex.hasMatch(text);
    final hasPhone = phoneRegex.hasMatch(text);

    if (hasEmail || hasPhone) {
      final match = (hasEmail ? emailRegex : phoneRegex).firstMatch(text);
      return Declaration(
        type: 'consumer_care',
        label: 'Consumer Care Contact Details',
        isPresent: true,
        isCompliant: true,
        extractedText: match?.group(0)?.trim(),
        confidenceScore: 0.85,
        ruleReference: 'Rule 6(2)',
      );
    }

    return Declaration(
      type: 'consumer_care',
      label: 'Consumer Care Contact Details',
      isPresent: false,
      isCompliant: false,
      ruleReference: 'Rule 6(2)',
      issue: 'Consumer care contact info (phone/toll-free or email) not detected.',
    );
  }

  /// Rule 6(1)(aa): Country of Origin Declaration
  static Declaration _checkCountryOfOrigin(String text) {
    final originRegex = RegExp(
      r'(?:country\s+of\s+origin|made\s+in|product\s+of)\s*:\s*([A-Za-z\s]+)',
      caseSensitive: false,
    );

    final match = originRegex.firstMatch(text);

    if (match != null) {
      return Declaration(
        type: 'country_of_origin',
        label: 'Country of Origin',
        isPresent: true,
        isCompliant: true,
        extractedText: match.group(0)?.trim(),
        confidenceScore: 0.80,
        ruleReference: 'Rule 6(1)(aa)',
      );
    }

    return Declaration(
      type: 'country_of_origin',
      label: 'Country of Origin',
      isPresent: false,
      isCompliant: false,
      ruleReference: 'Rule 6(1)(aa)',
      issue: 'Country of origin mandatory declaration missing.',
    );
  }
}