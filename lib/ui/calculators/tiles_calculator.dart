import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class TilesCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const TilesCalculator({super.key, required this.onResult});

  @override
  State<TilesCalculator> createState() => _TilesCalculatorState();
}

class _TilesCalculatorState extends State<TilesCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _bathroomCount = TextEditingController(text: "0");
  final _wcCount = TextEditingController(text: "0");
  final _kitchenCount = TextEditingController(text: "0");
  final _floorSqm = TextEditingController(text: "0");
  final _installationSqm = TextEditingController(text: "0");
  final _skirtingMeters = TextEditingController(text: "0");

  // Unit Price Controllers
  final _bathPriceController = TextEditingController(text: "1300.0");
  final _wcPriceController = TextEditingController(text: "1100.0");
  final _kitchenPriceController = TextEditingController(text: "250.0");
  final _tilePriceController = TextEditingController(text: "28.0");
  final _installPriceController = TextEditingController(text: "25.0");
  final _skirtingPriceController = TextEditingController(text: "3.5");
  final _gluePriceController = TextEditingController(text: "16.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_TILES");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "BATH") _bathPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "WC") _wcPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "KITCHEN") _kitchenPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "TILE") _tilePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "INSTALL") _installPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SKIRTING") _skirtingPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "GLUE") _gluePriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_TILES");

    final Map<String, double> prices = {
      "BATH": double.tryParse(_bathPriceController.text) ?? 1300.0,
      "WC": double.tryParse(_wcPriceController.text) ?? 1100.0,
      "KITCHEN": double.tryParse(_kitchenPriceController.text) ?? 250.0,
      "TILE": double.tryParse(_tilePriceController.text) ?? 28.0,
      "INSTALL": double.tryParse(_installPriceController.text) ?? 25.0,
      "SKIRTING": double.tryParse(_skirtingPriceController.text) ?? 3.5,
      "GLUE": double.tryParse(_gluePriceController.text) ?? 16.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_TILES", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_TILES", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bCount = int.tryParse(_bathroomCount.text) ?? 0;
    final wCount = int.tryParse(_wcCount.text) ?? 0;
    final kCount = int.tryParse(_kitchenCount.text) ?? 0;
    final fVal = double.tryParse(_floorSqm.text) ?? 0.0;
    final fiVal = double.tryParse(_installationSqm.text) ?? 0.0;
    final sVal = double.tryParse(_skirtingMeters.text) ?? 0.0;

    final bathPrice = double.tryParse(_bathPriceController.text) ?? 0.0;
    final wcPrice = double.tryParse(_wcPriceController.text) ?? 0.0;
    final kitchenPrice = double.tryParse(_kitchenPriceController.text) ?? 0.0;
    final tilePrice = double.tryParse(_tilePriceController.text) ?? 0.0;
    final installPrice = double.tryParse(_installPriceController.text) ?? 0.0;
    final skirtingPrice = double.tryParse(_skirtingPriceController.text) ?? 0.0;
    final gluePrice = double.tryParse(_gluePriceController.text) ?? 0.0;

    final totalGlue = (bCount * 15) + fiVal.ceil();
    final glueCost = totalGlue * gluePrice;
    final unitPriceTotal = (bCount * bathPrice) + (wCount * wcPrice) + (kCount * kitchenPrice) + (fVal * tilePrice) + (fiVal * installPrice) + (sVal * skirtingPrice) + glueCost;

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
                title: "Τιμές Μονάδας Πλακιδίων",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Μπάνιο (€/τεμ)", _bathPriceController),
                    _priceEditRow("WC (€/τεμ)", _wcPriceController),
                    _priceEditRow("Κουζίνα (€/τεμ)", _kitchenPriceController),
                    _priceEditRow("Αγορά Πλακ. (€/m²)", _tilePriceController),
                    _priceEditRow("Τοποθέτηση (€/m²)", _installPriceController),
                    _priceEditRow("Σοβατεπί (€/m)", _skirtingPriceController),
                    _priceEditRow("Κόλλα (€/σακί)", _gluePriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Τοποθέτηση (τμ / τρέχοντα)",
            icon: Icons.grid_view_rounded,
            child: Column(
              children: [
                TextField(controller: _installationSqm, decoration: InputDecoration(labelText: "Πατώματα m² (${installPrice.toInt()}€/m²)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                TextField(controller: _skirtingMeters, decoration: InputDecoration(labelText: "Σοβατεπί m ($skirtingPrice€/m)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Χώροι (Τεμάχια)",
            icon: Icons.meeting_room_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _bathroomCount, decoration: InputDecoration(labelText: "Μπάνια (${bathPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _wcCount, decoration: InputDecoration(labelText: "WC (${wcPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {}))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _kitchenCount, decoration: InputDecoration(labelText: "Κουζίνα / Καθρέπτης (${kitchenPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Υλικά",
            icon: Icons.inventory_rounded,
            child: Column(
              children: [
                TextField(controller: _floorSqm, decoration: InputDecoration(labelText: "Συνολικά τμ Πλακιδίων ($tilePrice€/τμ)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                if (totalGlue > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text("• Κόλλα Πλακιδίων: $totalGlue σακιά (${glueCost.toStringAsFixed(2)} €)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                  ),
              ],
            ),
          ),
          SturdyResultBanner(total: unitPriceTotal, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: unitPriceTotal > 0 ? () async {
                await _savePrices();
                
                String detailNote = "ΠΕΡΙΛΑΜΒΑΝΟΝΤΑΙ:\n";
                if (bCount > 0) detailNote += "- Τοποθέτηση Πλακιδίων (Μπάνιο): $bCount τεμ.\n";
                if (wCount > 0) detailNote += "- Τοποθέτηση Πλακιδίων (WC): $wCount τεμ.\n";
                if (kCount > 0) detailNote += "- Τοποθέτηση Πλακιδίων (Κουζίνα/Καθρέπτης): $kCount τεμ.\n";
                if (fiVal > 0) detailNote += "- Τοποθέτηση Πλακιδίων (Δάπεδα): ${fiVal.toStringAsFixed(1)} m²\n";
                if (sVal > 0) detailNote += "- Τοποθέτηση Σοβατεπί: ${sVal.toStringAsFixed(1)} m\n";
                if (fVal > 0) detailNote += "- Προμήθεια Πλακιδίων: ${fVal.toStringAsFixed(1)} m²\n";
                if (totalGlue > 0) detailNote += "- Προμήθεια Κόλλας: $totalGlue σακιά\n";

                widget.onResult("Τοποθέτηση & Προμήθεια Πλακιδίων", _multiplierController.text, unitPriceTotal.toStringAsFixed(2), detailNote);
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
