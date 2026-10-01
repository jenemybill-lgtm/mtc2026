import 'package:flutter/material.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class EarthworksCalculator extends StatefulWidget {
  final Function(String title, String quantity, String totalCost, String detailedNote) onResult;

  const EarthworksCalculator({super.key, required this.onResult});

  @override
  State<EarthworksCalculator> createState() => _EarthworksCalculatorState();
}

class _EarthworksCalculatorState extends State<EarthworksCalculator> {
  final _volumeController = TextEditingController();
  final _multiplierController = TextEditingController(text: "1");
  final _excavatorDaysController = TextEditingController(text: "1");

  // Editable prices
  final _pricePerCubicMeterController = TextEditingController(text: "18.0");
  final _pricePerTruckTripController = TextEditingController(text: "140.0");
  final _pricePerExcavatorDayController = TextEditingController(text: "400.0");
  final _truckCapacityController = TextEditingController(text: "10.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _volumeController.addListener(() => setState(() {}));
    _multiplierController.addListener(() => setState(() {}));
    _excavatorDaysController.addListener(() => setState(() {}));
    _pricePerCubicMeterController.addListener(() => setState(() {}));
    _pricePerTruckTripController.addListener(() => setState(() {}));
    _pricePerExcavatorDayController.addListener(() => setState(() {}));
    _truckCapacityController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    double volume = double.tryParse(_volumeController.text.replaceAll(',', '.')) ?? 0.0;
    double truckCapacity = double.tryParse(_truckCapacityController.text.replaceAll(',', '.')) ?? 10.0;
    if (truckCapacity <= 0) truckCapacity = 10.0; // fallback safety
    
    int trips = (volume / truckCapacity).ceil();
    int days = int.tryParse(_excavatorDaysController.text) ?? 1;

    double pricePerCubicMeter = double.tryParse(_pricePerCubicMeterController.text.replaceAll(',', '.')) ?? 18.0;
    double pricePerTruckTrip = double.tryParse(_pricePerTruckTripController.text.replaceAll(',', '.')) ?? 140.0;
    double pricePerExcavatorDay = double.tryParse(_pricePerExcavatorDayController.text.replaceAll(',', '.')) ?? 400.0;

    double excavationCost = volume * pricePerCubicMeter;
    double truckCost = trips * pricePerTruckTrip;
    double excavatorCost = days * pricePerExcavatorDay;

    double total = excavationCost + truckCost + excavatorCost;
    
    double q = double.tryParse(_multiplierController.text.replaceAll(',', '.')) ?? 1.0;
    total *= q;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ρυθμίσεις Τιμών", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              Switch(value: _showPriceSettings, onChanged: (v) => setState(() => _showPriceSettings = v), activeTrackColor: Colors.brown, activeColor: Colors.white),
            ],
          ),
          if (_showPriceSettings)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _priceEditRow("Τιμή Εκσκαφής (€/m³)", _pricePerCubicMeterController),
                  _priceEditRow("Τιμή Δρομολογίου Φορτηγού (€)", _pricePerTruckTripController),
                  _priceEditRow("Ημερομίσθιο Τσάπας (€)", _pricePerExcavatorDayController),
                  _priceEditRow("Χωρητικότητα Φορτηγού (m³)", _truckCapacityController),
                ],
              ),
            ),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.brown, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text("Το φορτηγό χωράει 10m³ (συμπιεσμένο χώμα). Ο υπολογισμός δρομολογίων γίνεται αυτόματα.", style: TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCalcField(_volumeController, "Όγκος Εκσκαφής - Άσκαφο (m³)", Icons.straighten_rounded),
          const SizedBox(height: 12),
          _buildCalcField(_excavatorDaysController, "Ημερομίσθια Τσάπας", Icons.precision_manufacturing_rounded),
          const SizedBox(height: 12),
          _buildCalcField(_multiplierController, "Πολλαπλασιαστής (π.χ. Αριθμός ίδιων σκαμμάτων)", Icons.close_rounded),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          if (volume > 0) ...[
            _costRow("Εκσκαφή (${volume}m³ x 18€)", excavationCost),
            _costRow("Μεταφορά ($trips δρομολόγια x 140€)", truckCost),
            _costRow("Τσάπα ($days ημέρες x 400€)", excavatorCost),
            const SizedBox(height: 8),
            const Divider(),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ΣΥΝΟΛΟ ΧΩΜΑΤΟΥΡΓΙΚΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.brown)),
                Text("${total.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.brown)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: total > 0 ? () {
                String detailNote = "ΑΝΑΛΥΣΗ ΧΩΜΑΤΟΥΡΓΙΚΩΝ:\n";
                detailNote += "- Όγκος (πιεσμένο): $volume m³\n";
                detailNote += "- Δρομολόγια (${truckCapacity}m³/φορτηγό): $trips\n";
                detailNote += "- Ημερομίσθια Τσάπας: $days";

                widget.onResult("Χωματουργικά & Εκσκαφές", _multiplierController.text, total.toStringAsFixed(2), detailNote);
              } : null,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text("ΠΡΟΣΘΗΚΗ ΣΤΗΝ ΠΡΟΣΦΟΡΑ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceEditRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown))),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.brown),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _costRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          Text("${val.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
