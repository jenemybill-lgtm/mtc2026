import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  final int projectId;
  const ProjectDocumentsScreen({super.key, required this.projectId});

  @override
  State<ProjectDocumentsScreen> createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ΕΓΓΡΑΦΑ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file_rounded), onPressed: _pickFiles),
        ],
      ),
      body: DropTarget(
        onDragDone: (details) => _handleDroppedFiles(details.files),
        onDragEntered: (details) => setState(() => _isDragging = true),
        onDragExited: (details) => setState(() => _isDragging = false),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
            decoration: BoxDecoration(
              color: _isDragging ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: _buildDocumentsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    final provider = Provider.of<ProjectProvider>(context);
    final docs = provider.currentProjectDocuments;

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text("Σύρετε αρχεία εδώ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Text("ή χρησιμοποιήστε το κουμπί ανέβασμα", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final file = File(doc.filePath);
        return _DocumentCard(
          doc: doc,
          onTap: () => OpenFile.open(doc.filePath),
          onDelete: () => _deleteFile(doc),
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    List<PlatformFile> result = await FilePicker.pickFiles();
    if (result.isNotEmpty) {
      for (var file in result) {
        if (file.path != null) await _saveFile(File(file.path!));
      }
      setState(() {});
    }
  }

  Future<void> _handleDroppedFiles(List<dynamic> droppedFiles) async {
    for (var dropped in droppedFiles) {
      await _saveFile(File(dropped.path));
    }
    setState(() => _isDragging = false);
  }

  Future<void> _saveFile(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${appDir.path}/documents/${widget.projectId}');
    if (!await projectDir.exists()) await projectDir.create(recursive: true);
    
    final fileName = p.basename(file.path);
    final destinationPath = '${projectDir.path}/$fileName';
    await file.copy(destinationPath);

    if (mounted) {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      await provider.addProjectDocument(ProjectDocument(
        projectId: widget.projectId,
        title: fileName,
        filePath: destinationPath,
        fileExtension: p.extension(fileName).replaceAll('.', '').toUpperCase(),
      ));
    }
  }

  Future<void> _deleteFile(ProjectDocument doc) async {
    final file = File(doc.filePath);
    if (await file.exists()) await file.delete();
    if (mounted) {
      await Provider.of<ProjectProvider>(context, listen: false).deleteProjectDocument(widget.projectId, doc.id);
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final ProjectDocument doc;
  final VoidCallback onTap, onDelete;

  const _DocumentCard({required this.doc, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final extension = doc.fileExtension;
    final file = File(doc.filePath);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _getColorForExt(extension).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(extension, style: TextStyle(color: _getColorForExt(extension), fontWeight: FontWeight.w900, fontSize: 10)),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(doc.dateAdded)), style: const TextStyle(fontSize: 10)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: onDelete),
      ),
    );
  }

  Color _getColorForExt(String ext) {
    switch (ext) {
      case "PDF": return Colors.red;
      case "XLSX": case "CSV": return Colors.green;
      case "JPG": case "PNG": return Colors.blue;
      default: return Colors.blueGrey;
    }
  }
}
