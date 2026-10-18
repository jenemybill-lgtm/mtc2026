import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/utils/toast_helper.dart';

class MaterialReceiptScreen extends StatefulWidget {
  final Project project;
  const MaterialReceiptScreen({super.key, required this.project});

  @override
  State<MaterialReceiptScreen> createState() => _MaterialReceiptScreenState();
}

class _MaterialReceiptScreenState extends State<MaterialReceiptScreen> {
  final List<Map<String, dynamic>> _receiptItems = [];
  final _supplierController = TextEditingController();

  void _showAddItemDialog() {
    final nameC = TextEditingController();
    final qtyC = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const PremiumHeader(title: "ΝΕΟ ΥΛΙΚΟ ΠΑΡΑΛΑΒΗΣ", icon: Icons.add_box_rounded, color: Color(0xFF4CC9F0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC, 
              decoration: const InputDecoration(labelText: "Όνομα / Περιγραφή Υλικού", prefixIcon: Icon(Icons.inventory_2_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyC, 
              decoration: const InputDecoration(labelText: "Ποσότητα (Τεμάχια/Μέτρα/Σακιά)", prefixIcon: Icon(Icons.numbers_rounded)), 
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isNotEmpty) {
                setState(() {
                  _receiptItems.add({
                    'name': nameC.text,
                    'quantity': double.tryParse(qtyC.text) ?? 1.0,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CC9F0)),
            child: const Text("ΠΡΟΣΘΗΚΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ΚΑΤΑΧΩΡΗΣΗ ΠΑΡΑΛΑΒΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text("ΝΕΟ ΥΛΙΚΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF4CC9F0),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                ),
                child: TextField(
                  controller: _supplierController,
                  decoration: const InputDecoration(
                    labelText: "Προμηθευτής / Μεταφορική (Προαιρετικό)",
                    prefixIcon: Icon(Icons.local_shipping_rounded, color: Colors.blueGrey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _receiptItems.isEmpty
                    ? const PremiumEmptyState(
                        title: "ΑΔΕΙΟ ΔΕΛΤΙΟ ΠΑΡΑΛΑΒΗΣ",
                        subtitle: "Δεν έχετε προσθέσει υλικά.\nΠατήστε 'ΝΕΟ ΥΛΙΚΟ' για να προσθέσετε.",
                        icon: Icons.inventory_2_outlined,
                      )
                    : ListView.builder(
                        itemCount: _receiptItems.length,
                        itemBuilder: (context, index) {
                          final item = _receiptItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF4CC9F0).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CC9F0)),
                              ),
                              title: Text(item['name'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                              subtitle: Text("Ποσότητα: ${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _receiptItems.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_receiptItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final provider = Provider.of<ProjectProvider>(context, listen: false);
                      
                      // 1. Καταχώρηση στη βάση δεδομένων (στα Υλικά του Έργου)
                      for (var item in _receiptItems) {
                        await provider.addMaterial(MaterialEntity(
                          name: item['name'],
                          category: "ΓΕΝΙΚΑ / ΔΙΑΦΟΡΑ",
                          locationType: "PROJECT",
                          projectId: widget.project.id,
                          quantity: item['quantity'],
                          minStockThreshold: 0,
                        ));
                      }

                      // 2. Δημιουργία PDF Δελτίου Παραλαβής
                      await PdfGenerator.generateAndShareReceipt(
                        projectName: widget.project.name,
                        supplierName: _supplierController.text.trim(),
                        items: _receiptItems,
                        settings: provider.settings,
                      );

                      if (context.mounted) {
                        ToastHelper.showSuccess(context, "Η παραλαβή καταχωρήθηκε επιτυχώς και τα υλικά προστέθηκαν στο έργο!");
                        setState(() {
                          _receiptItems.clear();
                          _supplierController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
                    label: const Text("ΚΑΤΑΧΩΡΗΣΗ & ΕΚΔΟΣΗ PDF", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
