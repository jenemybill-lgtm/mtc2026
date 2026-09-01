import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/screens/sketch_drawing_screen.dart';

class ProjectSketchesScreen extends StatefulWidget {
  final int projectId;
  const ProjectSketchesScreen({super.key, required this.projectId});

  @override
  State<ProjectSketchesScreen> createState() => _ProjectSketchesScreenState();
}

class _ProjectSketchesScreenState extends State<ProjectSketchesScreen> {
  String _selectedFolder = "ΟΛΑ";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final project = provider.projects.firstWhere((p) => p.id == widget.projectId);
    final sketches = provider.currentProjectSketches;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΣΚΑΡΙΦΗΜΑΤΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeSelection(context),
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width > 900 ? 1000 : double.infinity),
          child: Column(
            children: [
              if (sketches.isNotEmpty) _buildFolderTabs(sketches),
              Expanded(
                child: sketches.isEmpty ? _buildEmptyState() : _buildSketchesGrid(sketches),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTabs(List sketches) {
    final folders = ["ΟΛΑ", ...sketches.map((s) => s.folder.toString()).toSet()];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: folders.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedFolder == f,
            onSelected: (v) => setState(() => _selectedFolder = f),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_rounded, size: 80, color: Colors.blue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text("Σκαριφήματα Έργου", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Δεν υπάρχουν ακόμα σχέδια.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSketchesGrid(List sketches) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final filtered = _selectedFolder == "ΟΛΑ" ? sketches : sketches.where((s) => s.folder == _selectedFolder).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _SketchCard(sketch: filtered[index]),
    );
  }

  void _showTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΝΕΟ ΣΧΕΔΙΟ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Επιλέξτε τον τύπο σχεδίασης:"),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SketchDrawingScreen(projectId: widget.projectId)));
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Column(children: [Icon(Icons.layers_rounded), Text("ΚΑΤΟΨΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => ElevationDrawingScreen(projectId: widget.projectId)));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Column(children: [Icon(Icons.view_quilt_rounded), Text("ΟΨΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchCard extends StatelessWidget {
  final ProjectSketch sketch;
  const _SketchCard({required this.sketch});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          if (sketch.imagePath.isNotEmpty && File(sketch.imagePath).existsSync())
            Positioned.fill(child: Image.file(File(sketch.imagePath), fit: BoxFit.cover))
          else
            const Positioned.fill(child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
          Positioned(
            top: 4, right: 4,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              radius: 14,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
                      content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτό το σχέδιο;"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
                        TextButton(
                          onPressed: () {
                            Provider.of<ProjectProvider>(context, listen: false).deleteProjectSketch(sketch.projectId, sketch.id);
                            Navigator.pop(context);
                          },
                          child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sketch.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10), maxLines: 1),
                  Text(sketch.folder, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
