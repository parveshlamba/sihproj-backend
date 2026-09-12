import 'package:flutter/material.dart';

class ComplianceBadge extends StatelessWidget {
  final String status; // "compliant" | "non_compliant"

  const ComplianceBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isCompliant = status == 'compliant';
    final color = isCompliant ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        isCompliant ? 'COMPLIANT' : 'NON-COMPLIANT',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
