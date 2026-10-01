import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectChecklistScreen extends StatefulWidget {
  final Project project;

  const ProjectChecklistScreen({super.key, required this.project});

  @override
  State<ProjectChecklistScreen> createState() => _ProjectChecklistScreenState();
}

class _ProjectChecklistScreenState extends State<ProjectChecklistScreen> {
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
    final checklist = provider.projectChecklists.where((c) => c.projectId == widget.project.id).toList();
    final completedCount = checklist.where((c) => c.isChecked).length;
    final totalCount = checklist.length;
    final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΛΙΣΤΑ ΕΛΕΓΧΟΥ (CHECKLIST)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 1)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, provider),
        label: const Text("ΝΕΟ ΤΑΣΚ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              PremiumCard(
                accentColor: Colors.teal,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ΠΡΟΟΔΟΣ ΕΡΓΑΣΙΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.teal)),
                        Text("$completedCount / $totalCount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: checklist.isEmpty
                    ? const Center(
                        child: Text(
                          "Δεν υπάρχουν εργασίες στη λίστα ελέγχου.",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: checklist.length,
                        itemBuilder: (context, index) {
                          final item = checklist[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.teal.withValues(alpha: 0.25), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onLongPress: () => _showTaskOptionsModal(context, provider, item),
                              leading: Checkbox(
                                value: item.isChecked,
                                activeColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (v) async {
                                  await provider.updateChecklistItem(item.copyWith(isChecked: v!));
                                },
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                  color: item.isChecked ? Colors.grey : Colors.black87,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                onPressed: () => _showTaskOptionsModal(context, provider, item),
                              ),
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

  void _showTaskOptionsModal(BuildContext context, ProjectProvider provider, ProjectChecklistItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text("Επεξεργασία Εργασίας", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showAddDialog(context, provider, itemToEdit: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text("Διαγραφή Εργασίας", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, provider, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, ProjectProvider provider, {ProjectChecklistItem? itemToEdit}) {
    final controller = TextEditingController(text: itemToEdit?.title ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: PremiumHeader(
          title: itemToEdit == null ? "ΝΕΑ ΕΡΓΑΣΙΑ CHECKLIST" : "ΕΠΕΞΕΡΓΑΣΙΑ",
          icon: Icons.playlist_add_check_rounded,
          color: Colors.teal,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Περιγραφή Εργασίας",
            prefixIcon: const Icon(Icons.edit_note_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                if (itemToEdit == null) {
                  await provider.addChecklistItem(ProjectChecklistItem(
                    projectId: widget.project.id,
                    title: title,
                  ));
                } else {
                  await provider.updateChecklistItem(itemToEdit.copyWith(title: title));
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ProjectProvider provider, ProjectChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή την εγγραφή από το checklist;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          TextButton(
            onPressed: () async {
              await provider.deleteChecklistItem(item.id, widget.project.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
