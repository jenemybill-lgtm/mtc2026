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
  final _sqmController = TextEditingController();
  final _widthController = TextEditingController();
  final _projectionController = TextEditingController();

  final _fabricPriceController = TextEditingController(text: "25.0");
  final _armsBasePriceController = TextEditingController(text: "250.0"); // per pair (ζεύγος)
  final _extraArmPriceController = TextEditingController(text: "100.0");
  final _motorPriceController = TextEditingController(text: "250.0");

  int _armPairsCount = 1; // Δυάδες βραχιόνων (default 1 ζεύγος)
  int _extraArmsCount = 0; // Επιπλέον μεμονωμένοι βραχίονες
  int _motorsCount = 0; // Μοτέρ/Μηχανισμοί
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
    final directSqm = double.tryParse(_sqmController.text.replaceAll(',', '.')) ?? 0.0;
    final width = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
    final proj = double.tryParse(_projectionController.text.replaceAll(',', '.')) ?? 0.0;
    
    final sqm = directSqm > 0 ? directSqm : (width * proj);

    final pFabric = double.tryParse(_fabricPriceController.text) ?? 25.0;
    final pArmsBase = double.tryParse(_armsBasePriceController.text) ?? 250.0;
    final pExtraArm = double.tryParse(_extraArmPriceController.text) ?? 100.0;
    final pMotor = double.tryParse(_motorPriceController.text) ?? 250.0;

    // Υπολογισμοί
    final fabricCost = sqm * pFabric;
    final armPairsCost = _armPairsCount * pArmsBase;
    final extraArmsCost = _extraArmsCount * pExtraArm;
    final motorsCost = _motorsCount * pMotor;

    final total = fabricCost + armPairsCost + extraArmsCost + motorsCost;

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
                    _priceEditRow("Δυάδα Βραχιόνων (€/ζεύγος)", _armsBasePriceController),
                    _priceEditRow("Επιπλέον Βραχίονας (€/τεμ)", _extraArmPriceController),
                    _priceEditRow("Μηχανισμός / Μοτέρ (€/τεμ)", _motorPriceController),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "m² Πανιού & Διαστάσεις",
            icon: Icons.straighten_rounded,
            child: Column(
              children: [
                TextField(
                  controller: _sqmController,
                  decoration: const InputDecoration(
                    labelText: "Συνολικά m² Πανιού (Απευθείας ή από διαστάσεις)",
                    prefixIcon: Icon(Icons.aspect_ratio_rounded),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _widthController, 
                        decoration: const InputDecoration(labelText: "Πλάτος (m)", prefixIcon: Icon(Icons.space_bar_rounded), border: OutlineInputBorder()), 
                        keyboardType: TextInputType.number, 
                        onChanged: (v) {
                          final w = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                          final p = double.tryParse(_projectionController.text.replaceAll(',', '.')) ?? 0.0;
                          if (w > 0 && p > 0) {
                            _sqmController.text = (w * p).toStringAsFixed(2);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _projectionController, 
                        decoration: const InputDecoration(labelText: "Άνοιγμα/Κατέβασμα (m)", prefixIcon: Icon(Icons.height_rounded), border: OutlineInputBorder()), 
                        keyboardType: TextInputType.number, 
                        onChanged: (v) {
                          final w = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
                          final p = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                          if (w > 0 && p > 0) {
                            _sqmController.text = (w * p).toStringAsFixed(2);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Τελικά m² Πανιού: ${sqm.toStringAsFixed(2)} m²", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Βραχίονες & Μηχανισμοί",
            icon: Icons.settings_suggest_rounded,
            child: Column(
              children: [
                // 1. Δυάδες / Ζεύγη Βραχιόνων (250 €/ζεύγος)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Δυάδες Βραχιόνων (250€/ζεύγος)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("Περιλαμβάνει 2 βραχίονες & βάση", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(onPressed: () => setState(() { if (_armPairsCount > 0) _armPairsCount--; }), icon: const Icon(Icons.remove)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("$_armPairsCount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        IconButton.filledTonal(onPressed: () => setState(() => _armPairsCount++), icon: const Icon(Icons.add)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 2. Επιπλέον Μεμονωμένοι Βραχίονες (100 €/τεμ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Επιπλέον Βραχίονες (100€/τεμ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("Μεμονωμένος έξτρα βραχίονας", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(onPressed: () => setState(() { if (_extraArmsCount > 0) _extraArmsCount--; }), icon: const Icon(Icons.remove)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("$_extraArmsCount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        IconButton.filledTonal(onPressed: () => setState(() => _extraArmsCount++), icon: const Icon(Icons.add)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 3. Μοτέρ / Μηχανισμοί (250 €/τεμ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ηλεκτρικά Μοτέρ (250€/τεμ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("Μηχανισμός αυτοματισμού", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(onPressed: () => setState(() { if (_motorsCount > 0) _motorsCount--; }), icon: const Icon(Icons.remove)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("$_motorsCount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        IconButton.filledTonal(onPressed: () => setState(() => _motorsCount++), icon: const Icon(Icons.add)),
                      ],
                    ),
                  ],
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
                
                String desc = "Εγκατάσταση Τέντας / Σκίασης (${sqm.toStringAsFixed(1)} m²)";
                String details = "Πανί (${sqm.toStringAsFixed(1)}m²): ${fabricCost.toStringAsFixed(2)}€, Δυάδες Βραχιόνων ($_armPairsCount): ${armPairsCost.toStringAsFixed(2)}€";
                if (_extraArmsCount > 0) details += ", Έξτρα Βραχίονες ($_extraArmsCount): ${extraArmsCost.toStringAsFixed(2)}€";
                if (_motorsCount > 0) details += ", Μοτέρ ($_motorsCount): ${motorsCost.toStringAsFixed(2)}€";

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
