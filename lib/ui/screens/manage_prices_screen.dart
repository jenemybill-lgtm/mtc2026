import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ManagePricesScreen extends StatelessWidget {
  const ManagePricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("ΠΡΟΤΥΠΑ ΤΙΜΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: AppDestinations.values.length,
        itemBuilder: (context, index) {
          final cat = AppDestinations.values[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PremiumCard(
              accentColor: cat.color,
              padding: const EdgeInsets.all(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CategoryPricesScreen(category: cat))),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cat.color, cat.color.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: cat.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(cat.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      cat.label.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 0.5)
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: cat.color.withValues(alpha: 0.2), size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryPricesScreen extends StatefulWidget {
  final AppDestinations category;
  const _CategoryPricesScreen({required this.category});

  @override
  State<_CategoryPricesScreen> createState() => _CategoryPricesScreenState();
}

class _CategoryPricesScreenState extends State<_CategoryPricesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final color = widget.category.color;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.category.label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPriceDialog(context),
        label: const Text("ΝΕΑ ΤΙΜΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<GlobalPriceEntity>>(
        future: provider.getGlobalPrices(widget.category.name),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final prices = snapshot.data!;
          if (prices.isEmpty) return const Center(child: Text("Δεν υπάρχουν αποθηκευμένα πρότυπα."));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: prices.length,
            itemBuilder: (context, index) {
              final price = prices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  accentColor: color,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(widget.category.icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                            Text("ΜΟΝΑΔΑ: ${price.unit}", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.1)),
                        ),
                        child: Text("${price.defaultUnitPrice.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black12),
                        onPressed: () => _showDeleteConfirm(context, price),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPriceDialog(BuildContext context) {
    final descController = TextEditingController();
    final unitController = TextEditingController(text: "τ.μ.");
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΝΕΟ ΠΡΟΤΥΠΟ ΤΙΜΗΣ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Περιγραφή")),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: "Μονάδα")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Τιμή Αγοράς (€)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).addGlobalPrice(GlobalPriceEntity(
                  category: widget.category.name,
                  description: descController.text,
                  unit: unitController.text,
                  defaultUnitPrice: double.tryParse(priceController.text) ?? 0.0,
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

  void _showDeleteConfirm(BuildContext context, GlobalPriceEntity price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΔΙΑΓΡΑΦΗ ΠΡΟΤΥΠΟΥ"),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε το πρότυπο '${price.description}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProjectProvider>(context, listen: false).deleteGlobalPrice(price.id).then((_) => setState(() {}));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ"),
          ),
        ],
      ),
    );
  }
}
