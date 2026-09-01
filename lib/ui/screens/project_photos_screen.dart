import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectPhotosScreen extends StatefulWidget {
  final int projectId;
  const ProjectPhotosScreen({super.key, required this.projectId});

  @override
  State<ProjectPhotosScreen> createState() => _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState extends State<ProjectPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedFolder = "ΓΕΝΙΚΑ";

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΦΩΤΟΓΡΑΦΙΕΣ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_rounded, color: Colors.blue),
            onPressed: () => _showCreateFolderDialog(context),
            tooltip: "Νέος Φάκελος",
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_a_photo_rounded),
      ),
      body: FutureBuilder<List<ProjectPhotoEntity>>(
        future: provider.getProjectPhotos(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final allPhotos = snapshot.data!;
          final folders = allPhotos.map((p) => p.folderName).toSet().toList()..sort();
          if (!folders.contains("ΓΕΝΙΚΑ")) folders.add("ΓΕΝΙΚΑ");
          
          final displayedPhotos = allPhotos.where((p) => p.folderName == _selectedFolder).toList();

          return Column(
            children: [
              _buildFolderBar(folders),
              Expanded(
                child: displayedPhotos.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 5 : 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: displayedPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = displayedPhotos[index];
                          return _PhotoItem(
                            photo: photo,
                            onTap: () => _viewFullScreen(context, photo),
                            onLongPress: () => _showPhotoOptions(context, photo, folders, allPhotos),
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

  Widget _buildFolderBar(List<String> folders) {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          final isSelected = folder == _selectedFolder;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(folder, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.white : Colors.blueGrey)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFolder = folder),
              backgroundColor: Colors.blueGrey.withValues(alpha: 0.05),
              selectedColor: Colors.blue,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text("Δεν βρέθηκαν φωτογραφίες σε αυτόν τον φάκελο", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _viewFullScreen(BuildContext context, ProjectPhotoEntity photo) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
        body: Center(child: InteractiveViewer(child: Image.file(File(photo.uri)))),
      ),
    ));
  }

  void _showPhotoOptions(BuildContext context, ProjectPhotoEntity photo, List<String> folders, List<ProjectPhotoEntity> allPhotos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.drive_file_move_rounded, color: Colors.blue),
            title: const Text("Μεταφορά σε Φάκελο", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _showMoveToFolderDialog(context, photo, folders);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded, color: Colors.orange),
            title: const Text("Αλλαγή Ημερομηνίας", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _changePhotoDate(context, photo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_rounded, color: Colors.teal),
            title: const Text("Συνδυασμός (Πριν/Μετά)", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _combinePhotos(context, photo, allPhotos);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text("Διαγραφή", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _deletePhoto(photo.id);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, ProjectPhotoEntity photo, List<String> folders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΕΠΙΛΟΓΗ ΦΑΚΕΛΟΥ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: folders.map((f) => ListTile(
            title: Text(f),
            onTap: () async {
              await Provider.of<ProjectProvider>(context, listen: false).updatePhoto(ProjectPhotoEntity(
                id: photo.id,
                projectId: photo.projectId,
                uri: photo.uri,
                description: photo.description,
                dateAdded: photo.dateAdded,
                folderName: f,
              ));
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
          )).toList(),
        ),
      ),
    );
  }

  void _changePhotoDate(BuildContext context, ProjectPhotoEntity photo) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(photo.dateAdded),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && context.mounted) {
      await Provider.of<ProjectProvider>(context, listen: false).updatePhoto(ProjectPhotoEntity(
        id: photo.id,
        projectId: photo.projectId,
        uri: photo.uri,
        description: photo.description,
        dateAdded: date.millisecondsSinceEpoch,
        folderName: photo.folderName,
      ));
      setState(() {});
    }
  }

  void _combinePhotos(BuildContext context, ProjectPhotoEntity photoA, List<ProjectPhotoEntity> allPhotos) {
    final others = allPhotos.where((p) => p.id != photoA.id).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const PremiumHeader(title: "ΕΠΙΛΟΓΗ 2ης ΦΩΤΟΓΡΑΦΙΑΣ", icon: Icons.add_photo_alternate_rounded),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: others.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showComparison(context, photoA, others[index]);
                  },
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(others[index].uri), fit: BoxFit.cover)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComparison(BuildContext context, ProjectPhotoEntity a, ProjectPhotoEntity b) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text("ΠΡΙΝ & ΜΕΤΑ"), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
          body: Column(
            children: [
              Expanded(child: Stack(children: [Positioned.fill(child: Image.file(File(a.uri), fit: BoxFit.contain)), Positioned(top: 10, left: 10, child: _label("ΠΡΙΝ"))])),
              const Divider(height: 2, color: Colors.white, thickness: 2),
              Expanded(child: Stack(children: [Positioned.fill(child: Image.file(File(b.uri), fit: BoxFit.contain)), Positioned(top: 10, left: 10, child: _label("ΜΕΤΑ"))])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)));

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΝΕΟΣ ΦΑΚΕΛΟΣ"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Όνομα Φακέλου")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              setState(() => _selectedFolder = controller.text.toUpperCase());
              Navigator.pop(context);
            }
          }, child: const Text("ΔΗΜΙΟΥΡΓΙΑ")),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) await photosDir.create();

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(photosDir.path, fileName);
      await File(image.path).copy(savedPath);

      final photo = ProjectPhotoEntity(
        projectId: widget.projectId,
        uri: savedPath,
        folderName: _selectedFolder,
      );

      await Provider.of<ProjectProvider>(context, listen: false).addPhoto(photo);
      setState(() {});
    }
  }

  Future<void> _deletePhoto(int id) async {
    await Provider.of<ProjectProvider>(context, listen: false).deletePhoto(id);
    setState(() {});
  }
}

class _PhotoItem extends StatelessWidget {
  final ProjectPhotoEntity photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoItem({required this.photo, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(child: Image.file(File(photo.uri), fit: BoxFit.cover)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, Colors.black54], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Text(
                    DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(photo.dateAdded)),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
