import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class AwningsCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const AwningsCalculator({super.key, required this.onResult});

  @override
  State<AwningsCalculator> createState() => _AwningsCalculatorState();
}

class _AwningsCalculatorState extends State<AwningsCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _widthController = TextEditingController();
  final _projectionController = TextEditingController(); // Κατέβασμα (άνοιγμα)

  final _fabricPriceController = TextEditingController(text: "25.0");
  final _armsBasePriceController = TextEditingController(text: "250.0"); // 2 arms
  final _extraArmPriceController = TextEditingController(text: "100.0");
  final _motorPriceController = TextEditingController(text: "250.0");

  int _armsCount = 2;
  bool _hasMotor = false;
  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_AWNINGS");

    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "FABRIC") _fabricPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "ARMS_BASE") _armsBasePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "EXTRA_ARM") _extraArmPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "MOTOR") _motorPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_AWNINGS");

    final Map<String, double> prices = {
      "FABRIC": double.tryParse(_fabricPriceController.text) ?? 25.0,
      "ARMS_BASE": double.tryParse(_armsBasePriceController.text) ?? 250.0,
      "EXTRA_ARM": double.tryParse(_extraArmPriceController.text) ?? 100.0,
      "MOTOR": double.tryParse(_motorPriceController.text) ?? 250.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.where((p) => p.description == entry.key).firstOrNull;
      final entity = GlobalPriceEntity(
        id: existing?.id ?? 0,
        category: "CALC_AWNINGS",
        description: entry.key,
        unit: "unit",
        defaultUnitPrice: entry.value,
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
    final width = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
    final proj = double.tryParse(_projectionController.text.replaceAll(',', '.')) ?? 0.0;
    final sqm = width * proj;

    final pFabric = double.tryParse(_fabricPriceController.text) ?? 25.0;
    final pArmsBase = double.tryParse(_armsBasePriceController.text) ?? 250.0;
    final pExtraArm = double.tryParse(_extraArmPriceController.text) ?? 100.0;
    final pMotor = double.tryParse(_motorPriceController.text) ?? 250.0;

    // Υπολογισμοί
    final fabricCost = sqm * pFabric;
    
    double armsCost = pArmsBase;
    if (_armsCount > 2) {
      armsCost += (_armsCount - 2) * pExtraArm;
    } else if (_armsCount < 2) {
      // In case they set it to 0 or 1, maybe just scale or set 0? Let's say it's 0 if 0 arms.
      if (_armsCount == 0) armsCost = 0;
      if (_armsCount == 1) armsCost = pArmsBase / 2; // Rough estimate or just minimum 250
    }

    final motorCost = _hasMotor ? pMotor : 0.0;

    final total = fabricCost + armsCost + motorCost;

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
                tooltip: "Ρύθμιση Τιμών",
              ),
            ],
          ),

          if (_showPriceSettings)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SturdyCalcSection(
                title: "Τιμές Μονάδας Τεντών",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Πανί (€/m²)", _fabricPriceController),
                    _priceEditRow("Βραχίονες Βάση (Ζεύγος)", _armsBasePriceController),
                    _priceEditRow("Επιπλέον Βραχίονας", _extraArmPriceController),
                    _priceEditRow("Μηχανισμός (Μοτέρ)", _motorPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Διαστάσεις Τέντας",
            icon: Icons.straighten_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _widthController, decoration: const InputDecoration(labelText: "Πλάτος (m)", prefixIcon: Icon(Icons.space_bar_rounded), border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _projectionController, decoration: const InputDecoration(labelText: "Άνοιγμα/Κατέβασμα (m)", prefixIcon: Icon(Icons.height_rounded), border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Σύνολο Τετραγωνικών (Πανί): ${sqm.toStringAsFixed(2)} m²", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Εξοπλισμός & Μηχανισμοί",
            icon: Icons.settings_suggest_rounded,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Αριθμός Βραχιόνων", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton.filledTonal(onPressed: () => setState(() { if (_armsCount > 0) _armsCount--; }), icon: const Icon(Icons.remove)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("$_armsCount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        ),
                        IconButton.filledTonal(onPressed: () => setState(() => _armsCount++), icon: const Icon(Icons.add)),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Μηχανισμός (Μοτέρ)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Ηλεκτρικός μηχανισμός λειτουργίας"),
                  value: _hasMotor,
                  onChanged: (v) => setState(() => _hasMotor = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          SturdyResultBanner(total: total, quantity: _multiplierController.text),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: total > 0 ? () async {
                final q = _multiplierController.text;
                await _savePrices();
                
                String desc = "Εγκατάσταση Τέντας (${_widthController.text}x${_projectionController.text}m)";
                String details = "Πανί: ${fabricCost.toStringAsFixed(2)}€, Βραχίονες ($_armsCount): ${armsCost.toStringAsFixed(2)}€";
                if (_hasMotor) details += ", Μοτέρ: ${motorCost.toStringAsFixed(2)}€";

                widget.onResult(desc, q, total.toStringAsFixed(2), details);
                Navigator.pop(context);
              } : null,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("ΕΦΑΡΜΟΓΗ ΚΟΣΤΟΥΣ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
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
