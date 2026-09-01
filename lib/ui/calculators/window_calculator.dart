import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class WindowCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const WindowCalculator({super.key, required this.onResult});

  @override
  State<WindowCalculator> createState() => _WindowCalculatorState();
}

class _WindowCalculatorState extends State<WindowCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _selectedPartner = "Αναστόπουλος";
  String _windowType = "Επάλληλο";
  String _shutterType = "Όχι";
  bool _isBath = false;

  @override
  Widget build(BuildContext context) {
    final w = double.tryParse(_widthController.text) ?? 0.0;
    final h = double.tryParse(_heightController.text) ?? 0.0;

    final hWindow = _shutterType == "Εντός" ? max(0.0, h - 0.14) : h;
    final hShutter = _shutterType == "Εκτός" ? h + 0.14 : h;
    final areaWindow = w * hWindow;
    final areaShutter = w * hShutter;

    double costWindow = 0.0;
    double costShutter = 0.0;

    if (_selectedPartner == "Αναστόπουλος") {
      costWindow = areaWindow > 0 ? 205.0 + (areaWindow * 365.0) : 0.0;
      if (_windowType == "Ανοιγόμενο") costWindow *= 1.05;
      costShutter = (_shutterType != "Όχι" && areaShutter > 0)
          ? (areaShutter <= 1.0 ? 200.0 : 200.0 + ((areaShutter - 1.0) / 0.5).ceil() * 100.0)
          : 0.0;
    } else {
      if (areaWindow > 0) {
        double basePrice = 450.0 + (380.0 * pow(areaWindow, 0.85)) + (250.0 * (w - 3.0));
        double finalPrice = max(basePrice, 0.0);
        if (_shutterType == "Όχι") finalPrice *= (2.0 / 3.0);
        costWindow = finalPrice;
        if (_windowType == "Ανοιγόμενο") costWindow *= 1.05;
      }
    }
    final unitCost = (costWindow + costShutter) * 1.05;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          QuantityMultiplierField(controller: _multiplierController),
          const SizedBox(height: 16),
          SturdyCalcSection(
            title: "Συνεργάτης",
            icon: Icons.badge_rounded,
            child: Row(
              children: ["Αναστόπουλος", "Profilco"].map((p) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: _selectedPartner == p,
                    onSelected: (val) => setState(() => _selectedPartner = p),
                  ),
                ),
              )).toList(),
            ),
          ),
          SturdyCalcSection(
            title: "Διαστάσεις (m)",
            icon: Icons.open_in_full_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _widthController, decoration: const InputDecoration(labelText: "Πλάτος"), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("x", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: TextField(controller: _heightController, decoration: const InputDecoration(labelText: "Ύψος"), keyboardType: TextInputType.number, onChanged: (v) => setState(() {}))),
                  ],
                ),
                SwitchListTile(
                  title: const Text("Είναι Μπάνιο;"),
                  value: _isBath,
                  onChanged: (val) {
                    setState(() {
                      _isBath = val;
                      if (val) _shutterType = "Όχι";
                    });
                  },
                ),
              ],
            ),
          ),
          SturdyCalcSection(
            title: "Τύπος & Ρολό",
            icon: Icons.settings_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isBath) ...[
                  const Text("Επιλογή Ρολού:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Row(
                    children: ["Όχι", "Εντός", "Εκτός"].map((type) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(label: Text(type), selected: _shutterType == type, onSelected: (val) => setState(() => _shutterType = type)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text("Τύπος Κουφώματος:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: ["Επάλληλο", "Ανοιγόμενο"].map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(label: Text(type), selected: _windowType == type, onSelected: (val) => setState(() => _windowType = type)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          SturdyResultBanner(total: unitCost, quantity: _multiplierController.text),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: unitCost > 0 ? () {
                final typeInfo = _windowType == "Επάλληλο" ? "Επάλληλο Alu EUROPA" : "Ανοιγώμενο ALU EUROPA";
                final shutterInfo = _shutterType != "Όχι" ? " + Ηλεκτρικό Ρολό" : "";
                final desc = "$typeInfo$shutterInfo (${_widthController.text}x${_heightController.text})";
                widget.onResult(desc, _multiplierController.text, unitCost.toStringAsFixed(2), "Αλγόριθμος $_selectedPartner");
                Navigator.pop(context);
              } : null,
              child: const Text("ΜΕΤΑΦΟΡΑ ΣΤΗΝ ΠΡΟΣΦΟΡΑ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
