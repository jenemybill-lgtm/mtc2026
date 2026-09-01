import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectNotesScreen extends StatefulWidget {
  final Project project;

  const ProjectNotesScreen({super.key, required this.project});

  @override
  State<ProjectNotesScreen> createState() => _ProjectNotesScreenState();
}

class _ProjectNotesScreenState extends State<ProjectNotesScreen> {
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
    final notes = provider.currentProjectNotes;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΣΗΜΕΙΩΜΑΤΑΡΙΟ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 1)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context),
        label: const Text("ΝΕΑ ΣΗΜΕΙΩΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.note_add_rounded),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: notes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => _NoteCard(
                    note: notes[index],
                    onEdit: () => _showNoteDialog(context, note: notes[index]),
                    onDelete: () => _showDeleteConfirm(context, notes[index]),
                  ),
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
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.notes_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text("Δεν υπάρχουν σημειώσεις", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
          const Text("Κρατήστε γρήγορες σημειώσεις για το έργο", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {ProjectNote? note}) {
    final controller = TextEditingController(text: note?.content ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: PremiumHeader(
          title: note == null ? "ΝΕΑ ΣΗΜΕΙΩΣΗ" : "ΕΠΕΞΕΡΓΑΣΙΑ",
          icon: Icons.edit_note_rounded,
        ),
        content: TextField(
          controller: controller,
          maxLines: 8,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Γράψτε εδώ τη σημείωσή σας...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                if (note == null) {
                  provider.addProjectNote(ProjectNote(projectId: widget.project.id, content: controller.text.trim()));
                } else {
                  provider.updateProjectNote(note.copyWith(content: controller.text.trim()));
                }
                Navigator.pop(context);
              }
            },
            child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ProjectNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΣΗΜΕΙΩΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή τη σημείωση;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProjectProvider>(context, listen: false).deleteProjectNote(widget.project.id, note.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ProjectNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note.dateAdded));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        accentColor: Colors.blue,
        padding: const EdgeInsets.all(20),
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black12),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
