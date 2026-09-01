import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectChecklistScreen extends StatefulWidget {
  final int projectId;
  const ProjectChecklistScreen({super.key, required this.projectId});

  @override
  State<ProjectChecklistScreen> createState() => _ProjectChecklistScreenState();
}

class _ProjectChecklistScreenState extends State<ProjectChecklistScreen> {
  final List<String> _defaultItems = [
    "ΚΑΘΑΡΙΣΜΟΣ ΧΩΡΟΥ",
    "ΕΛΕΓΧΟΣ ΠΡΙΖΩΝ & ΔΙΑΚΟΠΤΩΝ",
    "ΕΛΕΓΧΟΣ ΥΔΡΑΥΛΙΚΩΝ (ΔΙΑΡΡΟΕΣ)",
    "ΣΤΟΚΑΡΙΣΜΑ & ΦΙΝΙΡΙΣΜΑ",
    "ΕΛΕΓΧΟΣ ΚΟΥΦΩΜΑΤΩΝ",
    "ΠΑΡΑΔΟΣΗ ΚΛΕΙΔΙΩΝ",
    "ΦΩΤΟΓΡΑΦΙΣΗ ΟΛΟΚΛΗΡΩΣΗΣ"
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΛΙΣΤΑ ΠΟΙΟΤΙΚΟΥ ΕΛΕΓΧΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        label: const Text("ΝΕΟ ΣΤΟΙΧΕΙΟ"),
        icon: const Icon(Icons.playlist_add_rounded),
      ),
      body: FutureBuilder<List<ProjectChecklistItem>>(
        future: provider.getProjectChecklist(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text("Δεν υπάρχουν στοιχεία ελέγχου.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _initDefaultItems(provider),
                    child: const Text("ΦΟΡΤΩΣΗ ΠΡΟΚΑΘΟΡΙΣΜΕΝΩΝ"),
                  ),
                ],
              ),
            );
          }

          final completedCount = items.where((i) => i.isChecked).length;
          final progress = items.isEmpty ? 0.0 : completedCount / items.length;

          return Column(
            children: [
              _buildProgressHeader(completedCount, items.length, progress),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ChecklistCard(
                      item: item,
                      onToggle: (val) => provider.updateChecklistItem(ProjectChecklistItem(
                        id: item.id,
                        projectId: item.projectId,
                        title: item.title,
                        isChecked: val!,
                      )).then((_) => setState(() {})),
                      onDelete: () => provider.deleteChecklistItem(item.id).then((_) => setState(() {})),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ΠΡΟΟΔΟΣ ΕΛΕΓΧΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              Text("$completed / $total", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            color: progress >= 1.0 ? Colors.green : Colors.blue,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΠΡΟΣΘΗΚΗ ΕΛΕΓΧΟΥ"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Περιγραφή")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Provider.of<ProjectProvider>(context, listen: false).addChecklistItem(ProjectChecklistItem(
                  projectId: widget.projectId,
                  title: controller.text.toUpperCase(),
                ));
                if (context.mounted) Navigator.pop(context);
                setState(() {});
              }
            }, 
            child: const Text("ΠΡΟΣΘΗΚΗ"),
          ),
        ],
      ),
    );
  }

  void _initDefaultItems(ProjectProvider provider) async {
    for (var title in _defaultItems) {
      await provider.addChecklistItem(ProjectChecklistItem(
        projectId: widget.projectId,
        title: title,
      ));
    }
    setState(() {});
  }
}

class _ChecklistCard extends StatelessWidget {
  final ProjectChecklistItem item;
  final Function(bool?) onToggle;
  final VoidCallback onDelete;

  const _ChecklistCard({required this.item, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.isChecked ? Colors.green.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked, 
          onChanged: onToggle,
          activeColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 13,
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : const Color(0xFF1E293B),
          )
        ),
        trailing: IconButton(onPressed: onDelete, icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.black12)),
      ),
    );
  }
}
