import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/utils/excel_exporter.dart';

class GlobalToolsScreen extends StatefulWidget {
  final String category;
  final String locationType;
  final int? projectId;

  const GlobalToolsScreen({super.key, required this.category, required this.locationType, this.projectId});

  @override
  State<GlobalToolsScreen> createState() => _GlobalToolsScreenState();
}

class _GlobalToolsScreenState extends State<GlobalToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text(widget.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () async {
              final tools = await provider.getTools(widget.projectId, widget.locationType, widget.category);
              await PdfGenerator.generateAndShareToolList(tools: tools, settings: provider.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () async {
              final tools = await provider.getTools(widget.projectId, widget.locationType, widget.category);
              await ExcelExporter.exportTools(tools);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showToolDialog(context),
        label: const Text("ΝΕΟ ΕΡΓΑΛΕΙΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: FutureBuilder<List<Tool>>(
            future: provider.getTools(widget.projectId, widget.locationType, widget.category),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final tools = snapshot.data!;
              if (tools.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
                        child: Icon(Icons.handyman_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      const SizedBox(height: 24),
                      const Text("Δεν υπάρχουν εργαλεία", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 2.6 : 3.2,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) => _ToolItemCardPremium(
                  tool: tools[index],
                  onClick: () => _showToolDialog(context, tool: tools[index]),
                  onDelete: () => _showDeleteConfirm(context, tools[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showToolDialog(BuildContext context, {Tool? tool}) {
    showDialog(
      context: context,
      builder: (context) => _ToolEntryDialog(
        category: widget.category == "ΟΛΑ" ? "ΓΕΝΙΚΑ" : widget.category,
        locationType: widget.locationType,
        locationId: widget.projectId ?? 0,
        initialTool: tool,
        onConfirm: () => setState(() {}),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Tool tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΕΡΓΑΛΕΙΟΥ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε το εργαλείο '${tool.name}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<ProjectProvider>(context, listen: false).deleteTool(tool.id);
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

class _ToolItemCardPremium extends StatelessWidget {
  final Tool tool;
  final VoidCallback onClick;
  final VoidCallback onDelete;

  const _ToolItemCardPremium({required this.tool, required this.onClick, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onClick,
      accentColor: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.blue.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tool.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(tool.category, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 8)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getLocationText(tool), 
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E293B).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                child: Text("x${tool.quantity.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
              ),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.black12), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocationText(Tool tool) {
    final customName = tool.customLocationName;
    switch (tool.locationType) {
      case "WAREHOUSE": return "ΑΠΟΘΗΚΗ";
      case "VAN": return "ΒΑΝ";
      case "PROJECT": return (customName != null && customName.isNotEmpty) ? customName.toUpperCase() : "ΕΡΓΟ";
      default: return "";
    }
  }
}

class _ToolEntryDialog extends StatefulWidget {
  final String category;
  final String locationType;
  final int locationId;
  final Tool? initialTool;
  final VoidCallback onConfirm;

  const _ToolEntryDialog({required this.category, required this.locationType, required this.locationId, this.initialTool, required this.onConfirm});

  @override
  State<_ToolEntryDialog> createState() => _ToolEntryDialogState();
}

class _ToolEntryDialogState extends State<_ToolEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _commentsController;
  
  late String _selectedLocationType;
  late int _selectedLocationId;
  String _customLocationName = "";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialTool?.name ?? "");
    _qtyController = TextEditingController(text: widget.initialTool?.quantity.toInt().toString() ?? "1");
    _commentsController = TextEditingController(text: widget.initialTool?.comments ?? "");
    
    // Default to provided location unless it's "TOTAL", then default to WAREHOUSE or initial tool's location
    if (widget.locationType == "TOTAL") {
       _selectedLocationType = widget.initialTool?.locationType ?? "WAREHOUSE";
       _selectedLocationId = widget.initialTool?.locationId ?? 0;
       _customLocationName = widget.initialTool?.customLocationName ?? "";
    } else {
       _selectedLocationType = widget.locationType;
       _selectedLocationId = widget.locationId;
       _customLocationName = widget.initialTool?.customLocationName ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final projects = provider.projects;
    const color = Color(0xFF4361EE);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.initialTool == null ? Icons.handyman_rounded : Icons.edit_rounded, color: color, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.initialTool == null ? "ΠΡΟΣΘΗΚΗ ΕΡΓΑΛΕΙΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    _buildMinimalTextField(_nameController, "Όνομα Εργαλείου", Icons.edit_rounded),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMinimalTextField(_qtyController, "Ποσότητα", Icons.numbers_rounded, type: TextInputType.number),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: widget.category,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Κατηγορία",
                              filled: true,
                              fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            items: provider.toolCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (v) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Location Selection
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("ΤΟΠΟΘΕΣΙΑ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        selectedBackgroundColor: color,
                        selectedForegroundColor: Colors.white,
                      ),
                      segments: const [
                        ButtonSegment(value: "WAREHOUSE", label: Text("ΑΠΟΘΗΚΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "VAN", label: Text("ΒΑΝ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "PROJECT", label: Text("ΕΡΓΟ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                      selected: {_selectedLocationType},
                      onSelectionChanged: (s) => setState(() {
                        _selectedLocationType = s.first;
                        if (_selectedLocationType != "PROJECT") {
                          _selectedLocationId = 0;
                          _customLocationName = "";
                        }
                      }),
                    ),
                    
                    if (_selectedLocationType == "PROJECT") ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedLocationId != 0 ? _selectedLocationId : (projects.isNotEmpty ? projects.first.id : null),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Επιλογή Έργου",
                          filled: true,
                          fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedLocationId = v;
                              _customLocationName = projects.firstWhere((p) => p.id == v).name;
                            });
                          }
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    _buildMinimalTextField(_commentsController, "Σχόλια / Σημειώσεις", Icons.notes_rounded, maxLines: 2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blueGrey)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_nameController.text.isNotEmpty) {
                            final tool = Tool(
                              id: widget.initialTool?.id ?? 0,
                              name: _nameController.text,
                              category: widget.category,
                              quantity: double.tryParse(_qtyController.text) ?? 1.0,
                              comments: _commentsController.text,
                              locationType: _selectedLocationType,
                              locationId: _selectedLocationId,
                              customLocationName: _customLocationName,
                            );
                            if (widget.initialTool == null) {
                              await provider.addTool(tool);
                            } else {
                              await provider.updateTool(tool);
                            }
                            widget.onConfirm();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4361EE), width: 2)),
      ),
    );
  }
}