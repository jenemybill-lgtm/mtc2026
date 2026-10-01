import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class AluminumAiTrainingScreen extends StatefulWidget {
  final Partner partner;

  const AluminumAiTrainingScreen({super.key, required this.partner});

  @override
  State<AluminumAiTrainingScreen> createState() => _AluminumAiTrainingScreenState();
}

class AluminumSample {
  double width = 1.0;
  double height = 1.0;
  String type = "Ανοιγόμενο"; // "Ανοιγόμενο", "Επάλληλο/Συρόμενο"
  bool hasScreen = false;
  String shutter = "Χωρίς Ρολό"; // "Χωρίς Ρολό", "Απλό", "Ηλεκτρικό"
  double price = 0.0;
}

class _AluminumAiTrainingScreenState extends State<AluminumAiTrainingScreen> {
  final List<AluminumSample> _samples = [AluminumSample()];
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiResult;

  void _addSample() {
    setState(() => _samples.add(AluminumSample()));
  }

  void _removeSample(int index) {
    if (_samples.length > 1) {
      setState(() => _samples.removeAt(index));
    }
  }

  Future<void> _analyzeAndSave() async {
    // 1. Validation
    if (_samples.isEmpty || _samples.any((s) => s.price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Συμπληρώστε όλες τις τιμές!")));
      return;
    }

    setState(() => _isAnalyzing = true);

    // 2. Simulated "AI Algorithm" / Equation Solver
    await Future.delayed(const Duration(seconds: 2));

    double bestBasePrice = 180.0;
    double bestScreenPrice = 40.0;
    double bestShutterSimple = 60.0;
    double bestShutterElec = 150.0;
    double slidingMult = 0.85; 
    double minSqm = 1.2;

    // A simplified heuristic based on user input to mock the "Learning" part
    // We look at the first few samples to guess the base price
    for (var s in _samples) {
      double sqm = s.width * s.height;
      if (sqm < 1.0) sqm = 1.0; // guess min 1 sqm
      if (s.price > 0) {
        // very rough estimation just to show dynamic adaptation
        double guessedBase = s.price / sqm;
        if (s.hasScreen) guessedBase -= 30;
        if (s.shutter == "Απλό") guessedBase -= 50;
        if (s.shutter == "Ηλεκτρικό") guessedBase -= 120;
        if (guessedBase > 80 && guessedBase < 400) {
          bestBasePrice = guessedBase;
        }
      }
    }

    final pricingData = {
      'basePricePerSqm': bestBasePrice.roundToDouble(),
      'minSqm': minSqm,
      'screenPrice': bestScreenPrice,
      'shutterSimplePrice': bestShutterSimple,
      'shutterElectricPrice': bestShutterElec,
      'slidingMultiplier': slidingMult,
    };

    // 3. Save to Partner
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final updatedPartner = Partner(
      id: widget.partner.id,
      name: widget.partner.name,
      phone: widget.partner.phone,
      trade: widget.partner.trade,
      baseRate: widget.partner.baseRate,
      aiPricingData: jsonEncode(pricingData),
    );
    
    await provider.updatePartner(updatedPartner);

    setState(() {
      _isAnalyzing = false;
      _aiResult = pricingData;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Ο Αλγόριθμος του συνεργάτη εκπαιδεύτηκε και αποθηκεύτηκε επιτυχώς!"),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("AI ΕΚΠΑΙΔΕΥΣΗ ΚΟΣΤΟΥΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.partner.name.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: Colors.blue, size: 32),
                    SizedBox(width: 16),
                    Expanded(child: Text("Εισάγετε 2-3 πραγματικές προσφορές που έχετε λάβει από τον αλουμινά. Το σύστημα (AI) θα κατανοήσει πώς κοστολογεί και θα δημιουργήσει έναν αυτόματο αλγόριθμο για μελλοντικά κουφώματα.", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _samples.length,
                  itemBuilder: (context, index) {
                    return _buildSampleCard(index);
                  },
                ),
              ),
              if (_aiResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Ο ΑΛΓΟΡΙΘΜΟΣ ΑΠΟΘΗΚΕΥΤΗΚΕ!", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                        ],
                      ),
                      const Divider(),
                      Text("• Βασική Τιμή (m²): ${_aiResult!['basePricePerSqm']}€", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("• Ελάχιστα m² Χρέωσης: ${_aiResult!['minSqm']}m²", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("• Κόστος Σίτας: +${_aiResult!['screenPrice']}€", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("• Κόστος Ρολού (Απλό / Ηλεκτρικό): +${_aiResult!['shutterSimplePrice']}€ / +${_aiResult!['shutterElectricPrice']}€", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addSample, 
                      icon: const Icon(Icons.add), 
                      label: const Text("ΝΕΟ ΠΑΡΑΘΥΡΟ"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeAndSave,
                      icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                      label: const Text("ΑΝΑΛΥΣΗ ΜΕ AI & ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleCard(int index) {
    final sample = _samples[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Δείγμα #${index + 1}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                if (_samples.length > 1)
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeSample(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: sample.width.toString(),
                    decoration: const InputDecoration(labelText: "Πλάτος (m)", isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => sample.width = double.tryParse(v.replaceAll(',', '.')) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: sample.height.toString(),
                    decoration: const InputDecoration(labelText: "Ύψος (m)", isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => sample.height = double.tryParse(v.replaceAll(',', '.')) ?? 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sample.type,
                    decoration: const InputDecoration(labelText: "Τύπος", isDense: true),
                    items: ["Ανοιγόμενο", "Επάλληλο/Συρόμενο"].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => sample.type = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sample.shutter,
                    decoration: const InputDecoration(labelText: "Ρολό", isDense: true),
                    items: ["Χωρίς Ρολό", "Απλό", "Ηλεκτρικό"].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => sample.shutter = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("Με Σίτα", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: sample.hasScreen,
                    onChanged: (v) => setState(() => sample.hasScreen = v!),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: sample.price > 0 ? sample.price.toString() : "",
                    decoration: InputDecoration(labelText: "Τιμή Συνεργάτη (€)", prefixIcon: const Icon(Icons.euro_rounded, size: 16), filled: true, fillColor: Colors.blue.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => sample.price = double.tryParse(v.replaceAll(',', '.')) ?? 0.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
