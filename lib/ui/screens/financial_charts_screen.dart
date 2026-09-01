import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/breakdown_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';

class FinancialChartsScreen extends StatelessWidget {
  final String projectName;
  final ProjectROIData roiData;
  final Map<String, CategoryBreakdown> detailedBreakdown;

  const FinancialChartsScreen({
    super.key,
    required this.projectName,
    required this.roiData,
    required this.detailedBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = roiData.laborCosts + roiData.materialExpenses + roiData.fixedCostsContribution;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΑΝΑΛΥΣΗ ΚΟΣΤΟΥΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(projectName.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              PdfGenerator.generateAndShareCostAnalysis(projectName: projectName, breakdown: detailedBreakdown, settings: provider.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => ExcelExporter.exportCostAnalysis(projectName, detailedBreakdown),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. General Allocation (Premium Pie Chart)
          PremiumCard(
            accentColor: Colors.blue,
            child: Column(
              children: [
                const PremiumHeader(
                  title: "ΓΕΝΙΚΗ ΚΑΤΑΝΟΜΗ ΔΑΠΑΝΩΝ",
                  icon: Icons.pie_chart_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 6,
                          centerSpaceRadius: 65,
                          sections: [
                            if (roiData.laborCosts > 0)
                              PieChartSectionData(
                                color: const Color(0xFF4361EE),
                                value: roiData.laborCosts,
                                title: '${(roiData.laborCosts / totalCost * 100).toInt()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                gradient: const LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)]),
                              ),
                            if (roiData.materialExpenses > 0)
                              PieChartSectionData(
                                color: const Color(0xFFFF9800),
                                value: roiData.materialExpenses,
                                title: '${(roiData.materialExpenses / totalCost * 100).toInt()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                              ),
                            if (roiData.fixedCostsContribution > 0)
                              PieChartSectionData(
                                color: const Color(0xFF94A3B8),
                                value: roiData.fixedCostsContribution,
                                title: '${(roiData.fixedCostsContribution / totalCost * 100).toInt()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                gradient: const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("ΣΥΝΟΛΟ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                          Text("${totalCost.toStringAsFixed(0)}€", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                _LegendRow(color: const Color(0xFF4361EE), label: "Εργατικά", amount: roiData.laborCosts),
                const SizedBox(height: 12),
                _LegendRow(color: const Color(0xFFFF9800), label: "Υλικά", amount: roiData.materialExpenses),
                const SizedBox(height: 12),
                _LegendRow(color: const Color(0xFF94A3B8), label: "Πάγια Έξοδα", amount: roiData.fixedCostsContribution),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // 2. Bar Chart for Categories
          if (detailedBreakdown.isNotEmpty) ...[
            PremiumCard(
              accentColor: Colors.deepPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PremiumHeader(
                    title: "ΣΥΓΚΡΙΣΗ ΦΑΣΕΩΝ",
                    icon: Icons.bar_chart_rounded,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxCost(detailedBreakdown) * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < detailedBreakdown.length) {
                                  final label = detailedBreakdown.keys.elementAt(value.toInt());
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(label.substring(0, 3).toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: _getBarGroups(detailedBreakdown),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Κόστος ανά φάση εργασίας (Εργατικά + Υλικά)", 
                      style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],

          const PremiumHeader(
            title: "ΑΝΑΛΥΣΗ ΑΝΑ ΦΑΣΗ",
            icon: Icons.list_alt_rounded,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 20),
          if (detailedBreakdown.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("Δεν υπάρχουν αναλυτικά στοιχεία ακόμα.")))
          else
            ...detailedBreakdown.entries.map((entry) => _CategoryCostCardPremium(category: entry.key, info: entry.value)).toList(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  double _getMaxCost(Map<String, CategoryBreakdown> data) {
    double max = 0;
    for (var e in data.values) {
      if (e.total > max) max = e.total;
    }
    return max;
  }

  List<BarChartGroupData> _getBarGroups(Map<String, CategoryBreakdown> data) {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < data.length; i++) {
      final entry = data.values.elementAt(i);
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.total,
              color: const Color(0xFF4361EE),
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: const LinearGradient(
                colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  const _LegendRow({required this.color, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12, height: 12, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const Spacer(),
        Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _CategoryCostCardPremium extends StatefulWidget {
  final String category;
  final CategoryBreakdown info;
  const _CategoryCostCardPremium({required this.category, required this.info});

  @override
  State<_CategoryCostCardPremium> createState() => _CategoryCostCardPremiumState();
}

class _CategoryCostCardPremiumState extends State<_CategoryCostCardPremium> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ratio = widget.info.agreed > 0 ? (widget.info.total / widget.info.agreed).clamp(0.0, 1.1) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _expanded ? Colors.blue.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.blue, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatMiniBox(label: "ΕΡΓΑΤΙΚΑ", amount: widget.info.labor, color: const Color(0xFF4361EE))),
                      const SizedBox(width: 12),
                      Expanded(child: _StatMiniBox(label: "ΥΛΙΚΑ", amount: widget.info.materials, color: const Color(0xFFFF9800))),
                    ],
                  ),
                  if (widget.info.agreed > 0) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ΑΠΟΡΡΟΦΗΣΗ ΠΡΟΣΦΟΡΑΣ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                        Text("${(ratio * 100).toInt()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ratio > 1.0 ? Colors.red : Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: ratio.toDouble(),
                        minHeight: 10,
                        color: ratio > 1.0 ? Colors.red : Colors.blue,
                        backgroundColor: Colors.blue.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ΣΥΝΟΛΟ ΦΑΣΗΣ", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text("${widget.info.total.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                        ],
                      ),
                      if (widget.info.agreed > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("ΠΡΟΣΦΟΡΑ", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text("${widget.info.agreed.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.blueGrey)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.info.laborRecords.isNotEmpty) ...[
                    _DetailSectionHeader(label: "ΚΑΤΑΓΕΓΡΑΜΜΕΝΑ ΜΕΡΟΚΑΜΑΤΑ"),
                    ...widget.info.laborRecords.map((r) => _DetailLine(title: r.workerName, amount: r.dailyRate + r.overtimeAmount, color: const Color(0xFF4361EE))),
                  ],
                  if (widget.info.materialRecords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _DetailSectionHeader(label: "ΥΛΙΚΑ & ΤΙΜΟΛΟΓΙΑ"),
                    ...widget.info.materialRecords.map((r) => _DetailLine(title: r.description, amount: r.hasVat ? r.amount / 1.24 : r.amount, color: const Color(0xFFFF9800))),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatMiniBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _StatMiniBox({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withValues(alpha: 0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionHeader extends StatelessWidget {
  final String label;
  const _DetailSectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  const _DetailLine({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
