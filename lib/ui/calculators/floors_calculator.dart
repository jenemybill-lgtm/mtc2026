import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/calculators/calculator_widgets.dart';

class FloorsCalculator extends StatefulWidget {
  final Function(String, String, String, String) onResult;

  const FloorsCalculator({super.key, required this.onResult});

  @override
  State<FloorsCalculator> createState() => _FloorsCalculatorState();
}

class _FloorsCalculatorState extends State<FloorsCalculator> {
  final _multiplierController = TextEditingController(text: "1");
  int _calcMethod = 0; // 0: Pre-polished, 1: Solid
  
  final _areaSqm = TextEditingController();
  bool _includePurchase = true;
  bool _includeInstallation = true;
  bool _includePrimer = false;

  final _roomsCount = TextEditingController(text: "0");

  // Unit Price Controllers
  final _purchasePriceController = TextEditingController(text: "45.0");
  final _installPriceController = TextEditingController(text: "14.0");
  final _primerPriceController = TextEditingController(text: "14.0");
  final _solidRoomPriceController = TextEditingController(text: "350.0");

  bool _showPriceSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPrices();
  }

  Future<void> _loadStoredPrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_FLOORS");
    if (stored.isNotEmpty) {
      setState(() {
        for (var p in stored) {
          if (p.description == "PURCHASE") _purchasePriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "INSTALL") _installPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "PRIMER") _primerPriceController.text = p.defaultUnitPrice.toString();
          if (p.description == "SOLID_ROOM") _solidRoomPriceController.text = p.defaultUnitPrice.toString();
        }
      });
    }
  }

  Future<void> _savePrices() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final stored = await provider.getGlobalPrices("CALC_FLOORS");

    final Map<String, double> prices = {
      "PURCHASE": double.tryParse(_purchasePriceController.text) ?? 45.0,
      "INSTALL": double.tryParse(_installPriceController.text) ?? 14.0,
      "PRIMER": double.tryParse(_primerPriceController.text) ?? 14.0,
      "SOLID_ROOM": double.tryParse(_solidRoomPriceController.text) ?? 350.0,
    };

    for (var entry in prices.entries) {
      final existing = stored.firstWhereOrNull((p) => p.description == entry.key);
      if (existing != null) {
        await provider.updateGlobalPrice(GlobalPriceEntity(id: existing.id, category: "CALC_FLOORS", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      } else {
        await provider.addGlobalPrice(GlobalPriceEntity(category: "CALC_FLOORS", description: entry.key, unit: "unit", defaultUnitPrice: entry.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purPrice = double.tryParse(_purchasePriceController.text) ?? 45.0;
    final insPrice = double.tryParse(_installPriceController.text) ?? 14.0;
    final priPrice = double.tryParse(_primerPriceController.text) ?? 14.0;
    final solPrice = double.tryParse(_solidRoomPriceController.text) ?? 350.0;

    double total = 0.0;
    if (_calcMethod == 0) {
      double rate = 0.0;
      if (_includePurchase) rate += purPrice;
      if (_includeInstallation) rate += insPrice;
      if (_includePrimer) rate += priPrice;
      total = (double.tryParse(_areaSqm.text) ?? 0) * rate;
    } else {
      total = (int.tryParse(_roomsCount.text) ?? 0) * solPrice;
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
                title: "Τιμές Μονάδας Δαπέδων",
                icon: Icons.price_change_rounded,
                child: Column(
                  children: [
                    _priceEditRow("Αγορά Υλικού (€/m²)", _purchasePriceController),
                    _priceEditRow("Τοποθέτηση (€/m²)", _installPriceController),
                    _priceEditRow("Αστάρι (€/m²)", _primerPriceController),
                    _priceEditRow("Solid (Τρίψ/Δωμ.) (€)", _solidRoomPriceController),
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
                    tabs: const [Tab(text: "Προγυαλισμένο"), Tab(text: "Μασίφ (Τρίψιμο)")],
                  ),
                ),
                const SizedBox(height: 16),
                if (_calcMethod == 0)
                  SturdyCalcSection(
                    title: "Μετρήσεις & Επιλογές",
                    icon: Icons.square_foot_rounded,
                    child: Column(
                      children: [
                        TextField(controller: _areaSqm, decoration: const InputDecoration(labelText: "Επιφάνεια m²", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                        const SizedBox(height: 8),
                        CheckboxListTile(title: Text("Αγορά Υλικού (${purPrice.toInt()}€/m²)"), value: _includePurchase, onChanged: (v) => setState(() => _includePurchase = v!), contentPadding: EdgeInsets.zero),
                        CheckboxListTile(title: Text("Τοποθέτηση (${insPrice.toInt()}€/m²)"), value: _includeInstallation, onChanged: (v) => setState(() => _includeInstallation = v!), contentPadding: EdgeInsets.zero),
                        CheckboxListTile(title: Text("Αστάρι (${priPrice.toInt()}€/m²)"), value: _includePrimer, onChanged: (v) => setState(() => _includePrimer = v!), contentPadding: EdgeInsets.zero),
                      ],
                    ),
                  )
                else
                  SturdyCalcSection(
                    title: "Τρίψιμο & Γυάλισμα",
                    icon: Icons.home_repair_service_rounded,
                    child: Column(
                      children: [
                        TextField(controller: _roomsCount, decoration: InputDecoration(labelText: "Αριθμός Δωματίων (${solPrice.toInt()}€/τεμ)", border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => setState(() {})),
                        const SizedBox(height: 8),
                        const Text("* Περιλαμβάνει τρίψιμο και γυάλισμα μασίφ δαπέδου.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
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
                
                String detailNote = "ΑΝΑΛΥΣΗ ΔΑΠΕΔΩΝ:\n";
                if (_calcMethod == 0) {
                  detailNote += "- Προγυαλισμένο: ${_areaSqm.text} m²\n";
                  detailNote += "- Περιλαμβάνει: ";
                  List<String> inc = [];
                  if (_includePurchase) inc.add("Αγορά");
                  if (_includeInstallation) inc.add("Τοποθέτηση");
                  if (_includePrimer) inc.add("Αστάρι");
                  detailNote += inc.join(", ");
                } else {
                  detailNote += "- Μασίφ: ${_roomsCount.text} δωμάτια\n";
                  detailNote += "- Εργασία: Τρίψιμο & Γυάλισμα";
                }

                String title = _calcMethod == 0 ? "Προγυαλισμένο Δάπεδο" : "Τρίψιμο/Γυάλισμα Μασίφ";
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
