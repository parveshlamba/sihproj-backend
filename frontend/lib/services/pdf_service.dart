import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/scan_result.dart';

class PdfService {
  /// Generates and triggers the native print/save dialog for a compliance audit report.
  static Future exportComplianceReport(ScanResult result) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Report Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Legal Metrology Compliance Audit',
                      style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Scan ID: ${result.scanId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  result.overallStatus.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: result.overallStatus.toLowerCase() == 'compliant'
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Summary Metrics
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Compliant: ${result.compliantCount}', style: const pw.TextStyle(color: PdfColors.green800)),
                  pw.Text('Non-Compliant: ${result.nonCompliantCount}', style: const pw.TextStyle(color: PdfColors.red800)),
                  pw.Text('Missing: ${result.missingCount}', style: const pw.TextStyle(color: PdfColors.orange800)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Declarations Table
            pw.Text('Evaluated Declarations', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            // ignore: deprecated_member_use
            pw.Table.fromTextArray(
              headers: ['Declaration', 'Rule Reference', 'Status', 'Extracted / Finding'],
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
              },
              data: result.declarations.map((d) {
                return [
                  d.label,
                  d.ruleReference ?? 'N/A',
                  d.isCompliant ? 'PASS' : 'FAIL',
                  d.isCompliant ? (d.extractedText ?? 'Present') : (d.issue ?? 'Non-compliant'),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Triggers OS native print preview / save as PDF sheet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Compliance_Report_${result.scanId}.pdf',
    );
  }
}