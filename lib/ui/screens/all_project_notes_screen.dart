import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class AllProjectNotesScreen extends StatefulWidget {
  const AllProjectNotesScreen({super.key});

  @override
  State<AllProjectNotesScreen> createState() => _AllProjectNotesScreenState();
}

class _AllProjectNotesScreenState extends State<AllProjectNotesScreen> {
  late Future<List<ProjectNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _refreshNotes() {
    _notesFuture = DatabaseHelper().getAllProjectNotes();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text("ΟΛΕΣ ΟΙ ΣΗΜΕΙΩΣΕΙΣ ΕΡΓΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context, provider),
        label: const Text("ΝΕΑ ΣΗΜΕΙΩΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.note_add_rounded),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<ProjectNote>>(
            future: _notesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
              }

              final notes = snapshot.data ?? [];

              if (notes.isEmpty) {
                return const Center(
                  child: Text(
                    "Δεν υπάρχουν καταγεγραμμένες σημειώσεις στα έργα.",
                    style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return _buildNoteCardItem(context, notes[index], provider);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCardItem(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note.dateAdded));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showNoteOptions(context, note, provider),
          onLongPress: () => _showNoteOptions(context, note, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          proj.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(proj.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                ),
                const SizedBox(width: 8),
                const Text("ΕΠΙΛΟΓΕΣ ΣΗΜΕΙΩΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              ),
              title: const Text("Επεξεργασία Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(context, provider, noteToEdit: note);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: const Text("Διαγραφή Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await provider.deleteProjectNote(note.projectId, note.id);
                setState(() { _refreshNotes(); });
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, ProjectProvider provider, {ProjectNote? noteToEdit}) {
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν έργα για προσθήκη σημείωσης.")),
      );
      return;
    }

    int? selectedProjectId = noteToEdit?.projectId ?? provider.projects.first.id;
    final noteController = TextEditingController(text: noteToEdit?.content ?? "");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: PremiumHeader(
            title: noteToEdit == null ? "ΝΕΑ ΣΗΜΕΙΩΣΗ ΕΡΓΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΣΗΜΕΙΩΣΗΣ",
            icon: noteToEdit == null ? Icons.note_add_rounded : Icons.edit_note_rounded,
            color: const Color(0xFFFF9800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: selectedProjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Επιλογή Έργου",
                  prefixIcon: Icon(Icons.business_center_rounded),
                  border: OutlineInputBorder(),
                ),
                items: provider.projects.map((p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedProjectId = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Περιεχόμενο Σημείωσης",
                  hintText: "Γράψτε εδώ τη σημείωσή σας...",
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = noteController.text.trim();
                if (content.isNotEmpty && selectedProjectId != null) {
                  if (noteToEdit == null) {
                    await provider.addProjectNote(
                      ProjectNote(
                        projectId: selectedProjectId!,
                        content: content,
                        dateAdded: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                  } else {
                    await provider.updateProjectNote(
                      noteToEdit.copyWith(
                        projectId: selectedProjectId!,
                        content: content,
                      ),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() { _refreshNotes(); });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: Text(noteToEdit == null ? "ΠΡΟΣΘΗΚΗ" : "ΑΠΟΘΗΚΕΥΣΗ", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}