import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class EngineeringCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const EngineeringCalculator({super.key, required this.onResult});

  @override
  State<EngineeringCalculator> createState() => _EngineeringCalculatorState();
}

class _EngineeringCalculatorState extends State<EngineeringCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _studyCost = TextEditingController();
  final _supervisionCost = TextEditingController();
  final _managementCost = TextEditingController();
  final _permitsCost = TextEditingController();

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_ENGINEERING");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "STUDY") _studyCost.text = p.defaultUnitPrice.toString();
          if (p.description == "SUPERVISION") _supervisionCost.text = p.defaultUnitPrice.toString();
          if (p.description == "MANAGEMENT") _managementCost.text = p.defaultUnitPrice.toString();
          if (p.description == "PERMITS") _permitsCost.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_ENGINEERING");

    final Map<String, double> prices = {
      "STUDY": double.tryParse(_studyCost.text) ?? 0.0,
      "SUPERVISION": double.tryParse(_supervisionCost.text) ?? 0.0,
      "MANAGEMENT": double.tryParse(_managementCost.text) ?? 0.0,
      "PERMITS": double.tryParse(_permitsCost.text) ?? 0.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_ENGINEERING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_ENGINEERING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sC = double.tryParse(_studyCost.text) ?? 0.0;
    final svC = double.tryParse(_supervisionCost.text) ?? 0.0;
    final mC = double.tryParse(_managementCost.text) ?? 0.0;
    final pC = double.tryParse(_permitsCost.text) ?? 0.0;

    final total = sC + svC + mC + pC;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: QuantityMultiplierField(controller: _multiplierController)),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => setState(() => _showPriceSettings = !_showPriceSettings),
                icon: Icon(_showPriceSettings ? Icons.settings_applications : Icons.settings_outlined),
                tooltip: "Αποθήκευση ως Προεπιλογή",
              ),
            ],
          ),

          if (_showPriceSettings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: const Text("Οι παρακάτω τιμές θα αποθηκευτούν ως προεπιλογές για μελλοντικούς υπολογισμούς.", 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
            ),

          SturdyCalcSection(
            title: "Υπηρεσίες Μηχανικού",
            icon: Icons.design_services_rounded,
            child: Column(
              children: [
                TextField(controller: _studyCost, decoration: const InputDecoration(labelText: "Μελέτη / Σχεδιασμός (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                TextField(controller: _supervisionCost, decoration: const InputDecoration(labelText: "Επίβλεψη Εργασιών (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                TextField(controller: _managementCost, decoration: const InputDecoration(labelText: "Κατασκευή / Διαχείριση (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                TextField(controller: _permitsCost, decoration: const InputDecoration(labelText: "Άδειες / Παράβολα (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
              ],
            ),
          ),
          SturdyResultBanner(total: total, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: total > 0 ? () async {
                await _savePrices();
                
                String detailNote = "ΑΝΑΛΥΣΗ ΥΠΗΡΕΣΙΩΝ:\n";
                if (sC > 0) detailNote += "- Μελέτη: ${sC.toStringAsFixed(2)} €\n";
                if (svC > 0) detailNote += "- Επίβλεψη: ${svC.toStringAsFixed(2)} €\n";
                if (mC > 0) detailNote += "- Διαχείριση: ${mC.toStringAsFixed(2)} €\n";
                if (pC > 0) detailNote += "- Άδειες: ${pC.toStringAsFixed(2)} €";

                widget.onResult("Μελέτες & Επιβλέψεις", _multiplierController.text, total.toStringAsFixed(2), detailNote);
                Navigator.pop(context);
              } : null,
              child: const Text("ΜΕΤΑΦΟΡΑ ΣΤΗΝ ΠΡΟΣΦΟΡΑ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
