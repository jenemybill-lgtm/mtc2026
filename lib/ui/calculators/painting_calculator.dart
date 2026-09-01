import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class PaintingCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const PaintingCalculator({super.key, required this.onResult});

  @override
  State<PaintingCalculator> createState() => _PaintingCalculatorState();
}

class _PaintingCalculatorState extends State<PaintingCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  int _calcMethod = 0; // 0: Analytical, 1: Flat rate
  
  final _wallSqm = TextEditingController();
  final _wallSpatSqm = TextEditingController();
  final _ceilingSqm = TextEditingController();
  final _ceilingSpatSqm = TextEditingController();
  
  final _houseSqm = TextEditingController();
  final _doorsCount = TextEditingController(text: "0");
  final _wardrobesCount = TextEditingController(text: "0");

  // Unit Price Controllers
  final _wallPriceController = TextEditingController(text: "5.0");
  final _wallSpatPriceController = TextEditingController(text: "10.0");
  final _ceilingPriceController = TextEditingController(text: "8.0");
  final _ceilingSpatPriceController = TextEditingController(text: "16.0");
  final _houseFlatPriceController = TextEditingController(text: "18.0");
  final _doorPriceController = TextEditingController(text: "55.0");
  final _wardrobePriceController = TextEditingController(text: "250.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_PAINTING");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "WALL") _wallPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "WALL_SPAT") _wallSpatPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "CEILING") _ceilingPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "CEILING_SPAT") _ceilingSpatPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "HOUSE_FLAT") _houseFlatPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "DOOR") _doorPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "WARDROBE") _wardrobePriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_PAINTING");

    final Map<String, double> prices = {
      "WALL": double.tryParse(_wallPriceController.text) ?? 5.0,
      "WALL_SPAT": double.tryParse(_wallSpatPriceController.text) ?? 10.0,
      "CEILING": double.tryParse(_ceilingPriceController.text) ?? 8.0,
      "CEILING_SPAT": double.tryParse(_ceilingSpatPriceController.text) ?? 16.0,
      "HOUSE_FLAT": double.tryParse(_houseFlatPriceController.text) ?? 18.0,
      "DOOR": double.tryParse(_doorPriceController.text) ?? 55.0,
      "WARDROBE": double.tryParse(_wardrobePriceController.text) ?? 250.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_PAINTING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_PAINTING", description: entry.key, unit: "€", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallPrice = double.tryParse(_wallPriceController.text) ?? 5.0;
    final wallSpatPrice = double.tryParse(_wallSpatPriceController.text) ?? 10.0;
    final ceilingPrice = double.tryParse(_ceilingPriceController.text) ?? 8.0;
    final ceilingSpatPrice = double.tryParse(_ceilingSpatPriceController.text) ?? 16.0;
    final houseFlatPrice = double.tryParse(_houseFlatPriceController.text) ?? 18.0;
    final doorPrice = double.tryParse(_doorPriceController.text) ?? 55.0;
    final wardrobePrice = double.tryParse(_wardrobePriceController.text) ?? 250.0;

    double total = 0.0;
    if (_calcMethod == 0) {
      total += (double.tryParse(_wallSqm.text) ?? 0) * wallPrice;
      total += (double.tryParse(_wallSpatSqm.text) ?? 0) * wallSpatPrice;
      total += (double.tryParse(_ceilingSqm.text) ?? 0) * ceilingPrice;
      total += (double.tryParse(_ceilingSpatSqm.text) ?? 0) * ceilingSpatPrice;
    } else {
      total += (double.tryParse(_houseSqm.text) ?? 0) * houseFlatPrice;
    }
    total += (int.tryParse(_doorsCount.text) ?? 0) * doorPrice;
    total += (int.tryParse(_wardrobesCount.text) ?? 0) * wardrobePrice;

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
                title: "Τιμές Μονάδας Χρωματισμών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Τοίχοι (€/m²)", _wallPriceController),
                    _priceEditRow("Τοίχοι Σπατ. (€/m²)", _wallSpatPriceController),
                    _priceEditRow("Ταβάνια (€/m²)", _ceilingPriceController),
                    _priceEditRow("Ταβάνια Σπατ. (€/m²)", _ceilingSpatPriceController),
                    _priceEditRow("Οικία Flat (€/m²)", _houseFlatPriceController),
                    _priceEditRow("Πόρτα (€/τεμ)", _doorPriceController),
                    _priceEditRow("Ντουλάπα (€/τεμ)", _wardrobePriceController),
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
                    tabs: const [Tab(text: "Αναλυτικά"), Tab(text: "Βάσει τμ")],
                  ),
                ),
                const SizedBox(height: 16),
                if (_calcMethod == 0)
                  SturdyCalcSection(
                    title: "Επιφάνειες (m²)",
                    icon: Icons.brush_rounded,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _wallSqm, decoration: InputDecoration(labelText: "Τοίχοι (${wallPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _wallSpatSqm, decoration: InputDecoration(labelText: "Σπατ. (${wallSpatPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _ceilingSqm, decoration: InputDecoration(labelText: "Ταβάνια (${ceilingPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _ceilingSpatSqm, decoration: InputDecoration(labelText: "Σπατ. (${ceilingSpatPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  SturdyCalcSection(
                    title: "Οικία (m²)",
                    icon: Icons.home_rounded,
                    child: TextField(controller: _houseSqm, decoration: InputDecoration(labelText: "τμ Σπιτιού (${houseFlatPrice.toInt()}€/τμ)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                  ),
                SturdyCalcSection(
                  title: "Πρόσθετα Τεμάχια",
                  icon: Icons.door_sliding_rounded,
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _doorsCount, decoration: InputDecoration(labelText: "Πόρτες (${doorPrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _wardrobesCount, decoration: InputDecoration(labelText: "Ντουλάπες (${wardrobePrice.toInt()}€)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                    ],
                  ),
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
                
                String detailNote = "ΑΝΑΛΥΣΗ ΧΡΩΜΑΤΙΣΜΩΝ:\n";
                if (_calcMethod == 0) {
                  if (_wallSqm.text.isNotEmpty && _wallSqm.text != "0") detailNote += "- Τοίχοι: ${_wallSqm.text} m²\n";
                  if (_wallSpatSqm.text.isNotEmpty && _wallSpatSqm.text != "0") detailNote += "- Τοίχοι Σπατ.: ${_wallSpatSqm.text} m²\n";
                  if (_ceilingSqm.text.isNotEmpty && _ceilingSqm.text != "0") detailNote += "- Ταβάνια: ${_ceilingSqm.text} m²\n";
                  if (_ceilingSpatSqm.text.isNotEmpty && _ceilingSpatSqm.text != "0") detailNote += "- Ταβάνια Σπατ.: ${_ceilingSpatSqm.text} m²\n";
                } else {
                  detailNote += "- Οικία (Flat rate): ${_houseSqm.text} m²\n";
                }
                if (_doorsCount.text != "0") detailNote += "- Πόρτες: ${_doorsCount.text} τεμ\n";
                if (_wardrobesCount.text != "0") detailNote += "- Ντουλάπες: ${_wardrobesCount.text} τεμ";

                widget.onResult("Χρωματισμοί", _multiplierController.text, total.toStringAsFixed(2), detailNote);
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
