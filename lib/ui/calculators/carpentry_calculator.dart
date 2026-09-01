import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class CarpentryCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const CarpentryCalculator({super.key, required this.onResult});

  @override
  State<CarpentryCalculator> createState() => _CarpentryCalculatorState();
}

class _CarpentryCalculatorState extends State<CarpentryCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _kitchenMeters = TextEditingController();
  final _kitchenRate = TextEditingController(text: "450");
  
  final _customName = TextEditingController();
  final _customQty = TextEditingController();
  final _customPrice = TextEditingController();

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_CARPENTRY");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "KITCHEN_RATE") _kitchenRate.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_CARPENTRY");

    final rate = double.tryParse(_kitchenRate.text) ?? 450.0;
    final existing = stored.firstWhereOrNull((p) => p.description == "KITCHEN_RATE");

    if (existing != null) {
      await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_CARPENTRY", description: "KITCHEN_RATE", unit: "m", defaultUnitPrice: rate));
    } else {
      await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_CARPENTRY", description: "KITCHEN_RATE", unit: "m", defaultUnitPrice: rate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final km = double.tryParse(_kitchenMeters.text) ?? 0.0;
    final kr = double.tryParse(_kitchenRate.text) ?? 450.0;
    final cq = double.tryParse(_customQty.text) ?? 0.0;
    final cp = double.tryParse(_customPrice.text) ?? 0.0;

    final unitCost = (km * kr) + (cq * cp);

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
              ),
            ],
          ),

          if (_showPriceSettings)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SturdyCalcSection(
                title: "Τιμές Μονάδας Ξυλουργικών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Τιμή Κουζίνας (€/m)", _kitchenRate),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Κουζίνα",
            icon: Icons.kitchen_rounded,
            child: Column(
              children: [
                TextField(controller: _kitchenMeters, decoration: InputDecoration(labelText: "Τρέχοντα Μέτρα m (${kr.toInt()}€/m)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Πρόσθετα / Custom",
            icon: Icons.add_rounded,
            child: Column(
              children: [
                TextField(controller: _customName, decoration: const InputDecoration(labelText: "Όνομα Κατασκευής", border: OutlineInputBorder()), onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _customQty, decoration: const InputDecoration(labelText: "Ποσότητα", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _customPrice, decoration: const InputDecoration(labelText: "Τιμή Μονάδος (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                  ],
                ),
              ],
            ),
          ),
          SturdyResultBanner(total: unitCost, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: unitCost > 0 ? () async {
                await _savePrices();
                
                String detailNote = "ΑΝΑΛΥΣΗ ΞΥΛΟΥΡΓΙΚΩΝ:\n";
                if (km > 0) detailNote += "- Κουζίνα: ${km} m\n";
                if (_customName.text.isNotEmpty) {
                  detailNote += "- ${_customName.text}: ${cq.toInt()} τεμ";
                }

                widget.onResult("Ξυλουργικές Εργασίες", _multiplierController.text, unitCost.toStringAsFixed(2), detailNote);
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

  Widget _priceEditRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 2, 
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), isDense: true, border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
            )
          ),
        ],
      ),
    );
  }
}
