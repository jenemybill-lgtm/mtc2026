import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/toast_helper.dart';

import 'package:collection/collection.dart';

class PurchasedMaterialsSummaryScreen extends StatefulWidget {
  final Project project;
  const PurchasedMaterialsSummaryScreen({super.key, required this.project});

  @override
  State<PurchasedMaterialsSummaryScreen> createState() => _PurchasedMaterialsSummaryScreenState();
}

class _PurchasedMaterialsSummaryScreenState extends State<PurchasedMaterialsSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjectData(widget.project.id);
    });
  }

  void _showAddPurchaseDialog(BuildContext context, ProjectProvider provider) {
    final materialC = TextEditingController();
    final qtyC = TextEditingController(text: "1");
    final unitC = TextEditingController(text: "σακί");
    final amountC = TextEditingController();
    final supplierC = TextEditingController();
    final invoiceC = TextEditingController();

    final Map<String, String> standardMaterialsWithUnits = {
      "ΤΣΙΜΕΝΤΟ": "σακί",
      "ΑΜΜΟΣ": "m³",
      "ΜΑΡΜΑΡΟΣΚΟΝΗ": "m³",
      "ΑΣΒΕΣΤΗΣ": "σακί",
      "ΚΟΛΛΑ ΠΛΑΚΙΔΙΩΝ": "σακί",
      "ΧΡΩΜΑΤΑ": "L",
      "ΑΣΤΑΡΙ": "L",
      "ΓΥΨΟΣΑΝΙΔΕΣ": "τεμ",
      "ΣΙΔΗΡΟΣ ΟΠΛΙΣΜΟΥ": "kg",
      "ΣΩΛΗΝΕΣ": "m",
      "ΚΑΛΩΔΙΑ": "m",
      "ΠΛΑΚΑΚΙΑ": "m²",
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const PremiumHeader(title: "ΚΑΤΑΧΩΡΗΣΗ ΑΓΟΡΑΣ ΥΛΙΚΟΥ", icon: Icons.add_shopping_cart_rounded, color: Color(0xFF4361EE)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim().toUpperCase();
                    if (query.isEmpty) return standardMaterialsWithUnits.keys.toList();
                    return standardMaterialsWithUnits.keys.where((String option) => option.contains(query));
                  },
                  onSelected: (String selection) {
                    materialC.text = selection;
                    if (standardMaterialsWithUnits.containsKey(selection)) {
                      unitC.text = standardMaterialsWithUnits[selection]!;
                    }
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    materialC.addListener(() {
                      if (controller.text != materialC.text) {
                        materialC.text = controller.text;
                      }
                    });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: "Επιλογή / Όνομα Υλικού (π.χ. ΤΣΙΜΕΝΤΟ)",
                        prefixIcon: const Icon(Icons.inventory_2_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyC,
                        decoration: InputDecoration(labelText: "Ποσότητα", prefixIcon: const Icon(Icons.numbers_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: unitC,
                        decoration: InputDecoration(labelText: "Μονάδα", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountC,
                  decoration: InputDecoration(labelText: "Συνολικό Κόστος Αγοράς (€)", prefixIcon: const Icon(Icons.euro_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: supplierC,
                  decoration: InputDecoration(labelText: "Προμηθευτής / Κατάστημα", prefixIcon: const Icon(Icons.store_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: invoiceC,
                  decoration: InputDecoration(labelText: "Αριθμός Τιμολογίου / Απόδειξης", prefixIcon: const Icon(Icons.receipt_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              final matName = materialC.text.trim().toUpperCase();
              final qty = double.tryParse(qtyC.text.replaceAll(',', '.')) ?? 1.0;
              final amt = double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0.0;

              if (matName.isNotEmpty) {
                // 1. Add as Project Expense with explicit MATERIAL_PURCHASE type
                final exp = Expense(
                  date: DateTime.now().millisecondsSinceEpoch,
                  description: "ΑΓΟΡΑ ΥΛΙΚΟΥ: $matName ($qty ${unitC.text})",
                  workerName: supplierC.text.trim().isNotEmpty ? supplierC.text.trim() : "ΠΡΟΜΗΘΕΥΤΗΣ",
                  amount: amt,
                  expenseType: "MATERIAL_PURCHASE",
                  projectId: widget.project.id,
                  hasVat: true,
                  invoiceNumber: invoiceC.text.trim(),
                );
                await provider.addExpense(widget.project.id, exp);

                // 2. Automatically link & increase quantity in "Υλικά" (Project Inventory)
                final projectMaterials = await provider.getMaterials(widget.project.id, "PROJECT", "ΟΛΑ");
                final existingMat = projectMaterials.where((m) => m.name.trim().toUpperCase() == matName).firstOrNull;

                if (existingMat != null) {
                  final updatedMat = existingMat.copyWith(
                    quantity: existingMat.quantity + qty,
                    lastUpdated: DateTime.now().millisecondsSinceEpoch,
                  );
                  await provider.updateMaterial(updatedMat);
                } else {
                  await provider.addMaterial(MaterialEntity(
                    name: matName,
                    category: "ΑΓΟΡΕΣ",
                    quantity: qty,
                    unit: unitC.text.trim(),
                    locationType: "PROJECT",
                    projectId: widget.project.id,
                  ));
                }

                if (ctx.mounted) {
                  ToastHelper.showSuccess(ctx, "Η αγορά καταχωρήθηκε & το υπόλοιπο υλικών ενημερώθηκε!");
                  Navigator.pop(ctx);
                  setState(() {});
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE)),
            child: const Text("ΚΑΤΑΧΩΡΗΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showConsumeMaterialDialog(BuildContext context, ProjectProvider provider, String materialName) {
    final qtyC = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: PremiumHeader(
          title: "ΑΝΑΛΩΣΗ / ΧΡΗΣΗ ΥΛΙΚΟΥ", 
          subtitle: materialName.toUpperCase(),
          icon: Icons.output_rounded, 
          color: Colors.orange,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Πόση ποσότητα $materialName χρησιμοποιήθηκε / σπαταλήθηκε στο έργο;", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyC,
              decoration: const InputDecoration(labelText: "Ποσότητα προς Αφαίρεση", prefixIcon: Icon(Icons.remove_circle_outline_rounded, color: Colors.orange)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text("Η ποσότητα αυτή θα αφαιρεθεί αυτόματα από το διαθέσιμο υπόλοιπο του έργου.", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              final consumeQty = double.tryParse(qtyC.text.replaceAll(',', '.')) ?? 0.0;
              if (consumeQty > 0) {
                final projectMaterials = await provider.getMaterials(widget.project.id, "PROJECT", "ΟΛΑ");
                final existingMat = projectMaterials.where((m) => m.name.trim().toUpperCase() == materialName.trim().toUpperCase()).firstOrNull;

                if (existingMat != null) {
                  final newQty = (existingMat.quantity - consumeQty).clamp(0.0, 99999.0);
                  final updatedMat = existingMat.copyWith(
                    quantity: newQty,
                    lastUpdated: DateTime.now().millisecondsSinceEpoch,
                  );
                  await provider.updateMaterial(updatedMat);
                  if (ctx.mounted) {
                    ToastHelper.showSuccess(ctx, "Αφαιρέθηκαν $consumeQty ${existingMat.unit} από το διαθέσιμο υπόλοιπο!");
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                } else {
                  if (ctx.mounted) {
                    ToastHelper.showError(ctx, "Το υλικό δεν βρέθηκε στο υπόλοιπο του έργου.");
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("ΑΦΑΙΡΕΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Filter expenses that are explicitly manually added material purchases for this project
    final materialExpenses = provider.currentProjectExpenses.where((e) => 
        e.expenseType == "MATERIAL_PURCHASE"
    ).toList();

    // Group purchases by Material Name
    final Map<String, List<Expense>> groupedPurchases = {};
    for (var exp in materialExpenses) {
      String matName = exp.description.toUpperCase().replaceAll("ΑΓΟΡΑ ΥΛΙΚΟΥ:", "").trim();
      final parenIdx = matName.indexOf('(');
      if (parenIdx != -1) {
        matName = matName.substring(0, parenIdx).trim();
      }
      if (matName.isEmpty) matName = "ΓΕΝΙΚΑ ΥΛΙΚΑ";
      groupedPurchases.putIfAbsent(matName, () => []).add(exp);
    }

    final totalSpentOnMaterials = materialExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ΑΓΟΡΑΣΜΕΝΑ ΥΛΙΚΑ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPurchaseDialog(context, provider),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text("ΝΕΑ ΑΓΟΡΑ ΥΛΙΚΟΥ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF4361EE),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Summary Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ΣΥΝΟΛΟ ΚΑΤΗΓΟΡΙΩΝ ΥΛΙΚΩΝ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text("${groupedPurchases.length} Διαφορετικά Υλικά", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("ΣΥΝΟΛΙΚΗ ΔΑΠΑΝΗ ΑΓΟΡΩΝ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text("${totalSpentOnMaterials.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF4361EE))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: groupedPurchases.isEmpty
                    ? const PremiumEmptyState(
                        title: "ΔΕΝ ΒΡΕΘΗΚΑΝ ΑΓΟΡΑΣΜΕΝΑ ΥΛΙΚΑ",
                        subtitle: "Δεν έχετε καταχωρήσει αγορές υλικών για αυτό το έργο.\nΠατήστε 'ΝΕΑ ΑΓΟΡΑ ΥΛΙΚΟΥ' για να προσθέσετε.",
                        icon: Icons.shopping_bag_outlined,
                      )
                    : ListView.builder(
                        itemCount: groupedPurchases.length,
                        itemBuilder: (context, index) {
                          final matName = groupedPurchases.keys.elementAt(index);
                          final purchases = groupedPurchases[matName]!;
                          final totalCategorySpent = purchases.fold(0.0, (sum, e) => sum + e.amount);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1.0),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF4361EE).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4361EE), size: 22),
                              ),
                              title: Text(matName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                              subtitle: Text("${purchases.length} Αγορές/Παραστατικά", style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                              trailing: Text("${totalCategorySpent.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4361EE))),
                              children: [
                                const Divider(height: 1),
                                ...purchases.map((p) => ListTile(
                                  dense: true,
                                  title: Text("${p.workerName} - ${p.description}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(p.date)), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  trailing: Text("${p.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                )),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _showConsumeMaterialDialog(context, provider, matName),
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.orange, size: 16),
                                      label: const Text("ΑΝΑΛΩΣΗ / ΧΡΗΣΗ ΥΛΙΚΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.orange)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
