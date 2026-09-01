import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  final int projectId;

  const ShoppingListScreen({super.key, required this.projectId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ΛΙΣΤΑ ΑΓΟΡΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ShoppingItemEntity>>(
        future: provider.getShoppingList(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text("Η λίστα είναι άδεια."));

          final pending = items.where((i) => !i.isBought).toList();
          final bought = items.where((i) => i.isBought).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                const Text("ΕΚΚΡΕΜΟΤΗΤΕΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blue)),
                const SizedBox(height: 8),
                ...pending.map((item) => _ShoppingCard(
                  item: item,
                  onBuy: () => _showBuyDialog(context, item),
                  onDelete: () => provider.deleteShoppingItem(item.id).then((_) => setState(() {})),
                )).toList(),
                const SizedBox(height: 24),
              ],
              if (bought.isNotEmpty) ...[
                const Text("ΑΓΟΡΑΣΤΗΚΑΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 8),
                ...bought.map((item) => _ShoppingCard(
                  item: item,
                  onBuy: () {},
                  onDelete: () => provider.deleteShoppingItem(item.id).then((_) => setState(() {})),
                )).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final descController = TextEditingController();
    final qtyController = TextEditingController();
    final storeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΠΡΟΣΘΗΚΗ ΕΛΛΕΙΨΗΣ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Περιγραφή")),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Ποσότητα")),
            TextField(controller: storeController, decoration: const InputDecoration(labelText: "Προτεινόμενο Κατάστημα")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).addShoppingItem(ShoppingItemEntity(
                  projectId: widget.projectId,
                  description: descController.text,
                  quantity: qtyController.text,
                  suggestedStore: storeController.text,
                )).then((_) => setState(() {}));
                Navigator.pop(context);
              }
            },
            child: const Text("ΠΡΟΣΘΗΚΗ"),
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(BuildContext context, ShoppingItemEntity item) {
    final costController = TextEditingController();
    bool hasVat = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("ΚΑΤΑΓΡΑΦΗ ΑΓΟΡΑΣ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Είδος: ${item.description}"),
              TextField(controller: costController, decoration: const InputDecoration(labelText: "Τελικό Κόστος (€)"), keyboardType: TextInputType.number),
              CheckboxListTile(
                title: const Text("Περιλαμβάνει ΦΠΑ"),
                value: hasVat,
                onChanged: (v) => setDialogState(() => hasVat = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
            ElevatedButton(
              onPressed: () {
                final cost = double.tryParse(costController.text) ?? 0.0;
                Provider.of<ProjectProvider>(context, listen: false).updateShoppingItem(item.copyWith(isBought: true)).then((_) {
                  Provider.of<ProjectProvider>(context, listen: false).addExpense(widget.projectId, Expense(
                    projectId: widget.projectId,
                    date: DateTime.now().millisecondsSinceEpoch,
                    description: "ΑΓΟΡΑ: ${item.description}",
                    workerName: "ΠΡΟΜΗΘΕΥΤΗΣ",
                    amount: cost,
                    hasVat: hasVat,
                    expenseType: "INVOICE",
                                    categoryType: "MATERIAL",
                                  ));
                                }).then((_) => setState(() {}));
                Navigator.pop(context);
              },
              child: const Text("ΟΛΟΚΛΗΡΩΣΗ"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingCard extends StatelessWidget {
  final ShoppingItemEntity item;
  final VoidCallback onBuy;
  final VoidCallback onDelete;

  const _ShoppingCard({required this.item, required this.onBuy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.isBought ? Colors.grey.withValues(alpha: 0.05) : Colors.white,
      child: ListTile(
        title: Text(item.description, style: TextStyle(fontWeight: FontWeight.bold, decoration: item.isBought ? TextDecoration.lineThrough : null, color: item.isBought ? Colors.grey : null)),
        subtitle: Text("${item.quantity} ${item.suggestedStore.isNotEmpty ? '• ${item.suggestedStore}' : ''}", style: const TextStyle(fontSize: 10)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isBought)
              ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(60, 32)),
                child: const Text("ΑΓΟΡΑ", style: TextStyle(fontSize: 10)),
              ),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.close, size: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
