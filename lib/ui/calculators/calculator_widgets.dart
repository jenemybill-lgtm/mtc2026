import 'package:flutter/material.dart';

class SturdyCalcSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SturdyCalcSection({super.key, required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 8),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class SturdyResultBanner extends StatelessWidget {
  final double total;
  final String label;
  final String quantity;

  const SturdyResultBanner({super.key, required this.total, this.label = "ΣΥΝΟΛΙΚΟ ΚΟΣΤΟΣ", this.quantity = "1"});

  @override
  Widget build(BuildContext context) {
    final q = double.tryParse(quantity) ?? 1.0;
    final grandTotal = total * q;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.85)],
          ),
        ),
        padding: const EdgeInsets.all(28.0),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
              "${grandTotal.toStringAsFixed(2)} €",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32),
            ),
            if (q != 1.0)
              Text(
                "($q x ${total.toStringAsFixed(2)} € ανά μονάδα)",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class QuantityMultiplierField extends StatelessWidget {
  final TextEditingController controller;
  const QuantityMultiplierField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Πλήθος / Ποσότητα (π.χ. 3 Χώροι)",
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: TextInputType.number,
    );
  }
}
