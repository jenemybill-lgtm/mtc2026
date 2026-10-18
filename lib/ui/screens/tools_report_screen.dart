import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ToolsReportScreen extends StatelessWidget {
  const ToolsReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text("ΑΝΑΦΟΡΑ ΕΡΓΑΛΕΙΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: FutureBuilder<List<Tool>>(
        future: Provider.of<ProjectProvider>(context, listen: false).getTools(null, "TOTAL", "ΟΛΑ"),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final tools = snapshot.data!;
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          
          // Φιλτράρισμα: Θέλουμε ΜΟΝΟ τα εργαλεία που ΔΕΝ είναι στην Αποθήκη ή στο Βαν
          final toolsInProjects = tools.where((t) => t.locationType != 'WAREHOUSE' && t.locationType != 'VAN' && t.locationType != 'REPAIR').toList();
          
          if (toolsInProjects.isEmpty) {
            return const PremiumEmptyState(
              title: "ΟΛΑ ΤΑ ΕΡΓΑΛΕΙΑ ΣΤΗ ΒΑΣΗ",
              subtitle: "Δεν υπάρχει κανένα εργαλείο ξεχασμένο ή αφημένο σε κάποιο εργοτάξιο αυτή τη στιγμή.",
              icon: Icons.check_circle_outline_rounded,
            );
          }

          // Ομαδοποίηση ανά Έργο (Ανά Τοποθεσία)
          final groupedTools = <String, List<Tool>>{};
          for (var t in toolsInProjects) {
            String locationName = t.customLocationName ?? "Άγνωστο Έργο";
            if (t.locationType == 'PROJECT') {
               final proj = provider.projects.where((p) => p.id == t.locationId).firstOrNull;
               if (proj != null) locationName = proj.name;
            }
            groupedTools.putIfAbsent(locationName, () => []).add(t);
          }

          final isDesktop = MediaQuery.of(context).size.width > 900;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: groupedTools.length,
                itemBuilder: (context, index) {
                  final locationName = groupedTools.keys.elementAt(index);
                  final locationTools = groupedTools[locationName]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12, top: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.business_rounded, color: Color(0xFF4361EE), size: 18),
                            const SizedBox(width: 8),
                            Text(locationName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      ...locationTools.map((t) {
                        final daysAgo = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(t.lastLocationUpdate)).inDays;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1.0),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4361EE).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.build_rounded, color: Color(0xFF4361EE), size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                      const SizedBox(height: 2),
                                      Text("Ποσότητα: ${t.quantity.toInt()} • ${t.category}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                      if (t.assignedTo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_pin_circle_rounded, size: 10, color: Color(0xFF4361EE)),
                                            const SizedBox(width: 4),
                                            Text(t.assignedTo.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4361EE))),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: daysAgo > 10 ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text("ΠΑΡΑΜΟΝΗ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: daysAgo > 10 ? Colors.red : Colors.orange)),
                                      Text("$daysAgo Ημέρες", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: daysAgo > 10 ? Colors.red : Colors.orange)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
