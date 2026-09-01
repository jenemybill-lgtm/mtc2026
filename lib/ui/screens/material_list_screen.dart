import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class MaterialListScreen extends StatefulWidget {
  final String category;
  final String locationType;
  final int? projectId;

  const MaterialListScreen({super.key, required this.category, required this.locationType, this.projectId});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMaterialDialog(context),
        label: const Text("ΝΕΟ ΥΛΙΚΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: FutureBuilder<List<MaterialEntity>>(
            future: provider.getMaterials(widget.projectId, widget.locationType, widget.category),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final materials = snapshot.data!;
              if (materials.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
                        child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      const SizedBox(height: 24),
                      const Text("Δεν υπάρχουν υλικά", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 2.6 : 3.4,
                ),
                itemCount: materials.length,
                itemBuilder: (context, index) => _MaterialItemCardPremium(
                  material: materials[index],
                  onClick: () => _showMaterialDialog(context, material: materials[index]),
                  onDelete: () => _showDeleteConfirm(context, materials[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMaterialDialog(BuildContext context, {MaterialEntity? material}) {
    showDialog(
      context: context,
      builder: (context) => _MaterialEntryDialog(
        category: widget.category == "ΟΛΑ" ? "ΓΕΝΙΚΑ" : widget.category,
        locationType: widget.locationType,
        projectId: widget.projectId,
        initialMaterial: material,
        onConfirm: () => setState(() {}),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, MaterialEntity material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΥΛΙΚΟΥ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε το υλικό '${material.name}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<ProjectProvider>(context, listen: false).deleteMaterial(material.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MaterialItemCardPremium extends StatelessWidget {
  final MaterialEntity material;
  final VoidCallback onClick;
  final VoidCallback onDelete;

  const _MaterialItemCardPremium({required this.material, required this.onClick, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isShortage = material.quantity <= material.minStockThreshold && material.minStockThreshold > 0;
    final color = isShortage ? Colors.red : Colors.blue;

    return PremiumCard(
      onTap: onClick,
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(
              isShortage ? Icons.warning_rounded : (material.category == "ΧΡΩΜΑΤΑ" ? Icons.palette_rounded : Icons.inventory_2_rounded),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    material.name.toUpperCase(), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B), letterSpacing: 0.5)
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (isShortage) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Text("ΕΛΛΕΙΨΗ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      material.category, 
                      style: TextStyle(color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Text(
                  "${material.quantity.toStringAsFixed(1)} ${material.unit}", 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: -0.8)
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: onDelete, 
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black12), 
                padding: EdgeInsets.zero, 
                constraints: const BoxConstraints()
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialEntryDialog extends StatefulWidget {
  final String category;
  final String locationType;
  final int? projectId;
  final MaterialEntity? initialMaterial;
  final VoidCallback onConfirm;

  const _MaterialEntryDialog({required this.category, required this.locationType, this.projectId, this.initialMaterial, required this.onConfirm});

  @override
  State<_MaterialEntryDialog> createState() => _MaterialEntryDialogState();
}

class _MaterialEntryDialogState extends State<_MaterialEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _unitController;
  late TextEditingController _minStockController;
  late TextEditingController _colorCodeController;

  final List<String> _suggestedMaterials = [
    "ΤΣΙΜΕΝΤΟ", "ΑΜΜΟΣ", "ΜΑΡΜΑΡΟΣΚΟΝΗ", "ΑΣΒΕΣΤΗΣ", "ΚΟΛΛΑ ΠΛΑΚΙΔΙΩΝ", 
    "ΚΑΛΩΔΙΑ", "ΣΩΛΗΝΕΣ", "ΓΥΨΟΣΑΝΙΔΕΣ", "ΕΤΟΙΜΟ ΜΠΕΤΟ", "ΣΙΔΗΡΟΣ ΟΠΛΙΣΜΟΥ", 
    "ΧΡΩΜΑΤΑ", "ΑΣΤΑΡΙ", "ΠΛΑΚΑΚΙΑ", "ΜΑΡΜΑΡΑ", "ΚΟΛΛΑ ΓΥΨΟΣΑΝΙΔΑΣ"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialMaterial?.name ?? "");
    _qtyController = TextEditingController(text: widget.initialMaterial?.quantity.toString() ?? "1");
    _unitController = TextEditingController(text: widget.initialMaterial?.unit ?? "");
    _minStockController = TextEditingController(text: widget.initialMaterial?.minStockThreshold.toString() ?? "0");
    _colorCodeController = TextEditingController(text: widget.initialMaterial?.colorCode ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.initialMaterial == null ? "ΠΡΟΣΘΗΚΗ ΥΛΙΚΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΥΛΙΚΟΥ", style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.initialMaterial == null) ...[
              const Text("ΠΡΟΤΕΙΝΟΜΕΝΑ ΥΛΙΚΑ:", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedMaterials.map((m) => ActionChip(
                  label: Text(m, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
                  onPressed: () {
                    setState(() {
                      _nameController.text = m;
                      if (m.contains("ΤΣΙΜΕΝΤΟ") || m.contains("ΚΟΛΛΑ") || m.contains("ΑΣΒΕΣΤΗΣ")) _unitController.text = "σακί";
                      if (m == "ΑΜΜΟΣ" || m == "ΜΑΡΜΑΡΟΣΚΟΝΗ" || m == "ΕΤΟΙΜΟ ΜΠΕΤΟ") _unitController.text = "m³";
                      if (m == "ΚΑΛΩΔΙΑ" || m == "ΣΩΛΗΝΕΣ") _unitController.text = "m";
                      if (m.contains("ΣΙΔΗΡΟΣ")) _unitController.text = "kg";
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameController, 
              decoration: const InputDecoration(
                labelText: "Ονομασία Υλικού", 
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                hintText: "π.χ. ΤΣΙΜΕΝΤΟ ΤΙΤΑΝ",
              )
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _qtyController, decoration: const InputDecoration(labelText: "Ποσότητα", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _unitController, decoration: const InputDecoration(labelText: "Μονάδα", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), hintText: "π.χ. σακί"))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _minStockController, decoration: const InputDecoration(labelText: "Όριο Ειδοποίησης (min)", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), keyboardType: TextInputType.number),
            if (widget.category == "ΧΡΩΜΑΤΑ") ...[
              const SizedBox(height: 16),
              TextField(controller: _colorCodeController, decoration: const InputDecoration(labelText: "Κωδικός Χρώματος", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isNotEmpty) {
              final material = MaterialEntity(
                id: widget.initialMaterial?.id ?? 0,
                name: _nameController.text.toUpperCase(),
                category: widget.category,
                quantity: double.tryParse(_qtyController.text) ?? 1.0,
                unit: _unitController.text,
                locationType: widget.locationType,
                projectId: widget.projectId,
                minStockThreshold: double.tryParse(_minStockController.text) ?? 0.0,
                colorCode: _colorCodeController.text.isEmpty ? null : _colorCodeController.text,
              );
              if (widget.initialMaterial == null) {
                await Provider.of<ProjectProvider>(context, listen: false).addMaterial(material);
              } else {
                await Provider.of<ProjectProvider>(context, listen: false).updateMaterial(material);
              }
              widget.onConfirm();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("ΑΠΟΘΗΚΕΥΣΗ"),
        ),
      ],
    );
  }
}
