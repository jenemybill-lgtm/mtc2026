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
                TextField(
                  controller: materialC,
                  decoration: InputDecoration(
                    labelText: "Όνομα Υλικού (Γράψτε ή Επιλέξτε)",
                    hintText: "π.χ. ΤΣΙΜΕΝΤΟ ή ΕΙΔΙΚΟΣ ΑΡΜΟΣΤΟΚΟΣ",
                    prefixIcon: const Icon(Icons.inventory_2_rounded, size: 20),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 28, color: Color(0xFF4361EE)),
                      onSelected: (val) {
                        materialC.text = val;
                        if (standardMaterialsWithUnits.containsKey(val)) {
                          unitC.text = standardMaterialsWithUnits[val]!;
                        }
                      },
                      itemBuilder: (ctx) => standardMaterialsWithUnits.keys.map((m) => PopupMenuItem(
                        value: m, 
                        child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                      )).toList(),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
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
                    : FutureBuilder<List<MaterialEntity>>(
                        future: provider.getMaterials(widget.project.id, "PROJECT", "ΟΛΑ"),
                        builder: (context, snapshot) {
                          final projectInventory = snapshot.data ?? [];

                          return ListView.builder(
                            itemCount: groupedPurchases.length,
                            itemBuilder: (context, index) {
                              final matName = groupedPurchases.keys.elementAt(index);
                              final purchases = groupedPurchases[matName]!;
                              final totalCategorySpent = purchases.fold(0.0, (sum, e) => sum + e.amount);

                              // Calculate total purchased quantity from descriptions
                              double totalPurchasedQty = 0.0;
                              String unit = "τεμ";

                              for (var p in purchases) {
                                final match = RegExp(r"\(([\d.]+)\s*([^)]+)?\)").firstMatch(p.description);
                                if (match != null) {
                                  totalPurchasedQty += double.tryParse(match.group(1)!) ?? 1.0;
                                  if (match.group(2) != null && match.group(2)!.trim().isNotEmpty) {
                                    unit = match.group(2)!.trim();
                                  }
                                } else {
                                  totalPurchasedQty += 1.0;
                                }
                              }

                              // Find inventory item
                              final invMat = projectInventory.firstWhereOrNull((m) => m.name.trim().toUpperCase() == matName.trim().toUpperCase());
                              final remainingQty = invMat?.quantity ?? 0.0;
                              if (invMat != null && invMat.unit.isNotEmpty) {
                                unit = invMat.unit;
                              }

                              final consumedQty = (totalPurchasedQty - remainingQty).clamp(0.0, 99999.0);
                              final indicativePrice = totalPurchasedQty > 0 ? (totalCategorySpent / totalPurchasedQty) : 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1.0),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Header: Material Name + Indicative Unit Price
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: const Color(0xFF4361EE).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4361EE), size: 22),
                                              ),
                                              const SizedBox(width: 14),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(matName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                                                  if (indicativePrice > 0)
                                                    Text("Ενδεικτική Τιμή: ~${indicativePrice.toStringAsFixed(2)} € / $unit", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Material Consumption Badges (3 STATS)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text("ΑΓΟΡΑΣΘΗΚΑΝ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF4361EE))),
                                                const SizedBox(height: 4),
                                                Text("${totalPurchasedQty.toStringAsFixed(0)} $unit", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF4361EE))),
                                              ],
                                            ),
                                          ),
                                          Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.08)),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text("ΧΑΛΑΣΑΝ / ΧΡΗΣΙΜΟΠΟΙΗΘΗΚΑΝ", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.orange)),
                                                const SizedBox(height: 4),
                                                Text("${consumedQty.toStringAsFixed(0)} $unit", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.orange)),
                                              ],
                                            ),
                                          ),
                                          Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.08)),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text("ΥΠΟΛΟΙΠΟ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                                                const SizedBox(height: 4),
                                                Text("${remainingQty.toStringAsFixed(0)} $unit", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10B981))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Expandable Purchases List & Consume Action
                                    ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                                      title: Text("Ιστορικό Αγορών (${purchases.length})", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showConsumeMaterialDialog(context, provider, matName),
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                                              label: const Text("ΚΑΤΑΧΩΡΗΣΗ ΑΝΑΛΩΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
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
