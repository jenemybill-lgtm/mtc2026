import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class PlumbingCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const PlumbingCalculator({super.key, required this.onResult});

  @override
  State<PlumbingCalculator> createState() => _PlumbingCalculatorState();
}

class _PlumbingCalculatorState extends State<PlumbingCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  String _roomType = "Μπάνιο";
  bool _hasManifold = false;
  bool _hasBuiltInTank = false;
  final _faucetsController = TextEditingController(text: "0");
  final _radiatorsController = TextEditingController(text: "0");
  bool _hasSolarHeater = false;
  bool _hasElectricHeater = false;

  // Unit Prices Settings
  final _bathBasePriceController = TextEditingController(text: "1100.0");
  final _wcBasePriceController = TextEditingController(text: "800.0");
  final _kitchenBasePriceController = TextEditingController(text: "1000.0");
  final _manifoldPriceController = TextEditingController(text: "200.0");
  final _tankPriceController = TextEditingController(text: "200.0");
  final _faucetPriceController = TextEditingController(text: "100.0");
  final _radiatorPriceController = TextEditingController(text: "50.0");
  final _solarPriceController = TextEditingController(text: "350.0");
  final _electricHeaterPriceController = TextEditingController(text: "250.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_PLUMBING");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "BATH_BASE") _bathBasePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "WC_BASE") _wcBasePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "KITCHEN_BASE") _kitchenBasePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "MANIFOLD") _manifoldPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "TANK") _tankPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "FAUCET") _faucetPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "RADIATOR") _radiatorPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SOLAR") _solarPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "ELECTRIC_HEATER") _electricHeaterPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_PLUMBING");

    final Map<String, double> prices = {
      "BATH_BASE": double.tryParse(_bathBasePriceController.text) ?? 1100.0,
      "WC_BASE": double.tryParse(_wcBasePriceController.text) ?? 800.0,
      "KITCHEN_BASE": double.tryParse(_kitchenBasePriceController.text) ?? 1000.0,
      "MANIFOLD": double.tryParse(_manifoldPriceController.text) ?? 200.0,
      "TANK": double.tryParse(_tankPriceController.text) ?? 200.0,
      "FAUCET": double.tryParse(_faucetPriceController.text) ?? 100.0,
      "RADIATOR": double.tryParse(_radiatorPriceController.text) ?? 50.0,
      "SOLAR": double.tryParse(_solarPriceController.text) ?? 350.0,
      "ELECTRIC_HEATER": double.tryParse(_electricHeaterPriceController.text) ?? 250.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_PLUMBING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_PLUMBING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bathBase = double.tryParse(_bathBasePriceController.text) ?? 0.0;
    final wcBase = double.tryParse(_wcBasePriceController.text) ?? 0.0;
    final kitchenBase = double.tryParse(_kitchenBasePriceController.text) ?? 0.0;
    final manifoldPrice = double.tryParse(_manifoldPriceController.text) ?? 0.0;
    final tankPrice = double.tryParse(_tankPriceController.text) ?? 0.0;
    final faucetPrice = double.tryParse(_faucetPriceController.text) ?? 0.0;
    final radiatorPrice = double.tryParse(_radiatorPriceController.text) ?? 0.0;
    final solarPrice = double.tryParse(_solarPriceController.text) ?? 0.0;
    final electricPrice = double.tryParse(_electricHeaterPriceController.text) ?? 0.0;

    double basePrice = 0.0;
    if (_roomType == "Μπάνιο") basePrice = bathBase;
    else if (_roomType == "WC") basePrice = wcBase;
    else if (_roomType == "Κουζίνα") basePrice = kitchenBase;

    double totalPrice = basePrice;
    if (_roomType == "Μπάνιο" || _roomType == "WC") {
      if (_hasManifold && _roomType == "Μπάνιο") totalPrice += manifoldPrice;
      if (_hasBuiltInTank) totalPrice += tankPrice;
      totalPrice += (int.tryParse(_faucetsController.text) ?? 0) * faucetPrice;
    }
    totalPrice += (int.tryParse(_radiatorsController.text) ?? 0) * radiatorPrice;
    if (_hasSolarHeater) totalPrice += solarPrice;
    if (_hasElectricHeater) totalPrice += electricPrice;

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
                title: "Τιμές Μονάδας Υδραυλικών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Βάση Μπάνιου (€)", _bathBasePriceController),
                    _priceEditRow("Βάση WC (€)", _wcBasePriceController),
                    _priceEditRow("Βάση Κουζίνας (€)", _kitchenBasePriceController),
                    _priceEditRow("Πίνακας Υδρολ. (€)", _manifoldPriceController),
                    _priceEditRow("Καζανάκι Εντ. (€)", _tankPriceController),
                    _priceEditRow("Μπαταρία Εντ. (€)", _faucetPriceController),
                    _priceEditRow("Σώμα Καλοριφέρ (€)", _radiatorPriceController),
                    _priceEditRow("Ηλιακός (€)", _solarPriceController),
                    _priceEditRow("Θερμοσίφωνας (€)", _electricHeaterPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Χώρος Εγκατάστασης",
            icon: Icons.water_drop_rounded,
            child: Row(
              children: ["Μπάνιο", "WC", "Κουζίνα", "Άλλο"].map((type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 10)),
                    selected: _roomType == type,
                    onSelected: (val) => setState(() => _roomType = type),
                  ),
                ),
              )).toList(),
            ),
          ),
          if (_roomType == "Μπάνιο" || _roomType == "WC")
            SturdyCalcSection(
              title: "Επιλογές Μπάνιου",
              icon: Icons.bathtub_rounded,
              child: Column(
                children: [
                  if (_roomType == "Μπάνιο")
                    SwitchListTile(
                      title: Text("Πίνακας Υδροληψίας (+${manifoldPrice.toInt()}€)"),
                      value: _hasManifold,
                      onChanged: (v) => setState(() => _hasManifold = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  SwitchListTile(
                    title: Text("Εντοιχισμένο Καζανάκι (+${tankPrice.toInt()}€)"),
                    value: _hasBuiltInTank,
                    onChanged: (v) => setState(() => _hasBuiltInTank = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _faucetsController,
                    decoration: InputDecoration(labelText: "Εντοιχ. Μπαταρίες (+${faucetPrice.toInt()}€/τεμ)", border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                  ),
                ],
              ),
            ),
          SturdyCalcSection(
            title: "Θέρμανση & Ζεστό Νερό",
            icon: Icons.thermostat_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _radiatorsController,
                  decoration: InputDecoration(labelText: "Σώματα Καλοριφέρ (+${radiatorPrice.toInt()}€/τεμ)", border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                SwitchListTile(
                  title: Text("Ηλιακός Θερμοσίφωνας (+${solarPrice.toInt()}€)"),
                  value: _hasSolarHeater,
                  onChanged: (v) => setState(() => _hasSolarHeater = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text("Ηλεκτρικός Θερμοσίφωνας (+${electricPrice.toInt()}€)"),
                  value: _hasElectricHeater,
                  onChanged: (v) => setState(() => _hasElectricHeater = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SturdyResultBanner(total: totalPrice, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: totalPrice > 0 ? () async {
                await _savePrices();
                
                String detailNote = "ΑΝΑΛΥΣΗ ΥΔΡΑΥΛΙΚΩΝ ($_roomType):\n";
                if (_roomType == "Μπάνιο" || _roomType == "WC") {
                  if (_hasManifold) detailNote += "- Πίνακας Υδροληψίας\n";
                  if (_hasBuiltInTank) detailNote += "- Εντοιχισμένο Καζανάκι\n";
                  if (_faucetsController.text != "0") detailNote += "- Εντοιχ. Μπαταρίες: ${_faucetsController.text} τεμ\n";
                }
                if (_radiatorsController.text != "0") detailNote += "- Σώματα Καλοριφέρ: ${_radiatorsController.text} τεμ\n";
                if (_hasSolarHeater) detailNote += "- Ηλιακός Θερμοσίφωνας\n";
                if (_hasElectricHeater) detailNote += "- Ηλεκτρικός Θερμοσίφωνας";

                widget.onResult("Υδραυλική Εγκατάσταση ($_roomType)", _multiplierController.text, totalPrice.toStringAsFixed(2), detailNote);
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
