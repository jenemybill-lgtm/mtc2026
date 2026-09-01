import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class BetonCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const BetonCalculator({super.key, required this.onResult});

  @override
  State<BetonCalculator> createState() => _BetonCalculatorState();
}

class _BetonCalculatorState extends State<BetonCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  int _calcMethod = 0; // 0: Analytical, 1: Rough estimate
  
  final _cleanBeton = TextEditingController();
  final _reinforcedBeton = TextEditingController();
  final _stairsQty = TextEditingController();
  final _wallQty = TextEditingController();
  final _ironWeight = TextEditingController();
  final _roughVolume = TextEditingController();

  // Unit Price Controllers
  final _cleanPriceController = TextEditingController(text: "39.0");
  final _reinforcedPriceController = TextEditingController(text: "130.0");
  final _stairsPriceController = TextEditingController(text: "13.0");
  final _wallPriceController = TextEditingController(text: "39.0");
  final _ironPriceController = TextEditingController(text: "0.325");
  final _roughPriceController = TextEditingController(text: "460.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_BETON");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "CLEAN") _cleanPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "REINFORCED") _reinforcedPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "STAIRS") _stairsPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "WALL") _wallPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "IRON") _ironPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "ROUGH") _roughPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_BETON");

    final Map<String, double> prices = {
      "CLEAN": double.tryParse(_cleanPriceController.text) ?? 39.0,
      "REINFORCED": double.tryParse(_reinforcedPriceController.text) ?? 130.0,
      "STAIRS": double.tryParse(_stairsPriceController.text) ?? 13.0,
      "WALL": double.tryParse(_wallPriceController.text) ?? 39.0,
      "IRON": double.tryParse(_ironPriceController.text) ?? 0.325,
      "ROUGH": double.tryParse(_roughPriceController.text) ?? 460.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_BETON", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_BETON", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanPrice = double.tryParse(_cleanPriceController.text) ?? 39.0;
    final reinforcedPrice = double.tryParse(_reinforcedPriceController.text) ?? 130.0;
    final stairsPrice = double.tryParse(_stairsPriceController.text) ?? 13.0;
    final wallPrice = double.tryParse(_wallPriceController.text) ?? 39.0;
    final ironPrice = double.tryParse(_ironPriceController.text) ?? 0.325;
    final roughPrice = double.tryParse(_roughPriceController.text) ?? 460.0;

    double total = 0.0;
    if (_calcMethod == 0) {
      total += (double.tryParse(_cleanBeton.text) ?? 0) * cleanPrice;
      total += (double.tryParse(_reinforcedBeton.text) ?? 0) * reinforcedPrice;
      total += (double.tryParse(_stairsQty.text) ?? 0) * stairsPrice;
      total += (double.tryParse(_wallQty.text) ?? 0) * wallPrice;
      total += (double.tryParse(_ironWeight.text) ?? 0) * ironPrice;
    } else {
      total += (double.tryParse(_roughVolume.text) ?? 0) * roughPrice;
    }

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
                title: "Τιμές Μονάδας Σκυροδέματος",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Καθαριότητας (€/m³)", _cleanPriceController),
                    _priceEditRow("Οπλισμένο (€/m³)", _reinforcedPriceController),
                    _priceEditRow("Σκάλες (€/m³)", _stairsPriceController),
                    _priceEditRow("Στηθαία (€/m)", _wallPriceController),
                    _priceEditRow("Σίδηρος (€/kg)", _ironPriceController),
                    _priceEditRow("Rough (€/m³)", _roughPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: TabBar(
                    onTap: (index) => setState(() => _calcMethod = index),
                    indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.blueGrey,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [Tab(text: "Αναλυτικά"), Tab(text: "Στο Περίπου")],
                  ),
                ),
                const SizedBox(height: 16),
                if (_calcMethod == 0)
                  SturdyCalcSection(
                    title: "Σκυροδέτηση & Υλικά",
                    icon: Icons.warehouse_rounded,
                    child: Column(
                      children: [
                        TextField(controller: _cleanBeton, decoration: InputDecoration(labelText: "Μπετό Καθαριότητας m³ (${cleanPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                        const SizedBox(height: 12),
                        TextField(controller: _reinforcedBeton, decoration: InputDecoration(labelText: "Οπλισμένο Σκυρόδεμα m³ (${reinforcedPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _stairsQty, decoration: InputDecoration(labelText: "Σκάλες m³ (${stairsPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {}))),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _wallQty, decoration: InputDecoration(labelText: "Στηθαία m (${wallPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {}))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: _ironWeight, decoration: InputDecoration(labelText: "Σίδηρος kg ($ironPrice€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                      ],
                    ),
                  )
                else
                  SturdyCalcSection(
                    title: "Γρήγορη Εκτίμηση",
                    icon: Icons.bolt_rounded,
                    child: TextField(controller: _roughVolume, decoration: InputDecoration(labelText: "Συνολικά Κυβικά m³ (${roughPrice.toInt()}€)", border: const OutlineInputBorder()), onChanged: (v) => setState(() {})),
                  ),
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
                
                String detailNote = "ΑΝΑΛΥΣΗ ΣΚΥΡΟΔΕΤΗΣΗΣ:\n";
                if (_calcMethod == 0) {
                  if (_cleanBeton.text.isNotEmpty) detailNote += "- Καθαριότητας: ${_cleanBeton.text} m³\n";
                  if (_reinforcedBeton.text.isNotEmpty) detailNote += "- Οπλισμένο: ${_reinforcedBeton.text} m³\n";
                  if (_stairsQty.text.isNotEmpty) detailNote += "- Σκάλες: ${_stairsQty.text} m³\n";
                  if (_wallQty.text.isNotEmpty) detailNote += "- Στηθαία: ${_wallQty.text} m\n";
                  if (_ironWeight.text.isNotEmpty) detailNote += "- Σίδηρος: ${_ironWeight.text} kg";
                } else {
                  detailNote += "- Εκτίμηση όγκου: ${_roughVolume.text} m³";
                }

                String title = _calcMethod == 0 ? "Εργασίες Σκυροδέτησης (Αναλυτικά)" : "Εργασίες Σκυροδέτησης ( Rough )";
                widget.onResult(title, _multiplierController.text, total.toStringAsFixed(2), detailNote);
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
