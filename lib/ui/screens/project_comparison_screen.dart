import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectComparisonScreen extends StatelessWidget {
  const ProjectComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final projects = provider.projects;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("ΣΥΓΚΡΙΣΗ ΕΡΓΩΝ (ROI)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
      body: FutureBuilder<List<ProjectROIData>>(
        future: Future.wait(projects.map((p) => provider.calculateProjectROIData(p.id))),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final allRoiData = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    PremiumCard(
                      accentColor: Colors.blue,
                      child: Column(
                        children: [
                          const PremiumHeader(
                            title: "ΚΕΡΔΟΦΟΡΙΑ ΑΝΑ ΕΡΓΟ (%)", 
                            icon: Icons.analytics_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            height: 320,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 100,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= projects.length) return const SizedBox.shrink();
                                        final name = projects[value.toInt()].name;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 12.0),
                                          child: RotatedBox(
                                            quarterTurns: 0,
                                            child: Text(
                                              name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase(), 
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) => Text("${value.toInt()}%", style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      reservedSize: 32,
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                barGroups: projects.asMap().entries.map((entry) {
                                  final roi = allRoiData[entry.key].roiPercentage;
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: roi.clamp(0, 100),
                                        color: roi > 20 ? const Color(0xFF38B000) : const Color(0xFFF72585),
                                        width: 24,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        gradient: LinearGradient(
                                          colors: [
                                            roi > 20 ? const Color(0xFF38B000) : const Color(0xFFF72585),
                                            (roi > 20 ? const Color(0xFF38B000) : const Color(0xFFF72585)).withValues(alpha: 0.7),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const PremiumHeader(
                      title: "ΑΝΑΛΥΤΙΚΟΣ ΠΙΝΑΚΑΣ ΑΠΟΔΟΣΗΣ", 
                      icon: Icons.table_chart_rounded,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonTablePremium(projects, allRoiData),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildComparisonTablePremium(List<Project> projects, List<ProjectROIData> allRoiData) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 28,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text("ΕΡΓΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 0.5))),
            DataColumn(label: Text("ΕΙΣΠΡΑΞΕΙΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey))),
            DataColumn(label: Text("ΕΡΓΑΤΙΚΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey))),
            DataColumn(label: Text("ΥΛΙΚΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey))),
            DataColumn(label: Text("ΚΕΡΔΟΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey))),
            DataColumn(label: Text("ROI %", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey))),
          ],
          rows: List.generate(projects.length, (index) {
            final p = projects[index];
            final roiData = allRoiData[index];
            return DataRow(cells: [
              DataCell(Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))),
              DataCell(Text("${roiData.actualIncome.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue))),
              DataCell(Text("${roiData.laborCosts.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 11, color: Color(0xFF4361EE)))),
              DataCell(Text("${roiData.materialExpenses.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 11, color: Colors.orange))),
              DataCell(Text("${roiData.netProfit.toStringAsFixed(0)} €", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: roiData.netProfit >= 0 ? const Color(0xFF38B000) : Colors.red))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (roiData.roiPercentage > 20 ? Colors.green : Colors.pink).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${roiData.roiPercentage.toStringAsFixed(1)}%", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: roiData.roiPercentage > 20 ? const Color(0xFF38B000) : const Color(0xFFF72585))
                  ),
                )
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
