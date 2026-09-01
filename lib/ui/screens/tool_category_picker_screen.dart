import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/screens/global_tools_screen.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ToolCategoryPickerScreen extends StatefulWidget {
  final String title;
  final String locationType;
  final int? locationId;

  const ToolCategoryPickerScreen({super.key, required this.title, required this.locationType, this.locationId});

  @override
  State<ToolCategoryPickerScreen> createState() => _ToolCategoryPickerScreenState();
}

class _ToolCategoryPickerScreenState extends State<ToolCategoryPickerScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final categories = provider.toolCategories;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
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
                return _CategoryCard(
                  name: "ΟΛΑ ΤΑ ΕΡΓΑΛΕΙΑ",
                  icon: Icons.apps_rounded,
                  color: Colors.blue,
                  onClick: () => _navigateToGlobalTools(context, "ΟΛΑ"),
                );
              }
              final category = categories[index - 1];
              return _CategoryCard(
                name: category,
                icon: _getIconForCategory(category),
                color: _getColorForCategory(category),
                onClick: () => _navigateToGlobalTools(context, category),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToGlobalTools(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalToolsScreen(
          category: category,
          locationType: widget.locationType,
          projectId: widget.locationId,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name) {
      case "ΔΡΑΠΑΝΑ": return Icons.construction_rounded;
      case "ΧΕΙΡΟΣ": return Icons.handyman_rounded;
      case "ΣΟΒΑ": return Icons.home_work_rounded;
      case "ΚΟΠΗΣ": return Icons.content_cut_rounded;
      case "ΠΛΑΚΑΚΙΑ ΜΑΡΜΑΡΑ": return Icons.grid_view_rounded;
      default: return Icons.build_rounded;
    }
  }

  Color _getColorForCategory(String name) {
    switch (name) {
      case "ΔΡΑΠΑΝΑ": return const Color(0xFF3A0CA3);
      case "ΧΕΙΡΟΣ": return const Color(0xFF7209B7);
      case "ΚΟΠΗΣ": return Colors.redAccent;
      default: return Colors.blue;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΝΕΑ ΚΑΤΗΓΟΡΙΑ ΕΡΓΑΛΕΙΩΝ"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Όνομα Κατηγορίας", border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).addToolCategory(controller.text.toUpperCase());
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

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;

  const _CategoryCard({required this.name, required this.icon, required this.color, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onClick,
      accentColor: color,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), 
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            name, 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: Color(0xFF1E293B)), 
            textAlign: TextAlign.center
          ),
        ],
      ),
    );
  }
}
