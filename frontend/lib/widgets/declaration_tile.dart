import 'package:flutter/material.dart';
import '../models/declaration.dart';

class DeclarationTile extends StatelessWidget {
  final Declaration declaration;

  const DeclarationTile({super.key, required this.declaration});

  @override
  Widget build(BuildContext context) {
    final iconData = _iconFor(declaration.status);
    final color = _colorFor(declaration.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(iconData, color: color),
        title: Text(declaration.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: declaration.ruleReference != null
            ? Text(declaration.ruleReference!, style: const TextStyle(fontSize: 12))
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (declaration.extractedText != null) ...[
                  const Text('Extracted text:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(declaration.extractedText!),
                  const SizedBox(height: 8),
                ],
                if (declaration.issue != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(child: Text(declaration.issue!, style: const TextStyle(color: Colors.orange))),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (declaration.confidenceScore != null)
                  Text(
                    'Detection confidence: ${(declaration.confidenceScore! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: open manual-correction dialog for officer override
                    },
                    child: const Text('Correct manually'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'compliant':
        return Icons.check_circle;
      case 'non_compliant':
        return Icons.cancel;
      case 'missing':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'compliant':
        return Colors.green;
      case 'non_compliant':
        return Colors.red;
      case 'missing':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
}
