import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedCategory = "ΟΛΑ";
  final List<String> _categories = ["ΟΛΑ", "ΜΠΑΝΙΑ", "ΚΟΥΖΙΝΕΣ", "ΓΥΨΟΣΑΝΙΔΕΣ", "ΒΑΨΙΜΑΤΑ", "ΔΑΠΕΔΑ", "ΕΞΩΤΕΡΙΚΟΙ ΧΩΡΟΙ"];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΨΗΦΙΑΚΟ PORTFOLIO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPhoto,
        label: const Text("ΠΡΟΣΘΗΚΗ ΦΩΤΟ"),
        icon: const Icon(Icons.add_a_photo_rounded),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<List<PortfolioItem>>(
              future: provider.getPortfolio(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allItems = snapshot.data!;
                final items = _selectedCategory == "ΟΛΑ" 
                    ? allItems 
                    : allItems.where((i) => i.category == _selectedCategory).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        const Text("Καμία φωτογραφία σε αυτή την κατηγορία", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _PortfolioCard(
                    item: items[index],
                    onDelete: () => _deleteItem(items[index].id),
                    onTap: () => _showGallery(items, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.white : Colors.blueGrey)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: Colors.blue,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  void _addPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    String? category = await _showCategoryPicker();
    if (category == null) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    await provider.addPortfolioItem(PortfolioItem(
      uri: image.path,
      category: category,
    ));
    setState(() {});
  }

  Future<String?> _showCategoryPicker() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΕΠΙΛΟΓΗ ΚΑΤΗΓΟΡΙΑΣ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.where((c) => c != "ΟΛΑ").map((c) => ListTile(
            title: Text(c),
            onTap: () => Navigator.pop(context, c),
          )).toList(),
        ),
      ),
    );
  }

  void _deleteItem(int id) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    await provider.deletePortfolioItem(id);
    setState(() {});
  }

  void _showGallery(List<PortfolioItem> items, int initialIndex) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => _GalleryViewer(items: items, initialIndex: initialIndex),
    ));
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PortfolioCard({required this.item, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(File(item.uri), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.category, 
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onDelete, 
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.black12),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryViewer extends StatelessWidget {
  final List<PortfolioItem> items;
  final int initialIndex;
  const _GalleryViewer({required this.items, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.file(File(items[index].uri), fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
