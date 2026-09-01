import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class ElectricalCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const ElectricalCalculator({super.key, required this.onResult});

  @override
  State<ElectricalCalculator> createState() => _ElectricalCalculatorState();
}

class _ElectricalCalculatorState extends State<ElectricalCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _areaController = TextEditingController();
  final _spotsController = TextEditingController(text: "0");
  final _fixturesController = TextEditingController(text: "0");
  final _ledsController = TextEditingController(text: "0");
  final _socketsController = TextEditingController(text: "0");
  
  bool _hasPanel = false;
  bool _hasNewSupply = false;

  // Unit Price Controllers
  final _areaPriceController = TextEditingController(text: "65.0");
  final _spotPriceController = TextEditingController(text: "30.0");
  final _panelPriceController = TextEditingController(text: "400.0");
  final _supplyPriceController = TextEditingController(text: "3000.0");
  final _fixturePriceController = TextEditingController(text: "30.0");
  final _ledPriceController = TextEditingController(text: "35.0");
  final _socketPriceController = TextEditingController(text: "15.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_ELECTRICAL");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "AREA") _areaPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SPOT") _spotPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "PANEL") _panelPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SUPPLY") _supplyPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "FIXTURE") _fixturePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "LED") _ledPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SOCKET") _socketPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_ELECTRICAL");

    final Map<String, double> prices = {
      "AREA": double.tryParse(_areaPriceController.text) ?? 65.0,
      "SPOT": double.tryParse(_spotPriceController.text) ?? 30.0,
      "PANEL": double.tryParse(_panelPriceController.text) ?? 400.0,
      "SUPPLY": double.tryParse(_supplyPriceController.text) ?? 3000.0,
      "FIXTURE": double.tryParse(_fixturePriceController.text) ?? 30.0,
      "LED": double.tryParse(_ledPriceController.text) ?? 35.0,
      "SOCKET": double.tryParse(_socketPriceController.text) ?? 15.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_ELECTRICAL", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_ELECTRICAL", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaVal = double.tryParse(_areaController.text) ?? 0.0;
    final spots = int.tryParse(_spotsController.text) ?? 0;
    final fixtures = int.tryParse(_fixturesController.text) ?? 0;
    final leds = double.tryParse(_ledsController.text) ?? 0.0;
    final sockets = int.tryParse(_socketsController.text) ?? 0;

    final areaPrice = double.tryParse(_areaPriceController.text) ?? 0.0;
    final spotPrice = double.tryParse(_spotPriceController.text) ?? 0.0;
    final panelPrice = double.tryParse(_panelPriceController.text) ?? 0.0;
    final supplyPrice = double.tryParse(_supplyPriceController.text) ?? 0.0;
    final fixturePrice = double.tryParse(_fixturePriceController.text) ?? 0.0;
    final ledPrice = double.tryParse(_ledPriceController.text) ?? 0.0;
    final socketPrice = double.tryParse(_socketPriceController.text) ?? 0.0;

    double total = 0.0;
    total += areaVal * areaPrice;
    total += spots * spotPrice;
    if (_hasPanel) total += panelPrice;
    if (_hasNewSupply) total += supplyPrice;
    total += fixtures * fixturePrice;
    total += leds * ledPrice;
    total += sockets * socketPrice;

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
                title: "Τιμές Μονάδας Ηλεκτρολογικών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Εγκατάσταση (€/m²)", _areaPriceController),
                    _priceEditRow("Σποτάκια (€/τεμ)", _spotPriceController),
                    _priceEditRow("Πίνακας (€)", _panelPriceController),
                    _priceEditRow("Νέα Παροχή (€)", _supplyPriceController),
                    _priceEditRow("Φωτιστικά (€/τεμ)", _fixturePriceController),
                    _priceEditRow("LED (€/m)", _ledPriceController),
                    _priceEditRow("Πρίζες (€/τεμ)", _socketPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Βασική Εγκατάσταση",
            icon: Icons.electrical_services_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _areaController,
                  decoration: InputDecoration(labelText: "Εμβαδόν Εγκατάστασης m² (${areaPrice.toInt()}€/m²)", border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                SwitchListTile(
                  title: Text("Ηλεκτρολογικός Πίνακας (+${panelPrice.toInt()}€)"),
                  value: _hasPanel,
                  onChanged: (v) => setState(() => _hasPanel = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text("Νέα Παροχή (+${supplyPrice.toInt()}€)"),
                  value: _hasNewSupply,
                  onChanged: (v) => setState(() => _hasNewSupply = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Φωτισμός & Διακόπτες",
            icon: Icons.lightbulb_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _spotsController, decoration: InputDecoration(labelText: "Σποτάκια (${spotPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _fixturesController, decoration: InputDecoration(labelText: "Φωτιστικά (${fixturePrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ledsController, decoration: InputDecoration(labelText: "LED m (${ledPrice.toInt()}€/m)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _socketsController, decoration: InputDecoration(labelText: "Πρίζες (${socketPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                  ],
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
                
                String detailNote = "ΑΝΑΛΥΣΗ ΗΛΕΚΤΡΟΛΟΓΙΚΩΝ:\n";
                detailNote += "- Βασική εγκατάσταση: ${areaVal} m²\n";
                if (_hasPanel) detailNote += "- Ηλεκτρολογικός Πίνακας\n";
                if (_hasNewSupply) detailNote += "- Νέα Παροχή\n";
                if (_spotsController.text != "0") detailNote += "- Σποτάκια: ${_spotsController.text} τεμ\n";
                if (_fixturesController.text != "0") detailNote += "- Φωτιστικά: ${_fixturesController.text} τεμ\n";
                if (_ledsController.text != "0") detailNote += "- LED: ${_ledsController.text} m\n";
                if (_socketsController.text != "0") detailNote += "- Πρίζες: ${_socketsController.text} τεμ";

                widget.onResult("Ηλεκτρολογική Εγκατάσταση", _multiplierController.text, total.toStringAsFixed(2), detailNote);
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
