import 'package:flutter/material.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class ProjectROIScreen extends StatelessWidget {
  final String projectName;
  final ProjectROIData roiData;

  const ProjectROIScreen({super.key, required this.projectName, required this.roiData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΑΠΟΔΟΣΗ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(projectName.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width > 900 ? 1000 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _IndicatorCardPremium(roiData: roiData),
              const SizedBox(height: 40),
              const PremiumHeader(
                title: "ΑΝΑΛΥΣΗ ΚΟΣΤΟΥΣ VS ΕΣΟΔΩΝ", 
                icon: Icons.analytics_rounded,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _BreakdownCardPremium(roiData: roiData),
              const SizedBox(height: 32),
              _AdviceCardPremium(roiData: roiData),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorCardPremium extends StatelessWidget {
  final ProjectROIData roiData;
  const _IndicatorCardPremium({required this.roiData});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: Colors.blue,
      child: Column(
        children: [
          _RoiItemPremium(
            label: "ΠΕΡΙΘΩΡΙΟ ΚΕΡΔΟΥΣ (ΠΡΟΣΦΟΡΑ)", 
            percentage: roiData.roiPercentage, 
            amount: roiData.netProfit, 
            color: const Color(0xFF4361EE),
            icon: Icons.assignment_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Divider(),
          ),
          _RoiItemPremium(
            label: "ΠΕΡΙΘΩΡΙΟ ΚΕΡΔΟΥΣ (ΠΡΑΓΜΑΤΙΚΟ)", 
            percentage: roiData.realRoiPercentage, 
            amount: roiData.realNetProfit, 
            color: const Color(0xFF38B000),
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}

class _RoiItemPremium extends StatelessWidget {
  final String label;
  final double percentage;
  final double amount;
  final Color color;
  final IconData icon;

  const _RoiItemPremium({required this.label, required this.percentage, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "${percentage.toStringAsFixed(1)}%", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 36, color: color, letterSpacing: -1)
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Text("${amount.toStringAsFixed(0)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownCardPremium extends StatelessWidget {
  final ProjectROIData roiData;
  const _BreakdownCardPremium({required this.roiData});

  @override
  Widget build(BuildContext context) {
    final maxVal = roiData.quoteAmount > roiData.actualIncome ? roiData.quoteAmount : roiData.actualIncome;

    return PremiumCard(
      child: Column(
        children: [
          _StatBarPremium(label: "ΣΥΝΟΛΟ ΠΡΟΣΦΟΡΑΣ", amount: roiData.quoteAmount, total: maxVal, color: Colors.deepPurple, icon: Icons.description_rounded),
          const SizedBox(height: 24),
          _StatBarPremium(label: "ΠΡΑΓΜΑΤΙΚΕΣ ΕΙΣΠΡΑΞΕΙΣ", amount: roiData.actualIncome, total: maxVal, color: const Color(0xFF38B000), icon: Icons.payments_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),
          _StatBarPremium(label: "ΕΡΓΑΤΙΚΑ (ΚΟΣΤΟΣ)", amount: roiData.laborCosts, total: maxVal, color: const Color(0xFF4361EE), icon: Icons.engineering_rounded),
          const SizedBox(height: 24),
          _StatBarPremium(label: "ΥΛΙΚΑ & ΤΙΜΟΛΟΓΙΑ", amount: roiData.materialExpenses, total: maxVal, color: Colors.orange, icon: Icons.inventory_2_rounded),
        ],
      ),
    );
  }
}

class _StatBarPremium extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;

  const _StatBarPremium({required this.label, required this.amount, required this.total, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ],
            ),
            Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(5)),
            ),
            Container(
              height: 10,
              width: MediaQuery.of(context).size.width * 0.8 * progress, // Approximation for grid, fl_chart is better for complex
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdviceCardPremium extends StatelessWidget {
  final ProjectROIData roiData;
  const _AdviceCardPremium({required this.roiData});

  @override
  Widget build(BuildContext context) {
    String advice;
    IconData icon;
    Color color;
    
    if (roiData.roiPercentage > 35) {
      advice = "Εξαιρετική κερδοφορία. Το μοντέλο τιμολόγησης λειτουργεί άψογα.";
      icon = Icons.stars_rounded;
      color = Colors.green;
    } else if (roiData.roiPercentage > 20) {
      advice = "Υγιής κερδοφορία. Εντός των ορίων της αγοράς.";
      icon = Icons.check_circle_rounded;
      color = Colors.blue;
    } else {
      advice = "Προσοχή: Χαμηλό κέρδος. Απαιτείται αναθεώρηση τιμών.";
      icon = Icons.warning_rounded;
      color = Colors.orange;
    }

    final collectionProgress = roiData.quoteAmount > 0 ? (roiData.actualIncome / roiData.quoteAmount) : 0.0;

    return PremiumCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              const Text("ΣΥΜΠΕΡΑΣΜΑΤΑ & ΣΤΑΤΙΣΤΙΚΑ", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          Text(advice, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155), height: 1.5)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ΠΟΣΟΣΤΟ ΕΙΣΠΡΑΞΗΣ:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text("${(collectionProgress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: collectionProgress, minHeight: 6, color: Colors.blue, backgroundColor: Colors.blue.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }
}
