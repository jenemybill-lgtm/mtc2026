import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class MortarCalculator extends StatefulWidget {
  final String category;
  final Function(String, String, String, String) onResult;

  const MortarCalculator({super.key, required this.category, required this.onResult});

  @override
  State<MortarCalculator> createState() => _MortarCalculatorState();
}

class _MortarCalculatorState extends State<MortarCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _areaController = TextEditingController();
  final _thicknessController = TextEditingController(text: "0.05");
  final _laborPriceController = TextEditingController(text: "15.0");

  // Material Price Controllers
  final _sandPriceM3Controller = TextEditingController(text: "35.0");
  final _sandPriceBagController = TextEditingController(text: "1.0");
  
  final _marblePriceM3Controller = TextEditingController(text: "76.25");
  final _marblePriceBagController = TextEditingController(text: "2.5");

  final _cementPriceController = TextEditingController(text: "7.0");
  
  final _limePriceBagController = TextEditingController(text: "5.0");
  final _limePriceM2Controller = TextEditingController(text: "2.0");

  final _gluePriceController = TextEditingController(text: "12.0");

  // Unit Choice
  String _sandUnit = "m³";
  String _marbleUnit = "m³";
  String _limeUnit = "σακί";

  late List<String> _availableTypes;
  late String _selectedType;
  bool _hasMarbleLayer = false;
  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _availableTypes = (widget.category == "TILES" || widget.category == "BATHROOM")
        ? ["Κόλλα Πλακιδίων"]
        : ["Τσιμεντοκονία", "Σοβάς"];
    _selectedType = _availableTypes.first;
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_MORTAR");
    
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "SAND_M3") _sandPriceM3Controller.text = p.defaultUnitPrice.toString();
          if (p.description == "SAND_BAG") _sandPriceBagController.text = p.defaultUnitPrice.toString();
          
          if (p.description == "MARBLE_M3") _marblePriceM3Controller.text = p.defaultUnitPrice.toString();
          if (p.description == "MARBLE_BAG") _marblePriceBagController.text = p.defaultUnitPrice.toString();
          
          if (p.description == "CEMENT") _cementPriceController.text = p.defaultUnitPrice.toString();
          
          if (p.description == "LIME_BAG") _limePriceBagController.text = p.defaultUnitPrice.toString();
          if (p.description == "LIME_M2") _limePriceM2Controller.text = p.defaultUnitPrice.toString();
          
          if (p.description == "GLUE") _gluePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "LABOR") _laborPriceController.text = p.defaultUnitPrice.toString();
          
          if (p.description == "SAND_ACTIVE_UNIT") _sandUnit = p.unit;
          if (p.description == "MARBLE_ACTIVE_UNIT") _marbleUnit = p.unit;
          if (p.description == "LIME_ACTIVE_UNIT") _limeUnit = p.unit;
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_MORTAR");
    
    final Map<String, dynamic> data = {
      "SAND_M3": {"val": double.tryParse(_sandPriceM3Controller.text) ?? 35.0, "unit": "€"},
      "SAND_BAG": {"val": double.tryParse(_sandPriceBagController.text) ?? 1.0, "unit": "€"},
      "MARBLE_M3": {"val": double.tryParse(_marblePriceM3Controller.text) ?? 76.25, "unit": "€"},
      "MARBLE_BAG": {"val": double.tryParse(_marblePriceBagController.text) ?? 2.5, "unit": "€"},
      "CEMENT": {"val": double.tryParse(_cementPriceController.text) ?? 7.0, "unit": "€"},
      "LIME_BAG": {"val": double.tryParse(_limePriceBagController.text) ?? 5.0, "unit": "€"},
      "LIME_M2": {"val": double.tryParse(_limePriceM2Controller.text) ?? 2.0, "unit": "€"},
      "GLUE": {"val": double.tryParse(_gluePriceController.text) ?? 12.0, "unit": "€"},
      "LABOR": {"val": double.tryParse(_laborPriceController.text) ?? 15.0, "unit": "€"},
      "SAND_ACTIVE_UNIT": {"val": 0.0, "unit": _sandUnit},
      "MARBLE_ACTIVE_UNIT": {"val": 0.0, "unit": _marbleUnit},
      "LIME_ACTIVE_UNIT": {"val": 0.0, "unit": _limeUnit},
    };

    for (var entry in data.entries) {
      final existing = stored.where((p) => p.description == entry.key).firstOrNull;
      final entity = GlobalPriceEntity(
        id: existing?.id ?? 0,
        category: "CALC_MORTAR",
        description: entry.key,
        unit: entry.value["unit"],
        defaultUnitPrice: entry.value["val"],
      );
      if (existing != null) {
        await provider.updateGlobalPrice(entity);
      } else {
        await provider.addGlobalPrice(entity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaVal = double.tryParse(_areaController.text) ?? 0.0;
    final thickVal = double.tryParse(_thicknessController.text) ?? 0.0;
    final laborPerSqm = double.tryParse(_laborPriceController.text) ?? 0.0;
    
    final sandPrice = _sandUnit == "m³" 
        ? (double.tryParse(_sandPriceM3Controller.text) ?? 0.0) 
        : (double.tryParse(_sandPriceBagController.text) ?? 0.0);
    final marblePrice = _marbleUnit == "m³" 
        ? (double.tryParse(_marblePriceM3Controller.text) ?? 0.0) 
        : (double.tryParse(_marblePriceBagController.text) ?? 0.0);
    final cementPrice = double.tryParse(_cementPriceController.text) ?? 0.0;
    final limePrice = _limeUnit == "σακί" 
        ? (double.tryParse(_limePriceBagController.text) ?? 0.0) 
        : (double.tryParse(_limePriceM2Controller.text) ?? 0.0);
    final gluePrice = double.tryParse(_gluePriceController.text) ?? 0.0;

    final volume = areaVal * thickVal;

    double sandQtyM3 = 0.0;
    int cementQty = 0;
    int limeQty = 0;
    int glueQty = 0;
    double marbleDustQtyM3 = 0.0;

    if (_selectedType == "Τσιμεντοκονία") {
      sandQtyM3 = volume * 1.2; // 1.2m3 sand per m3 of floor
      cementQty = (volume * 14).round(); // ~350kg cement
    } else if (_selectedType == "Σοβάς") {
      // Average plaster (throwing + base layer)
      sandQtyM3 = volume * 1.1; 
      cementQty = (volume * 12).round();
      limeQty = (volume * 10).round();
      
      if (_hasMarbleLayer) {
        final marbleVolume = areaVal * 0.01; // 1cm marble layer
        marbleDustQtyM3 = marbleVolume * 1.2;
        cementQty += (marbleVolume * 8).round();
        limeQty += (marbleVolume * 15).round();
      }
    } else if (_selectedType == "Κόλλα Πλακιδίων") {
      glueQty = (areaVal / 5).ceil(); // 1 bag per 5sqm roughly
    }

    final sandQtyBags = sandQtyM3 * 80.0; // 80 bags per m3
    final marbleDustQtyBags = marbleDustQtyM3 * 80.0;

    final sandCost = _sandUnit == "m³" ? (sandQtyM3 * sandPrice) : (sandQtyBags * sandPrice);
    final marbleDustCost = _marbleUnit == "m³" ? (marbleDustQtyM3 * marblePrice) : (marbleDustQtyBags * marblePrice);
    
    // For Lime, if unit is m2, we multiply price by area. If unit is bag, we use calculated bags.
    final limeCost = _limeUnit == "σακί" ? (limeQty * limePrice) : (areaVal * limePrice);
    
    final cementCost = cementQty * cementPrice;
    final glueCost = glueQty * gluePrice;

    final totalMaterialCost = sandCost + marbleDustCost + limeCost + cementCost + glueCost;
    final totalLaborCost = areaVal * laborPerSqm;
    final grandTotal = totalMaterialCost + totalLaborCost;

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
                tooltip: "Ρύθμιση Τιμών Υλικών",
              ),
            ],
          ),
          
          if (_showPriceSettings)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SturdyCalcSection(
                title: "Τιμές Μονάδας Υλικών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _dualPriceEditRow(
                      label: "Άμμος",
                      unit1: "m³",
                      ctrl1: _sandPriceM3Controller,
                      unit2: "σακί",
                      ctrl2: _sandPriceBagController,
                      activeUnit: _sandUnit,
                      onUnitSwitch: (u) => setState(() => _sandUnit = u),
                    ),
                    _dualPriceEditRow(
                      label: "Μαρμαρόσκ.",
                      unit1: "m³",
                      ctrl1: _marblePriceM3Controller,
                      unit2: "σακί",
                      ctrl2: _marblePriceBagController,
                      activeUnit: _marbleUnit,
                      onUnitSwitch: (u) => setState(() => _marbleUnit = u),
                    ),
                    _priceEditRow("Τσιμέντο (€/σακί)", _cementPriceController),
                    _dualPriceEditRow(
                      label: "Ασβέστης",
                      unit1: "σακί",
                      ctrl1: _limePriceBagController,
                      unit2: "m²",
                      ctrl2: _limePriceM2Controller,
                      activeUnit: _limeUnit,
                      onUnitSwitch: (u) => setState(() => _limeUnit = u),
                    ),
                    _priceEditRow("Κόλλα (€/σακί)", _gluePriceController),
                    const SizedBox(height: 8),
                    const Text("Εισάγετε τιμές και για τις δύο μονάδες. Η επιλεγμένη μονάδα (highlight) χρησιμοποιείται στον υπολογισμό.", 
                      style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Τύπος & Επιλογές",
            icon: Icons.category_rounded,
            child: Column(
              children: [
                Row(
                  children: _availableTypes.map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        selected: _selectedType == type,
                        onSelected: (val) => setState(() => _selectedType = type),
                      ),
                    ),
                  )).toList(),
                ),
                if (_selectedType == "Σοβάς")
                  SwitchListTile(
                    title: const Text("Προσθήκη Μαρμαρώματος (Τελική Στρώση)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: _hasMarbleLayer,
                    onChanged: (val) => setState(() => _hasMarbleLayer = val),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Διαστάσεις & Εργατικά",
            icon: Icons.square_foot_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaController,
                        decoration: const InputDecoration(labelText: "Εμβαδόν m²", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    if (_selectedType != "Κόλλα Πλακιδίων") ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _thicknessController,
                          decoration: const InputDecoration(labelText: "Πάχος m", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _laborPriceController,
                  decoration: const InputDecoration(
                    labelText: "Εργατικά ανά m² (€)", 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.engineering_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),
          ),
          if (areaVal > 0)
            SturdyCalcSection(
              title: "Ανάλυση Υλικών",
              icon: Icons.inventory_2_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sandQtyM3 > 0) 
                    _matRow("Άμμος", "${sandQtyM3.toStringAsFixed(2)} m³", 
                      _sandUnit == "m³" 
                        ? "${sandCost.toStringAsFixed(2)} € (~${sandQtyBags.toStringAsFixed(0)} σακιά)"
                        : "${sandCost.toStringAsFixed(2)} € (${sandQtyBags.toStringAsFixed(0)} σακιά)"
                    ),
                  if (marbleDustQtyM3 > 0) 
                    _matRow("Μαρμαρόσκονη", "${marbleDustQtyM3.toStringAsFixed(2)} m³", 
                      _marbleUnit == "m³"
                        ? "${marbleDustCost.toStringAsFixed(2)} € (~${marbleDustQtyBags.toStringAsFixed(0)} σακιά)"
                        : "${marbleDustCost.toStringAsFixed(2)} € (${marbleDustQtyBags.toStringAsFixed(0)} σακιά)"
                    ),
                  if (cementQty > 0) 
                    _matRow("Τσιμέντα", "$cementQty σακιά", "${(cementQty * cementPrice).toStringAsFixed(2)} €"),
                  if (limeQty > 0) 
                    _matRow("Ασβέστης", _limeUnit == "σακί" ? "$limeQty σακιά" : "${areaVal.toStringAsFixed(0)} m²", "${limeCost.toStringAsFixed(2)} €"),
                  if (glueQty > 0) 
                    _matRow("Κόλλα", "$glueQty σακιά", "${(glueQty * gluePrice).toStringAsFixed(2)} €"),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ΣΥΝΟΛΟ ΕΡΓΑΤΙΚΩΝ:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("${totalLaborCost.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          SturdyResultBanner(total: grandTotal, quantity: _multiplierController.text),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              onPressed: areaVal > 0 ? () async {
                final q = _multiplierController.text;
                // Save prices before returning
                await _savePrices();
                
                // Construct a detailed human-readable note
                String detailNote = "Επιφάνεια: ${areaVal}m²";
                if (_selectedType != "Κόλλα Πλακιδίων") detailNote += " • Πάχος: ${thickVal}m";
                detailNote += "\nΥΛΙΚΑ:";
                
                if (sandQtyM3 > 0) {
                  detailNote += "\n- Άμμος: " + (_sandUnit == "m³" ? "${sandQtyM3.toStringAsFixed(2)} m³" : "${sandQtyBags.toStringAsFixed(0)} σακιά");
                }
                if (marbleDustQtyM3 > 0) {
                  detailNote += "\n- Μαρμαρόσκονη: " + (_marbleUnit == "m³" ? "${marbleDustQtyM3.toStringAsFixed(2)} m³" : "${marbleDustQtyBags.toStringAsFixed(0)} σακιά");
                }
                if (cementQty > 0) detailNote += "\n- Τσιμέντο: $cementQty σακιά";
                if (limeQty > 0) {
                   detailNote += "\n- Ασβέστης: " + (_limeUnit == "σακί" ? "$limeQty σακιά" : "${areaVal.toStringAsFixed(0)} m²");
                }
                if (glueQty > 0) detailNote += "\n- Κόλλα: $glueQty σακιά";

                widget.onResult(_selectedType, q, grandTotal.toStringAsFixed(2), detailNote);
                Navigator.pop(context);
              } : null,
              child: const Text("ΜΕΤΑΦΟΡΑ ΣΤΗΝ ΠΡΟΣΦΟΡΑ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _dualPriceEditRow({
    required String label,
    required String unit1,
    required TextEditingController ctrl1,
    required String unit2,
    required TextEditingController ctrl2,
    required String activeUnit,
    required Function(String) onUnitSwitch,
  }) {
    final bool is1Active = activeUnit == unit1;
    final Color activeColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Price 1
              Expanded(
                child: GestureDetector(
                  onTap: () => onUnitSwitch(unit1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: is1Active ? activeColor.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: is1Active ? activeColor : Colors.black12, width: is1Active ? 1.5 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("€ / $unit1", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: is1Active ? activeColor : Colors.grey)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: ctrl1,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: is1Active ? activeColor : Colors.blueGrey),
                          onChanged: (v) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Price 2
              Expanded(
                child: GestureDetector(
                  onTap: () => onUnitSwitch(unit2),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !is1Active ? activeColor.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: !is1Active ? activeColor : Colors.black12, width: !is1Active ? 1.5 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("€ / $unit2", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: !is1Active ? activeColor : Colors.grey)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: ctrl2,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: !is1Active ? activeColor : Colors.blueGrey),
                          onChanged: (v) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
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

  Widget _matRow(String label, String qty, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("• $label:", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(qty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              Text(detail, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
