import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectMaterialNeedsScreen extends StatefulWidget {
  final Project project;

  const ProjectMaterialNeedsScreen({super.key, required this.project});

  @override
  State<ProjectMaterialNeedsScreen> createState() => _ProjectMaterialNeedsScreenState();
}

class _ProjectMaterialNeedsScreenState extends State<ProjectMaterialNeedsScreen> {
  bool _isLoading = true;
  List<MaterialEntity> _allInventory = [];
  List<QuoteItem> _quoteNeeds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    // 1. Fetch Quote Data
    await provider.fetchProjectData(widget.project.id);
    
    // 2. Fetch all types of inventory
    final warehouse = await provider.getMaterials(null, "WAREHOUSE", "ΟΛΑ");
    final van = await provider.getMaterials(null, "VAN", "ΟΛΑ");
    final project = await provider.getMaterials(widget.project.id, "PROJECT", "ΟΛΑ");

    if (mounted) {
      setState(() {
        _quoteNeeds = provider.currentProjectQuoteItems.where((item) => 
            item.internalNote.contains("ΥΛΙΚΑ:") || 
            item.internalNote.contains("ΑΝΑΛΥΣΗ") ||
            item.internalNote.contains("m²") ||
            item.internalNote.contains("m³")).toList();
            
        _allInventory = [...project, ...van, ...warehouse];
        _isLoading = false;
      });
    }
  }

  Future<void> _syncAllToProject() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final Map<String, String> materialMap = {
      "ΤΣΙΜΕΝΤ": "ΤΣΙΜΕΝΤΟ",
      "ΑΜΜΟΣ": "ΑΜΜΟΣ",
      "ΜΑΡΜΑΡΟΣ": "ΜΑΡΜΑΡΟΣΚΟΝΗ",
      "ΑΣΒΕΣΤ": "ΑΣΒΕΣΤΗΣ",
      "ΚΟΛΛΑ": "ΚΟΛΛΑ",
      "ΚΑΛΩΔΙ": "ΚΑΛΩΔΙΑ",
      "ΣΩΛΗΝ": "ΣΩΛΗΝΕΣ",
      "ΓΥΨΟΣΑΝΙΔ": "ΓΥΨΟΣΑΝΙΔΕΣ",
      "ΜΠΕΤΟ": "ΕΤΟΙΜΟ ΜΠΕΤΟ",
      "ΣΙΔΗΡ": "ΣΙΔΗΡΟΣ ΟΠΛΙΣΜΟΥ",
      "ΧΡΩΜΑ": "ΧΡΩΜΑΤΑ",
      "ΑΣΤΑΡΙ": "ΑΣΤΑΡΙ",
    };

    int addedCount = 0;
    for (var item in _quoteNeeds) {
      final noteUpper = item.internalNote.toUpperCase();
      for (var entry in materialMap.entries) {
        if (noteUpper.contains(entry.key)) {
          final exists = _allInventory.any((m) => 
            m.projectId == widget.project.id && 
            m.locationType == "PROJECT" && 
            m.name.toUpperCase().contains(entry.key));
          
          if (!exists) {
            await provider.addMaterial(MaterialEntity(
              name: entry.value,
              category: item.category.label,
              quantity: 0.0,
              unit: _getUnitFor(entry.value),
              locationType: "PROJECT",
              projectId: widget.project.id,
            ));
            addedCount++;
          }
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Προστέθηκαν $addedCount νέα υλικά στη λίστα του έργου.")),
      );
      _loadData();
    }
  }

  String _getUnitFor(String name) {
    if (name.contains("ΤΣΙΜΕΝΤΟ") || name.contains("ΚΟΛΛΑ") || name.contains("ΑΣΒΕΣΤΗΣ")) return "σακί";
    if (name.contains("ΑΜΜΟΣ") || name.contains("ΜΑΡΜΑΡΟΣΚΟΝΗ") || name.contains("ΜΠΕΤΟ")) return "m³";
    if (name.contains("ΣΙΔΗΡΟΣ")) return "kg";
    return "τεμ";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΑΝΑΓΚΕΣ ΥΛΙΚΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.blue),
            tooltip: "Συγχρονισμός στο Έργο",
            onPressed: _syncAllToProject,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _quoteNeeds.isEmpty
          ? _buildEmptyState()
          : _buildNeedsList(),
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
            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text("Δεν βρέθηκαν υπολογισμοί υλικών", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNeedsList() {
    final Map<String, List<QuoteItem>> grouped = {};
    for (var item in _quoteNeeds) {
      grouped.putIfAbsent(item.category.label, () => []).add(item);
    }

    final Map<String, _AggregateNeed> aggregatedNeeds = {};
    final Map<String, String> materialMap = {
      "ΤΣΙΜΕΝΤ": "ΤΣΙΜΕΝΤΟ",
      "ΑΜΜΟΣ": "ΑΜΜΟΣ",
      "ΜΑΡΜΑΡΟΣ": "ΜΑΡΜΑΡΟΣΚΟΝΗ",
      "ΑΣΒΕΣΤ": "ΑΣΒΕΣΤΗΣ",
      "ΚΟΛΛΑ": "ΚΟΛΛΑ",
      "ΚΑΛΩΔΙ": "ΚΑΛΩΔΙΑ",
      "ΣΩΛΗΝ": "ΣΩΛΗΝΕΣ",
      "ΓΥΨΟΣΑΝΙΔ": "ΓΥΨΟΣΑΝΙΔΕΣ",
      "ΜΠΕΤΟ": "ΕΤΟΙΜΟ ΜΠΕΤΟ",
      "ΣΙΔΗΡ": "ΣΙΔΗΡΟΣ ΟΠΛΙΣΜΟΥ",
      "ΧΡΩΜΑ": "ΧΡΩΜΑΤΑ",
      "ΑΣΤΑΡΙ": "ΑΣΤΑΡΙ",
    };

    for (var item in _quoteNeeds) {
      final lines = item.internalNote.split('\n');
      for (var line in lines) {
        if (line.trim().startsWith('- ')) {
          final content = line.replaceFirst('- ', '').trim();
          final parts = content.split(':');
          if (parts.length == 2) {
             final name = parts[0].trim().toUpperCase();
             final qtyPart = parts[1].trim();
             final qtyMatch = RegExp(r"([\d.]+)").firstMatch(qtyPart);
             if (qtyMatch != null) {
               final qty = double.tryParse(qtyMatch.group(1)!) ?? 0.0;
               final unit = qtyPart.replaceAll(qtyMatch.group(1)!, "").trim();
               
               String standardName = name;
               for (var entry in materialMap.entries) {
                 if (name.contains(entry.key)) {
                   standardName = entry.value;
                   break;
                 }
               }
               
               final key = "$standardName|$unit";
               if (aggregatedNeeds.containsKey(key)) {
                 aggregatedNeeds[key]!.totalRequired += qty;
               } else {
                 aggregatedNeeds[key] = _AggregateNeed(name: standardName, totalRequired: qty, unit: unit);
               }
             }
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        const PremiumHeader(title: "ΣΥΝΟΛΙΚΕΣ ΕΛΛΕΙΨΕΙΣ ΕΡΓΟΥ", icon: Icons.analytics_rounded, color: Colors.redAccent),
        const SizedBox(height: 16),
        if (aggregatedNeeds.isEmpty)
           const Center(child: Text("Δεν βρέθηκαν αναλυτικά υλικά", style: TextStyle(fontSize: 10, color: Colors.grey)))
        else
          ...aggregatedNeeds.values.map((need) {
             final keyword = _getKeyword(need.name);
             final projectStock = _allInventory.where((m) => m.locationType == "PROJECT" && m.name.toUpperCase().contains(keyword)).fold(0.0, (sum, m) => sum + m.quantity);
             final vanStock = _allInventory.where((m) => m.locationType == "VAN" && m.name.toUpperCase().contains(keyword)).fold(0.0, (sum, m) => sum + m.quantity);
             final warehouseStock = _allInventory.where((m) => m.locationType == "WAREHOUSE" && m.name.toUpperCase().contains(keyword)).fold(0.0, (sum, m) => sum + m.quantity);
             
             final shortage = (need.totalRequired - projectStock).clamp(0.0, 99999.0);

             return _MaterialShortageAnalysisRow(
                name: need.name,
                requiredQty: need.totalRequired,
                projectQty: projectStock,
                vanQty: vanStock,
                warehouseQty: warehouseStock,
                shortage: shortage,
                unit: need.unit,
                onAdd: () async {
                   final provider = Provider.of<ProjectProvider>(context, listen: false);
                   String standardName = need.name.toUpperCase();
                   if (standardName.startsWith("ΤΣΙΜΕΝΤ")) standardName = "ΤΣΙΜΕΝΤΟ";
                   
                   await provider.addMaterial(MaterialEntity(
                     name: standardName,
                     category: "ΓΕΝΙΚΑ",
                     quantity: 0.0,
                     unit: need.unit,
                     locationType: "PROJECT",
                     projectId: widget.project.id,
                   ));
                   _loadData();
                },
             );
          }).toList(),

        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 24),
        const PremiumHeader(title: "ΑΝΑΛΥΣΗ ΑΝΑ ΕΡΓΑΣΙΑ", icon: Icons.list_alt_rounded, color: Colors.blueGrey),
        const SizedBox(height: 24),
        ...grouped.entries.map((entry) {
          final catName = entry.key;
          final items = entry.value;
          final color = items.first.category.color;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                child: Text(catName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 1)),
              ),
              ...items.map((it) => _MaterialNeedCard(
                item: it,
                accentColor: color,
                inventory: _allInventory,
                projectId: widget.project.id,
                onRefresh: _loadData,
              )).toList(),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ],
    );
  }
}

String _getKeyword(String name) {
  final n = name.toUpperCase();
  if (n.contains("ΤΣΙΜΕΝΤ")) return "ΤΣΙΜΕΝΤ";
  if (n.contains("ΑΜΜΟΣ")) return "ΑΜΜΟΣ";
  if (n.contains("ΜΑΡΜΑΡΟΣ")) return "ΜΑΡΜΑΡΟΣ";
  if (n.contains("ΑΣΒΕΣΤ")) return "ΑΣΒΕΣΤ";
  if (n.contains("ΚΟΛΛΑ")) return "ΚΟΛΛΑ";
  if (n.contains("ΚΑΛΩΔΙ")) return "ΚΑΛΩΔΙ";
  if (n.contains("ΣΩΛΗΝ")) return "ΣΩΛΗΝ";
  if (n.contains("ΓΥΨΟΣΑΝΙΔ")) return "ΓΥΨΟΣΑΝΙΔ";
  return n;
}

class _AggregateNeed {
  final String name;
  double totalRequired;
  final String unit;
  _AggregateNeed({required this.name, required this.totalRequired, required this.unit});
}

class _MaterialNeedCard extends StatelessWidget {
  final QuoteItem item;
  final Color accentColor;
  final List<MaterialEntity> inventory;
  final int projectId;
  final VoidCallback onRefresh;

  const _MaterialNeedCard({required this.item, required this.accentColor, required this.inventory, required this.projectId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    final lines = item.internalNote.split('\n');
    final needs = <_ParsedNeed>[];
    
    for (var line in lines) {
      if (line.trim().startsWith('- ')) {
        final content = line.replaceFirst('- ', '').trim();
        final parts = content.split(':');
        if (parts.length == 2) {
          final name = parts[0].trim();
          final qtyPart = parts[1].trim();
          final qtyMatch = RegExp(r"([\d.]+)").firstMatch(qtyPart);
          if (qtyMatch != null) {
            final qty = double.tryParse(qtyMatch.group(1)!) ?? 0.0;
            final unit = qtyPart.replaceAll(qtyMatch.group(1)!, "").trim();
            needs.add(_ParsedNeed(name: name, requiredQty: qty, unit: unit));
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.1), accentColor.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accentColor.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.description.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ΑΝΑΛΥΣΗ ΕΛΛΕΙΨΕΩΝ & ΑΠΟΘΕΜΑΤΩΝ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                
                if (needs.isEmpty) 
                   Text(item.internalNote, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))
                else
                  ...needs.map((need) {
                    final keyword = _getKeyword(need.name);
                    
                    final projectItems = inventory.where((m) => m.locationType == "PROJECT" && m.name.toUpperCase().contains(keyword)).toList();
                    final vanItems = inventory.where((m) => m.locationType == "VAN" && m.name.toUpperCase().contains(keyword)).toList();
                    final warehouseItems = inventory.where((m) => m.locationType == "WAREHOUSE" && m.name.toUpperCase().contains(keyword)).toList();

                    final projectStock = projectItems.fold(0.0, (sum, m) => sum + m.quantity);
                    final vanStock = vanItems.fold(0.0, (sum, m) => sum + m.quantity);
                    final warehouseStock = warehouseItems.fold(0.0, (sum, m) => sum + m.quantity);
                    
                    final shortage = (need.requiredQty - projectStock).clamp(0.0, 99999.0);

                    return _MaterialShortageAnalysisRow(
                      name: need.name,
                      requiredQty: need.requiredQty,
                      projectQty: projectStock,
                      vanQty: vanStock,
                      warehouseQty: warehouseStock,
                      shortage: shortage,
                      unit: need.unit,
                      onAdd: () async {
                        String finalName = need.name.toUpperCase();
                        if (finalName.startsWith("ΤΣΙΜΕΝΤ")) finalName = "ΤΣΙΜΕΝΤΟ";
                        if (finalName.startsWith("ΑΜΜΟΣ")) finalName = "ΑΜΜΟΣ";
                        if (finalName.startsWith("ΜΑΡΜΑΡΟΣ")) finalName = "ΜΑΡΜΑΡΟΣΚΟΝΗ";
                        
                        await provider.addMaterial(MaterialEntity(
                          name: finalName,
                          category: item.category.label,
                          quantity: 0.0,
                          unit: need.unit,
                          locationType: "PROJECT",
                          projectId: projectId,
                        ));
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Το υλικό $finalName προστέθηκε στο έργο.")),
                        );
                        onRefresh();
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedNeed {
  final String name;
  final double requiredQty;
  final String unit;
  _ParsedNeed({required this.name, required this.requiredQty, required this.unit});
}

class _MaterialShortageAnalysisRow extends StatelessWidget {
  final String name;
  final double requiredQty, projectQty, vanQty, warehouseQty, shortage;
  final String unit;
  final VoidCallback onAdd;

  const _MaterialShortageAnalysisRow({
    required this.name, 
    required this.requiredQty, 
    required this.projectQty, 
    required this.vanQty, 
    required this.warehouseQty,
    required this.shortage,
    required this.unit,
    required this.onAdd
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullyStocked = shortage <= 0;
    final bool isMissingInProject = projectQty <= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFullyStocked ? Colors.green.withValues(alpha: 0.03) : Colors.red.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isFullyStocked ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFullyStocked ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                size: 18,
                color: isFullyStocked ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E293B))
                ),
              ),
              if (isMissingInProject && projectQty <= 0 && vanQty == 0 && warehouseQty == 0)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.blue, size: 24),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: "Προσθήκη στο Έργο",
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _infoBox("ΑΠΑΙΤΕΙΤΑΙ", requiredQty, Colors.blueGrey, unit)),
              const SizedBox(width: 8),
              Expanded(child: _infoBox("ΣΤΟ ΕΡΓΟ", projectQty, const Color(0xFF38B000), unit)),
              const SizedBox(width: 8),
              Expanded(child: _infoBox("ΕΛΛΕΙΨΗ", shortage, Colors.red, unit, isBold: shortage > 0)),
            ],
          ),
          if (vanQty > 0 || warehouseQty > 0) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            const Text("ΔΙΑΘΕΣΙΜΑ ΓΙΑ ΜΕΤΑΦΟΡΑ / ΠΑΡΑΛΑΒΗ:", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (vanQty > 0) _altStock("ΣΤΟ ΒΑΝ", vanQty, Colors.orange, unit),
                if (vanQty > 0 && warehouseQty > 0) const SizedBox(width: 12),
                if (warehouseQty > 0) _altStock("ΑΠΟΘΗΚΗ", warehouseQty, const Color(0xFF7209B7), unit),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(String label, double qty, Color color, String unit, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey)),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "${qty.toStringAsFixed(1)} $unit",
            style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: 11, color: qty > 0 ? color : Colors.blueGrey.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  Widget _altStock(String label, double qty, Color color, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        "$label: ${qty.toStringAsFixed(1)} $unit",
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}
