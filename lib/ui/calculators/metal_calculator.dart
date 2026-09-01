import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class MetalCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const MetalCalculator({super.key, required this.onResult});

  @override
  State<MetalCalculator> createState() => _MetalCalculatorState();
}

class _MetalCalculatorState extends State<MetalCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _steelWeight = TextEditingController();
  final _sheetMetalCount = TextEditingController();

  // Unit Price Controllers
  final _steelPriceController = TextEditingController(text: "5000.0");
  final _sheetPriceController = TextEditingController(text: "10000.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_METAL");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "STEEL") _steelPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SHEET") _sheetPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_METAL");

    final Map<String, double> prices = {
      "STEEL": double.tryParse(_steelPriceController.text) ?? 5000.0,
      "SHEET": double.tryParse(_sheetPriceController.text) ?? 10000.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_METAL", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_METAL", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sW = double.tryParse(_steelWeight.text) ?? 0.0;
    final sM = double.tryParse(_sheetMetalCount.text) ?? 0.0;
    
    final steelPrice = double.tryParse(_steelPriceController.text) ?? 5000.0;
    final sheetPrice = double.tryParse(_sheetPriceController.text) ?? 10000.0;

    final total = (sW * steelPrice) + (sM * sheetPrice);

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
                title: "Τιμές Μονάδας Μετάλλων",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Χάλυβας (€/Τόνο)", _steelPriceController),
                    _priceEditRow("Λαμαρίνα (€/Τεμ)", _sheetPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Στοιχεία Κατασκευής",
            icon: Icons.construction_rounded,
            child: Column(
              children: [
                TextField(controller: _steelWeight, decoration: InputDecoration(labelText: "Χάλυβας Τόνοι (${steelPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                const SizedBox(height: 12),
                TextField(controller: _sheetMetalCount, decoration: InputDecoration(labelText: "Λαμαρίνα Πλάκας Τεμ (${sheetPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
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
                
                String detailNote = "ΑΝΑΛΥΣΗ ΜΕΤΑΛΛΙΚΩΝ:\n";
                if (sW > 0) detailNote += "- Χάλυβας: ${sW.toStringAsFixed(2)} t\n";
                if (sM > 0) detailNote += "- Λαμαρίνα: ${sM.toInt()} τεμ";

                widget.onResult("Μεταλλικός Σκελετός", _multiplierController.text, total.toStringAsFixed(2), detailNote);
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
