import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/toast_helper.dart';

class IndependentCashRegisterScreen extends StatefulWidget {
  const IndependentCashRegisterScreen({super.key});

  @override
  State<IndependentCashRegisterScreen> createState() => _IndependentCashRegisterScreenState();
}

class _IndependentCashRegisterScreenState extends State<IndependentCashRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ΤΑΜΕΙΟ / ΚΙΝΗΣΕΙΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text("Ανεξάρτητη καταγραφή εσόδων-εξόδων", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCashFlowDialog(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text("ΝΕΑ ΚΙΝΗΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF4361EE),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: FutureBuilder<List<CashFlowEntity>>(
            future: provider.getCashFlows(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allRecords = snapshot.data!;
              if (allRecords.isEmpty) {
                return const PremiumEmptyState(
                  title: "ΚΑΜΙΑ ΕΓΓΡΑΦΗ",
                  subtitle: "Δεν βρέθηκαν συναλλαγές στο ταμείο.\nΠατήστε 'ΝΕΑ ΚΙΝΗΣΗ' για να προσθέσετε.",
                  icon: Icons.account_balance_wallet_outlined,
                );
              }

              // Ομαδοποίηση ανά Μήνα/Έτος
              final Map<DateTime, List<CashFlowEntity>> groupedRecords = {};
              for (var r in allRecords) {
                final dt = DateTime.fromMillisecondsSinceEpoch(r.date);
                final monthKey = DateTime(dt.year, dt.month); // Χρήση 1ης μέρας του μήνα ως κλειδί
                groupedRecords.putIfAbsent(monthKey, () => []).add(r);
              }

              // Ταξινόμηση μηνών (πιο πρόσφατος πρώτος)
              final sortedMonths = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                itemCount: sortedMonths.length,
                itemBuilder: (context, index) {
                  final month = sortedMonths[index];
                  final records = groupedRecords[month]!;
                  final monthTitle = DateFormat('MMMM yyyy', 'el').format(month).toUpperCase();
                  
                  final totalIncome = records.where((r) => r.type == "INCOME").fold(0.0, (sum, r) => sum + r.amount);
                  final totalExpense = records.where((r) => r.type != "INCOME").fold(0.0, (sum, r) => sum + r.amount);
                  final balance = totalIncome - totalExpense;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0, // Ανοιχτός μόνο ο πιο πρόσφατος μήνας
                        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4361EE).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.date_range_rounded, color: Color(0xFF4361EE), size: 22),
                        ),
                        title: Text(monthTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                        subtitle: Text(
                          "${records.length} Εγγραφές | Υπόλοιπο: ${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €", 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: balance >= 0 ? const Color(0xFF10B981) : Colors.redAccent),
                        ),
                        children: [
                          _buildSummaryCards(totalIncome, totalExpense, balance),
                          ...records.map((record) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _CashFlowCard(
                              record: record,
                              onEdit: () => _showCashFlowDialog(context, provider, recordToEdit: record),
                              onDelete: () => _deleteRecord(context, provider, record),
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ΤΡΕΧΟΝ ΥΠΟΛΟΙΠΟ ΜΗΝΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (balance >= 0 ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${balance.toStringAsFixed(2)} €", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: balance >= 0 ? const Color(0xFF10B981) : Colors.redAccent),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
                    ),
                    child: _SummaryStat("ΕΣΟΔΑ (+)", income, const Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
                    ),
                    child: _SummaryStat("ΕΞΟΔΑ (-)", expense, Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCashFlowDialog(BuildContext context, ProjectProvider provider, {CashFlowEntity? recordToEdit}) {
    String type = recordToEdit?.type ?? "EXPENSE";
    DateTime selectedDate = recordToEdit != null ? DateTime.fromMillisecondsSinceEpoch(recordToEdit.date) : DateTime.now();
    final amountC = TextEditingController(text: recordToEdit?.amount == 0.0 ? "" : recordToEdit?.amount.toString() ?? "");
    final descC = TextEditingController(text: recordToEdit?.description ?? "");
    final invoiceC = TextEditingController(text: recordToEdit?.invoiceNumber ?? "");
    final projectC = TextEditingController(text: recordToEdit?.projectName ?? "");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: PremiumHeader(
            title: recordToEdit == null ? "ΝΕΑ ΕΓΓΡΑΦΗ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΕΓΓΡΑΦΗΣ", 
            icon: Icons.account_balance_wallet_rounded, 
            color: const Color(0xFF4361EE)
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "INCOME", label: Text("ΕΣΟΔΟ (+)", style: TextStyle(fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "EXPENSE_LABOR", label: Text("ΕΡΓΑΤΙΚΑ (-)", style: TextStyle(fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "EXPENSE_MATERIAL", label: Text("ΥΛΙΚΑ (-)", style: TextStyle(fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "EXPENSE_SUBCONTRACTOR", label: Text("ΣΥΝΕΡΓΑΤΕΣ (-)", style: TextStyle(fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "EXPENSE", label: Text("ΓΕΝΙΚΟ ΕΞΟΔΟ (-)", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setDialogState(() => type = s.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: type == "INCOME" ? const Color(0xFF10B981) : Colors.redAccent,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx, 
                        initialDate: selectedDate, 
                        firstDate: DateTime(2020), 
                        lastDate: DateTime(2030)
                      );
                      if (date != null) setDialogState(() => selectedDate = date);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 12),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountC,
                    decoration: InputDecoration(labelText: "Ποσό (€)", prefixIcon: const Icon(Icons.euro_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descC,
                    decoration: InputDecoration(labelText: "Αιτιολογία / Περιγραφή", prefixIcon: const Icon(Icons.description_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: invoiceC,
                    decoration: InputDecoration(
                      labelText: "Αριθμός Τιμολογίου/Απόδειξης", 
                      hintText: "(Αφήστε κενό αν δεν υπάρχει παραστατικό)",
                      prefixIcon: const Icon(Icons.receipt_rounded, size: 20), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: projectC,
                    decoration: InputDecoration(
                      labelText: "Όνομα Έργου (Ελεύθερο κείμενο - Προαιρετικό)", 
                      hintText: "π.χ. Έργο Παπάγου",
                      prefixIcon: const Icon(Icons.business_center_rounded, size: 20), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0.0;
                if (amt > 0 && descC.text.isNotEmpty) {
                  final record = CashFlowEntity(
                    id: recordToEdit?.id ?? 0,
                    date: selectedDate.millisecondsSinceEpoch,
                    type: type,
                    amount: amt,
                    description: descC.text.trim(),
                    invoiceNumber: invoiceC.text.trim(),
                    projectName: projectC.text.trim(),
                  );

                  if (recordToEdit == null) {
                    await provider.addCashFlow(record);
                  } else {
                    await provider.updateCashFlow(record);
                  }
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                } else {
                  ToastHelper.showError(ctx, "Συμπληρώστε ποσό και αιτιολογία.");
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE)),
              child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(BuildContext context, ProjectProvider provider, CashFlowEntity record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή την εγγραφή;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteCashFlow(record.id);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("ΔΙΑΓΡΑΦΗ"),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryStat(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  final CashFlowEntity record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CashFlowCard({required this.record, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == "INCOME";
    final color = isIncome ? const Color(0xFF10B981) : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 5, color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(isIncome ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(record.date)), style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text(
                        "${isIncome ? '+' : '-'}${record.amount.toStringAsFixed(2)} €", 
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color),
                      ),
                    ],
                  ),
                  if (record.invoiceNumber.isNotEmpty || record.projectName.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (record.invoiceNumber.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.receipt_rounded, size: 14, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text("ΑΡ: ${record.invoiceNumber}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          )
                        else
                          const Text("Χωρίς Παραστατικό", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                          
                        if (record.projectName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF4361EE).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.business_center_rounded, size: 10, color: Color(0xFF4361EE)),
                                const SizedBox(width: 4),
                                Text(record.projectName.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4361EE))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: onEdit, constraints: const BoxConstraints()),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), onPressed: onDelete, constraints: const BoxConstraints()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
