import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class DrywallCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const DrywallCalculator({super.key, required this.onResult});

  @override
  State<DrywallCalculator> createState() => _DrywallCalculatorState();
}

class _DrywallCalculatorState extends State<DrywallCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _areaController = TextEditingController();
  final _priceController = TextEditingController(text: "25");

  // Units prices settings
  final Map<String, TextEditingController> _priceControllers = {};
  final List<String> _types = ["Ταβάνι", "Επένδυση Μονή", "Επένδυση Διπλή", "Χώρισμα Μονό", "Χώρισμα Διπλό", "Κούτελο/Σκοτία"];
  
  late String _selectedType;
  bool _hasInsulation = false;
  bool _showPriceSettings = false;
  final _insulationPriceController = TextEditingController(text: "6.0");

  @override
  void initState() {
    super.initState();
    _selectedType = _types.first;
    for (var type in _types) {
      double initial = 25.0;
      if (type == "Ταβάνι") initial = 28.0;
      if (type == "Επένδυση Μονή") initial = 24.0;
      if (type == "Επένδυση Διπλή") initial = 32.0;
      if (type == "Χώρισμα Μονό") initial = 35.0;
      if (type == "Χώρισμα Διπλό") initial = 45.0;
      if (type == "Κούτελο/Σκοτία") initial = 15.0;
      _priceControllers[type] = TextEditingController(text: initial.toString());
    }
    _loadStoredPrices();
    _updateDisplayPrice();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_DRYWALL");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "INSULATION") _insulationPriceController.text = p.defaultUnitPrice.toString();
          if (_priceControllers.containsKey(p.description)) {
            _priceControllers[p.description]!.text = p.defaultUnitPrice.toString();
          }
        }
        _updateDisplayPrice();
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_DRYWALL");

    for (var type in _types) {
      final price = double.tryParse(_priceControllers[type]!.text) ?? 0.0;
      await _upsertPrice(provider, stored, type, price);
    }
    await _upsertPrice(provider, stored, "INSULATION", double.tryParse(_insulationPriceController.text) ?? 6.0);
  }

  Future<void> _upsertPrice(ProjectProvider provider, List<GlobalPriceEntity> stored, String desc, double value) async {
    final existing = stored.firstWhereOrNull((p) => p.description == desc);
    if (existing != null) {
      await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_DRYWALL", description: desc, unit: "€", defaultUnitPrice: value));
    } else {
      await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_DRYWALL", description: desc, unit: "€", defaultUnitPrice: value));
    }
  }

  void _updateDisplayPrice() {
    double price = double.tryParse(_priceControllers[_selectedType]?.text ?? "25") ?? 25.0;
    if (_hasInsulation) price += double.tryParse(_insulationPriceController.text) ?? 6.0;
    _priceController.text = price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final areaVal = double.tryParse(_areaController.text) ?? 0.0;
    final unitPrice = double.tryParse(_priceController.text) ?? 0.0;
    final totalTotal = areaVal * unitPrice;

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
                title: "Τιμές Μονάδας Κατασκευών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    ..._types.map((t) => _priceEditRow(t, _priceControllers[t]!)),
                    _priceEditRow("Μόνωση (€/m²)", _insulationPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Τύπος Κατασκευής",
            icon: Icons.layers_rounded,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val!;
                      _updateDisplayPrice();
                    });
                  },
                  decoration: const InputDecoration(labelText: "Επιλογή Κατασκευής"),
                ),
                SwitchListTile(
                  title: const Text("Περιλαμβάνει Μόνωση;", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  value: _hasInsulation,
                  onChanged: (val) {
                    setState(() {
                      _hasInsulation = val;
                      _updateDisplayPrice();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Μετρήσεις & Τιμολόγηση",
            icon: Icons.architecture_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _areaController,
                  decoration: InputDecoration(labelText: _selectedType == "Κούτελο/Σκοτία" ? "Τρέχοντα Μέτρα (m)" : "Επιφάνεια m²", border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Τελική Τιμή / m² (€)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),
          ),
          SturdyResultBanner(total: totalTotal, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: areaVal > 0 ? () async {
                await _savePrices();
                
                String detailNote = "ΑΝΑΛΥΣΗ ΓΥΨΟΣΑΝΙΔΑΣ:\n";
                detailNote += "- Τύπος: $_selectedType\n";
                detailNote += "- Ποσότητα: $areaVal " + (_selectedType == "Κούτελο/Σκοτία" ? "m" : "m²") + "\n";
                detailNote += "- Μόνωση: ${_hasInsulation ? "Ναι" : "Όχι"}";

                widget.onResult("$_selectedType (Γυψοσανίδα)", _multiplierController.text, unitPrice.toStringAsFixed(2), detailNote);
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
              onChanged: (v) => setState(() => _updateDisplayPrice()),
            )
          ),
        ],
      ),
    );
  }
}
