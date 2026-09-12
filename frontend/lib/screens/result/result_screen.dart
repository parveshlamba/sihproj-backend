import 'package:flutter/material.dart';
import 'package:legal_metrology_app/services/pdf_service.dart';
import '../../models/scan_result.dart';
import '../../widgets/declaration_tile.dart';
import '../../widgets/compliance_badge.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ResultScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImagePreview(),
          const SizedBox(height: 16),
          _buildSummaryCard(context),
          const SizedBox(height: 20),
          const Text('Declarations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...scanResult.declarations.map((d) => DeclarationTile(declaration: d)),
          if (scanResult.rawOcrText != null) ...[
            const SizedBox(height: 16),
            _buildRawTextSection(),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    Widget imageWidget;
    if (scanResult.productImageBytes != null) {
      // Image.memory works identically on web, Android, iOS and desktop.
      imageWidget = Image.memory(
        scanResult.productImageBytes!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (scanResult.productImageUrl != null) {
      imageWidget = Image.network(
        scanResult.productImageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        height: 160,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanResult.productName ?? 'Scanned Product',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Scan ID: ${scanResult.scanId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '${scanResult.compliantCount} compliant · ${scanResult.nonCompliantCount} non-compliant · ${scanResult.missingCount} missing',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            ComplianceBadge(status: scanResult.overallStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildRawTextSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.text_snippet_outlined),
        title: const Text('Raw extracted text'),
        subtitle: const Text('What the OCR engine actually read from the label', style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(scanResult.rawOcrText!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              // Show a quick visual indicator while generating the document
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating PDF Report...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                await PdfService.exportComplianceReport(scanResult);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to generate PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Report'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Persist scan result and navigate back home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan saved successfully!'),
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save & Finish'),
          ),
        ),
      ],
    );
  }
}