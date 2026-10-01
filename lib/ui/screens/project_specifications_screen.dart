import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectSpecificationsScreen extends StatefulWidget {
  final Project project;

  const ProjectSpecificationsScreen({super.key, required this.project});

  @override
  State<ProjectSpecificationsScreen> createState() => _ProjectSpecificationsScreenState();
}

class _ProjectSpecificationsScreenState extends State<ProjectSpecificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjectData(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final specs = provider.projectSpecs; // We will add this to provider
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Group specs by category
    final Map<String, List<ProjectSpecificationEntity>> groupedSpecs = {};
    for (var spec in specs) {
      if (!groupedSpecs.containsKey(spec.category)) {
        groupedSpecs[spec.category] = [];
      }
      groupedSpecs[spec.category]!.add(spec);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΤΑΥΤΟΤΗΤΑ ΥΛΙΚΩΝ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 1)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSpecDialog(context, provider),
        label: const Text("ΝΕΟ ΥΛΙΚΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: specs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: groupedSpecs.length,
                  itemBuilder: (context, index) {
                    final category = groupedSpecs.keys.elementAt(index);
                    final categorySpecs = groupedSpecs[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.category_rounded, color: Colors.teal, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.teal, letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        ...categorySpecs.map((spec) => _SpecCard(
                          spec: spec,
                          onEdit: () => _showSpecDialog(context, provider, specToEdit: spec),
                          onDelete: () => _showDeleteConfirm(context, provider, spec),
                        )),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.verified_rounded, size: 64, color: Colors.teal.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text("Δεν βρέθηκαν καταχωρήσεις υλικών", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text("Προσθέστε χρώματα, πλακάκια, είδη υγιεινής κ.α.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  void _showSpecDialog(BuildContext context, ProjectProvider provider, {ProjectSpecificationEntity? specToEdit}) {
    final catController = TextEditingController(text: specToEdit?.category ?? "");
    final nameController = TextEditingController(text: specToEdit?.name ?? "");
    final brandController = TextEditingController(text: specToEdit?.brandCode ?? "");
    final supplierController = TextEditingController(text: specToEdit?.supplier ?? "");
    final notesController = TextEditingController(text: specToEdit?.notes ?? "");

    final predefinedCategories = ["ΧΡΩΜΑΤΑ", "ΠΛΑΚΑΚΙΑ", "ΕΙΔΗ ΥΓΙΕΙΝΗΣ", "ΚΟΥΦΩΜΑΤΑ", "ΗΛΕΚΤΡΟΛΟΓΙΚΟ ΥΛΙΚΟ", "ΥΔΡΑΥΛΙΚΑ", "ΞΥΛΟΥΡΓΙΚΑ", "ΑΛΛΟ"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: PremiumHeader(
            title: specToEdit == null ? "ΝΕΑ ΤΑΥΤΟΤΗΤΑ ΥΛΙΚΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ",
            icon: Icons.verified_rounded,
            color: Colors.teal,
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: catController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return predefinedCategories;
                      }
                      return predefinedCategories.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      catController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      if (catController.text.isNotEmpty && controller.text.isEmpty) {
                         controller.text = catController.text;
                      }
                      catController.addListener(() {
                        if (controller.text != catController.text) {
                          catController.text = controller.text;
                        }
                      });
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          labelText: "Κατηγορία (π.χ. ΧΡΩΜΑΤΑ, ΠΛΑΚΑΚΙΑ)",
                          prefixIcon: const Icon(Icons.category_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: InputDecoration(labelText: "Περιγραφή (π.χ. Χρώμα Σαλονιού)", prefixIcon: const Icon(Icons.description_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                  const SizedBox(height: 12),
                  TextField(controller: brandController, decoration: InputDecoration(labelText: "Μάρκα / Κωδικός (π.χ. Vivechrom 10YY...)", prefixIcon: const Icon(Icons.qr_code_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                  const SizedBox(height: 12),
                  TextField(controller: supplierController, decoration: InputDecoration(labelText: "Προμηθευτής (Προαιρετικό)", prefixIcon: const Icon(Icons.store_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(labelText: "Σημειώσεις (Προαιρετικό)", prefixIcon: const Icon(Icons.notes_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final cat = catController.text.trim();
                final name = nameController.text.trim();
                if (cat.isNotEmpty && name.isNotEmpty) {
                  final spec = ProjectSpecificationEntity(
                    id: specToEdit?.id ?? 0,
                    projectId: widget.project.id,
                    category: cat.toUpperCase(),
                    name: name,
                    brandCode: brandController.text.trim(),
                    supplier: supplierController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                  
                  if (specToEdit == null) {
                    await provider.addProjectSpec(spec);
                  } else {
                    await provider.updateProjectSpec(spec);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ProjectProvider provider, ProjectSpecificationEntity spec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΥΛΙΚΟΥ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε την καταχώρηση '${spec.name}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteProjectSpec(spec.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final ProjectSpecificationEntity spec;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SpecCard({required this.spec, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(spec.dateAdded));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spec.name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                          if (spec.brandCode.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.qr_code_rounded, size: 10, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text(spec.brandCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.teal),
                          tooltip: "Επεξεργασία",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                          tooltip: "Διαγραφή",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (spec.supplier.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.store_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(spec.supplier, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                if (spec.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(spec.notes, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
