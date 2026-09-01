import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/pdf_generator.dart';

class ProjectTimelineScreen extends StatefulWidget {
  final int projectId;
  const ProjectTimelineScreen({super.key, required this.projectId});

  @override
  State<ProjectTimelineScreen> createState() => _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends State<ProjectTimelineScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ΧΡΟΝΟΔΙΑΓΡΑΜΜΑ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Έκδοση Αναφοράς Προόδου",
            onPressed: () => _generateProgressReport(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStageDialog(context),
        label: const Text("ΝΕΑ ΦΑΣΗ"),
        icon: const Icon(Icons.add),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: FutureBuilder<List<ProjectStageEntity>>(
            future: provider.getProjectStages(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final stages = snapshot.data!;

              if (stages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      const Text("Δεν έχει οριστεί χρονοδιάγραμμα.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  return _TimelineItem(
                    stage: stage,
                    isFirst: index == 0,
                    isLast: index == stages.length - 1,
                    onUpdate: (val) => provider.updateProjectStage(stage.copyWith(progress: val)),
                    onDelete: () => provider.deleteProjectStage(stage.id),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _generateProgressReport(BuildContext context, ProjectProvider provider) async {
    final stages = await provider.getProjectStages(widget.projectId);
    final photos = await provider.getProjectPhotos(widget.projectId);
    final project = provider.projects.firstWhere((p) => p.id == widget.projectId);

    if (context.mounted) {
      await PdfGenerator.generateAndShareProgressReport(
        project: project,
        stages: stages,
        photos: photos,
        settings: provider.settings,
      );
    }
  }

  void _showAddStageDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΠΡΟΣΘΗΚΗ ΦΑΣΗΣ"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Όνομα Φάσης (π.χ. Μπετά)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).addProjectStage(ProjectStageEntity(
                  projectId: widget.projectId,
                  name: controller.text,
                  progress: 0.0,
                  displayOrder: 0,
                ));
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

class _TimelineItem extends StatelessWidget {
  final ProjectStageEntity stage;
  final bool isFirst, isLast;
  final Function(double) onUpdate;
  final VoidCallback onDelete;

  const _TimelineItem({required this.stage, required this.isFirst, required this.isLast, required this.onUpdate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.blue.withValues(alpha: 0.2),
              ),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: stage.progress >= 1.0 ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(stage.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black12), onPressed: onDelete),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: stage.progress,
                            onChanged: onUpdate,
                            activeColor: stage.progress >= 1.0 ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("${(stage.progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
