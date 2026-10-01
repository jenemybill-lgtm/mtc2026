import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class AllProjectChecklistsScreen extends StatefulWidget {
  const AllProjectChecklistsScreen({super.key});

  @override
  State<AllProjectChecklistsScreen> createState() => _AllProjectChecklistsScreenState();
}

class _AllProjectChecklistsScreenState extends State<AllProjectChecklistsScreen> {
  late Future<List<ProjectChecklistItem>> _checklistFuture;

  @override
  void initState() {
    super.initState();
    _refreshChecklists();
  }

  void _refreshChecklists() {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    _checklistFuture = provider.getAllProjectChecklists();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text("ΛΙΣΤΑ ΕΡΓΑΣΙΩΝ (ΟΛΑ ΤΑ ΕΡΓΑ)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChecklistDialog(context, provider),
        label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<ProjectChecklistItem>>(
            future: _checklistFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.teal));
              }

              final checklist = snapshot.data ?? [];
              final completedCount = checklist.where((c) => c.isChecked).length;
              final totalCount = checklist.length;
              final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              final proj = provider.projects.firstWhere(
                                (p) => p.id == item.projectId,
                                orElse: () => Project(name: "ΕΡΓΟ #${item.projectId}", clientName: "", address: ""),
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.25), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onLongPress: () => _showChecklistOptionsModal(context, provider, item, proj),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: item.isChecked,
                                            activeColor: Colors.teal,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            onChanged: (v) async {
                                              await provider.updateChecklistItem(item.copyWith(isChecked: v!));
                                              setState(() { _refreshChecklists(); });
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                                    color: item.isChecked ? Colors.grey : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                                  ),
                                                  child: Text(
                                                    proj.name.toUpperCase(),
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.teal),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                            onPressed: () => _showChecklistOptionsModal(context, provider, item, proj),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddChecklistDialog(BuildContext context, ProjectProvider provider, {ProjectChecklistItem? itemToEdit}) {
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν διαθέσιμα έργα. Παρακαλώ δημιουργήστε πρώτα ένα έργο.")),
      );
      return;
    }

    final controller = TextEditingController(text: itemToEdit?.title ?? "");
    int selectedProjectId = itemToEdit?.projectId ?? provider.projects.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: PremiumHeader(
            title: itemToEdit == null ? "ΝΕΑ ΕΡΓΑΣΙΑ CHECKLIST" : "ΕΠΕΞΕΡΓΑΣΙΑ ΕΡΓΑΣΙΑΣ",
            icon: Icons.playlist_add_check_rounded,
            color: Colors.teal,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedProjectId,
                  decoration: InputDecoration(
                    labelText: "Επιλογή Έργου",
                    prefixIcon: const Icon(Icons.business_center_rounded, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: provider.projects.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedProjectId = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Περιγραφή Εργασίας",
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
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
                      projectId: selectedProjectId,
                      title: title,
                    ));
                  } else {
                    await provider.updateChecklistItem(itemToEdit.copyWith(
                      projectId: selectedProjectId,
                      title: title,
                    ));
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() { _refreshChecklists(); });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChecklistOptionsModal(BuildContext context, ProjectProvider provider, ProjectChecklistItem item, Project proj) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        proj.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.teal),
                      ),
                    ],
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
                _showAddChecklistDialog(context, provider, itemToEdit: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text("Διαγραφή Εργασίας", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChecklistConfirm(context, provider, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChecklistConfirm(BuildContext context, ProjectProvider provider, ProjectChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή την εργασία;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          TextButton(
            onPressed: () async {
              await provider.deleteChecklistItem(item.id, item.projectId);
              if (context.mounted) Navigator.pop(context);
              setState(() { _refreshChecklists(); });
            },
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
