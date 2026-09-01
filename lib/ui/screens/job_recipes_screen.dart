import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class JobRecipesScreen extends StatefulWidget {
  const JobRecipesScreen({super.key});

  @override
  State<JobRecipesScreen> createState() => _JobRecipesScreenState();
}

class _JobRecipesScreenState extends State<JobRecipesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΠΡΟΤΥΠΑ ΕΡΓΑΣΙΩΝ (RECIPES)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecipeDialog(context, provider),
        label: const Text("ΝΕΑ ΣΥΝΤΑΓΗ"),
        icon: const Icon(Icons.auto_fix_high_rounded),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: FutureBuilder<List<JobRecipe>>(
            future: provider.getJobRecipes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final recipes = snapshot.data!;

              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      const Text("Δεν έχετε δημιουργήσει πρότυπα ακόμα.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: recipes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final cat = AppDestinations.values.firstWhere((d) => d.name == recipe.category, orElse: () => AppDestinations.GENERAL);
                  return _RecipeCard(
                    recipe: recipe,
                    category: cat,
                    onDelete: () => provider.deleteJobRecipe(recipe.id).then((_) => setState(() {})),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRecipeDialog(BuildContext context, ProjectProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddRecipeDialog(onConfirm: () => setState(() {})),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final JobRecipe recipe;
  final AppDestinations category;
  final VoidCallback onDelete;

  const _RecipeCard({required this.recipe, required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: category.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    Text(category.label, style: TextStyle(color: category.color, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1)),
                  ],
                ),
              ),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.black12, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("ΥΛΙΚΑ ΑΝΑ ΜΟΝΑΔΑ:", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...recipe.materials.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 4, color: Colors.grey),
                const SizedBox(width: 8),
                Text("${m.name}: ", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text("${m.quantityPerUnit} ${m.unit}", style: const TextStyle(fontSize: 11)),
              ],
            ),
          )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ΕΡΓΑΤΙΚΑ ΑΝΑ ΜΟΝΑΔΑ:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text("${recipe.estimatedLabor.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRecipeDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const _AddRecipeDialog({required this.onConfirm});

  @override
  State<_AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends State<_AddRecipeDialog> {
  final _nameController = TextEditingController();
  final _laborController = TextEditingController();
  String _selectedCategory = AppDestinations.GENERAL.name;
  List<RecipeComponent> _materials = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const PremiumHeader(title: "ΔΗΜΙΟΥΡΓΙΑ ΠΡΟΤΥΠΟΥ", icon: Icons.auto_fix_high_rounded),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Όνομα Συνταγής (π.χ. Σοβάτισμα Standard)")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Κατηγορία"),
                items: AppDestinations.values.map((d) => DropdownMenuItem(value: d.name, child: Text(d.label))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ΥΛΙΚΑ (ΑΝΑ ΜΟΝΑΔΑ)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  IconButton(onPressed: _addMaterial, icon: const Icon(Icons.add_circle_outline, color: Colors.blue)),
                ],
              ),
              ..._materials.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    Text("${entry.value.quantityPerUnit} ${entry.value.unit}", style: const TextStyle(fontSize: 12)),
                    IconButton(onPressed: () => setState(() => _materials.removeAt(entry.key)), icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              TextField(controller: _laborController, decoration: const InputDecoration(labelText: "Εργατικά ανά Μονάδα (€)", prefixIcon: Icon(Icons.person_outline)), keyboardType: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isNotEmpty) {
              final recipe = JobRecipe(
                name: _nameController.text,
                category: _selectedCategory,
                materials: _materials,
                estimatedLabor: double.tryParse(_laborController.text) ?? 0.0,
              );
              await Provider.of<ProjectProvider>(context, listen: false).addJobRecipe(recipe);
              widget.onConfirm();
              if (context.mounted) Navigator.pop(context);
            }
          }, 
          child: const Text("ΑΠΟΘΗΚΕΥΣΗ"),
        ),
      ],
    );
  }

  void _addMaterial() {
    final nameC = TextEditingController();
    final qtyC = TextEditingController();
    final unitC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΠΡΟΣΘΗΚΗ ΥΛΙΚΟΥ ΣΤΗ ΣΥΝΤΑΓΗ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Όνομα Υλικού")),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: qtyC, decoration: const InputDecoration(labelText: "Ποσότητα ανά Μονάδα"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: unitC, decoration: const InputDecoration(labelText: "Μονάδα"))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isNotEmpty) {
                setState(() {
                  _materials.add(RecipeComponent(
                    name: nameC.text, 
                    quantityPerUnit: double.tryParse(qtyC.text) ?? 1.0, 
                    unit: unitC.text.isEmpty ? "τ.μ." : unitC.text
                  ));
                });
                Navigator.pop(context);
              }
            }, 
            child: const Text("ΠΡΟΣΘΗΚΗ"),
          ),
        ],
      ),
    );
  }
}
