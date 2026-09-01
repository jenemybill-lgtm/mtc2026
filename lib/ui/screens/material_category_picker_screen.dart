import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/screens/material_list_screen.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class MaterialCategoryPickerScreen extends StatefulWidget {
  final String title;
  final String locationType;
  final int? projectId;

  const MaterialCategoryPickerScreen({
    super.key,
    required this.title,
    required this.locationType,
    this.projectId,
  });

  @override
  State<MaterialCategoryPickerScreen> createState() => _MaterialCategoryPickerScreenState();
}

class _MaterialCategoryPickerScreenState extends State<MaterialCategoryPickerScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final categories = provider.materialCategories;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PremiumCategoryCard(
                  name: "ΟΛΑ ΤΑ ΥΛΙΚΑ",
                  icon: Icons.apps_rounded,
                  color: const Color(0xFF7209B7),
                  onClick: () => _navigateToMaterialList(context, "ΟΛΑ"),
                );
              }
              final category = categories[index - 1];
              return _PremiumCategoryCard(
                name: category,
                icon: _getIconForCategory(category),
                color: _getColorForCategory(category),
                onClick: () => _navigateToMaterialList(context, category),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToMaterialList(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialListScreen(
          category: category,
          locationType: widget.locationType,
          projectId: widget.projectId,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name) {
      case "ΧΡΩΜΑΤΑ": return Icons.palette_rounded;
      case "ΑΝΑΛΩΣΙΜΑ": return Icons.inventory_2_rounded;
      case "ΥΔΡΑΥΛΙΚΑ": return Icons.water_drop_rounded;
      case "ΗΛΕΚΤΡΙΚΑ": return Icons.bolt_rounded;
      case "ΓΥΨΟΣΑΝΙΔΕΣ": return Icons.layers_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getColorForCategory(String name) {
    switch (name) {
      case "ΧΡΩΜΑΤΑ": return const Color(0xFFE91E63);
      case "ΑΝΑΛΩΣΙΜΑ": return const Color(0xFF607D8B);
      case "ΓΥΨΟΣΑΝΙΔΕΣ": return const Color(0xFF4361EE);
      case "ΣΟΒΑ": return const Color(0xFF795548);
      case "ΥΔΡΑΥΛΙΚΑ": return const Color(0xFF2196F3);
      case "ΗΛΕΚΤΡΙΚΑ": return const Color(0xFFFFC107);
      default: return Colors.blue;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΝΕΑ ΚΑΤΗΓΟΡΙΑ ΥΛΙΚΩΝ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Όνομα Κατηγορίας", border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).addMaterialCategory(controller.text.toUpperCase());
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

class _PremiumCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;

  const _PremiumCategoryCard({required this.name, required this.icon, required this.color, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onClick,
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Color(0xFF1E293B)), 
              textAlign: TextAlign.center
            ),
          ),
        ],
      ),
    );
  }
}
