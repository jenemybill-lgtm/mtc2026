import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mtc2026/ui/components/signature_pad.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/pdf_generator.dart';

class SummaryScreen extends StatefulWidget {
  final Project project;
  final bool showAppBar;
  const SummaryScreen({super.key, required this.project, this.showAppBar = true});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _showCategoryTotals = true;
  Uint8List? _contractorSignature;
  Uint8List? _clientSignature;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final items = provider.currentProjectQuoteItems;
    final companyExpenses = provider.companyExpenses;
    final totalProjectsCount = provider.projects.length;

    final totalCost = items.fold(0.0, (sum, i) => sum + i.cost);
    final totalClientPrice = provider.totalQuoteRevenue;

    final totalFixed = companyExpenses
        .where((e) => e.isMonthly)
        .fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));
    final distributedFixed = totalProjectsCount > 0
        ? totalFixed / totalProjectsCount
        : 0.0;

    final totalGeneral = companyExpenses
        .where((e) => !e.isMonthly)
        .fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));
    final distributedGeneral = totalProjectsCount > 0
        ? totalGeneral / totalProjectsCount
        : 0.0;

    // Material Aggregation logic
    double totalSandM3 = 0.0,
        totalSandBags = 0.0,
        totalMarbleM3 = 0.0,
        totalMarbleBags = 0.0;
    int totalCement = 0, totalLime = 0, totalGlue = 0;

    for (var item in items) {
      final note = item.internalNote;

      final sandMatch = RegExp(r"\[SAND:([\d.,]+)m3,([\d.,]+)bags\]")
          .firstMatch(note);
      if (sandMatch != null) {
        totalSandM3 +=
            double.tryParse(sandMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
        totalSandBags +=
            double.tryParse(sandMatch.group(2)!.replaceAll(',', '.')) ?? 0.0;
      }
      final marbleMatch = RegExp(r"\[MARBLE:([\d.,]+)m3,([\d.,]+)bags\]")
          .firstMatch(note);
      if (marbleMatch != null) {
        totalMarbleM3 +=
            double.tryParse(marbleMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
        totalMarbleBags +=
            double.tryParse(marbleMatch.group(2)!.replaceAll(',', '.')) ?? 0.0;
      }

      final cementMatch = RegExp(r"\[CEMENT:(\d+)\]").firstMatch(note);
      if (cementMatch != null)
        totalCement += int.tryParse(cementMatch.group(1)!) ?? 0;

      final limeMatch = RegExp(r"\[LIME:(\d+)\]").firstMatch(note);
      if (limeMatch != null)
        totalLime += int.tryParse(limeMatch.group(1)!) ?? 0;

      final glueMatch = RegExp(r"\[GLUE:(\d+)\]").firstMatch(note);
      if (glueMatch != null)
        totalGlue += int.tryParse(glueMatch.group(1)!) ?? 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: widget.showAppBar ? AppBar(
        title: const Text("ΣΥΝΟΨΗ ΠΡΟΣΦΟΡΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPdfPreview(
                    "ΠΡΟΣΦΟΡΑ",
                    PdfGenerator.buildQuoteDocument(
                      projectName: widget.project.name,
                      items: items,
                      settings: provider.settings,
                      showCategoryTotals: _showCategoryTotals,
                      showItemizedTasks: false,
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_rounded),
                  label: const Text("ΠΡΟΕΠΙΣΚΟΠΗΣΗ"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _startContractFlow(context, items, provider.settings),
                  icon: const Icon(Icons.gavel_rounded),
                  label: const Text("ΣΥΜΦΩΝΗΤΙΚΟ"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text(
              "Εμφάνιση Συνόλων ανά Κατηγορία",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            value: _showCategoryTotals,
            onChanged: (v) => setState(() => _showCategoryTotals = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),
          PremiumHeader(title: "ΑΝΑΛΥΣΗ ΑΝΑ ΚΑΤΗΓΟΡΙΑ", color: Colors.blue),
          const SizedBox(height: 16),
          ...AppDestinations.values.map((cat) {
            final catItems = items.where((i) => i.category == cat).toList();
            final catClientTotal = catItems.fold(
              0.0,
              (sum, i) => sum + i.priceForClient,
            );
            if (catClientTotal == 0) return const SizedBox.shrink();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: cat.color, size: 18),
              ),
              title: Text(
                cat.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              trailing: _showCategoryTotals
                  ? Text(
                      "${catClientTotal.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    )
                  : null,
            );
          }).toList(),

          const SizedBox(height: 32),
          _MaterialOrderCard(
            sandM3: totalSandM3,
            sandBags: totalSandBags,
            marbleM3: totalMarbleM3,
            marbleBags: totalMarbleBags,
            cement: totalCement,
            lime: totalLime,
            glue: totalGlue,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Divider(height: 1),
          ),
          _EconomicCard(
            totalCost: totalCost,
            distributedOverheads: distributedFixed + distributedGeneral,
            totalRevenue: totalClientPrice,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _startContractFlow(
    BuildContext context,
    List<QuoteItem> items,
    Settings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => SignaturePad(
        title: "ΥΠΟΓΡΑΦΗ ΕΡΓΟΛΑΒΟΥ",
        onSignatureCaptured: (sig) {
          _contractorSignature = sig;
          Navigator.pop(context);
          _showClientSignatureDialog(context, items, settings);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showClientSignatureDialog(
    BuildContext context,
    List<QuoteItem> items,
    Settings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => SignaturePad(
        title: "ΥΠΟΓΡΑΦΗ ΠΕΛΑΤΗ",
        onSignatureCaptured: (sig) {
          _clientSignature = sig;
          Navigator.pop(context);
          _showPdfPreview(
            "ΣΥΜΦΩΝΗΤΙΚΟ",
            PdfGenerator.buildContractDocument(
              project: widget.project,
              items: items,
              settings: settings,
              contractorSignature: _contractorSignature,
              clientSignature: _clientSignature,
            ),
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showPdfPreview(String title, Future<dynamic> docFuture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF4361EE),
            foregroundColor: Colors.white,
            elevation: 4,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
            ),
            leading: IconButton(
              tooltip: "Επιστροφή",
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.keyboard_return_rounded, size: 18, color: Colors.white),
                label: const Text(
                  "ΕΠΙΣΤΡΟΦΗ",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: const Color(0xFF4361EE),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          body: FutureBuilder<dynamic>(
            future: docFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        "Προετοιμασία εγγράφου...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text("Σφάλμα: ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text("Δεν υπάρχουν δεδομένα"));
              }
              final doc = snapshot.data as pw.Document;
              return PdfPreview(
                build: (format) => doc.save(),
                canChangePageFormat: false,
                canChangeOrientation: false,
                allowPrinting: true,
                allowSharing: true,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: "${title}_${widget.project.name}.pdf",
                scrollViewDecoration: const BoxDecoration(
                  color: Colors.white,
                ),
                maxPageWidth: 800,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaterialOrderCard extends StatelessWidget {
  final double sandM3, sandBags, marbleM3, marbleBags;
  final int cement, lime, glue;

  const _MaterialOrderCard({
    required this.sandM3,
    required this.sandBags,
    required this.marbleM3,
    required this.marbleBags,
    required this.cement,
    required this.lime,
    required this.glue,
  });

  @override
  Widget build(BuildContext context) {
    if (sandM3 == 0 && marbleM3 == 0 && cement == 0 && lime == 0 && glue == 0)
      return const SizedBox.shrink();

    return Card(
      color: Colors.teal.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ΛΊΣΤΑ ΠΑΡΑΓΓΕΛΊΑΣ ΥΛΙΚΏΝ (ΕΣΩΤΕΡΙΚΉ)",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            if (sandM3 > 0)
              _materialRow(
                "Άμμος",
                "${sandM3.toStringAsFixed(2)} m³ (~${sandBags.toStringAsFixed(0)} σακιά)",
              ),
            if (marbleM3 > 0)
              _materialRow(
                "Μαρμαρόσκονη",
                "${marbleM3.toStringAsFixed(2)} m³ (~${marbleBags.toStringAsFixed(0)} σακιά)",
              ),
            if (cement > 0) _materialRow("Τσιμέντο (25kg)", "$cement σακιά"),
            if (lime > 0) _materialRow("Ασβέστης", "$lime σακιά"),
            if (glue > 0) _materialRow("Κόλλα", "$glue σακιά"),
          ],
        ),
      ),
    );
  }

  Widget _materialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.teal),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EconomicCard extends StatelessWidget {
  final double totalCost;
  final double distributedOverheads;
  final double totalRevenue;

  const _EconomicCard({
    required this.totalCost,
    required this.distributedOverheads,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final totalProjectCost = totalCost + distributedOverheads;
    final netProfit = totalRevenue - totalProjectCost;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ΟΙΚΟΝΟΜΙΚΆ ΣΤΟΙΧΕΊΑ ΈΡΓΟΥ (ΚΑΘΑΡΆ)",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _EconomicRow(label: "Κόστος βάσει Προσφοράς", amount: totalCost),
            const SizedBox(height: 8),
            _EconomicRow(
              label: "Καταμερισμένα Πάγια",
              amount: distributedOverheads,
            ),
            const Divider(height: 24),
            _EconomicRow(
              label: "Συνολικό Καθαρό Κόστος",
              amount: totalProjectCost,
              isBold: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ΚΑΘΑΡΌ ΚΈΡΔΟΣ ΈΡΓΟΥ",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "${netProfit.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EconomicRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _EconomicRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
        Text(
          "${amount.toStringAsFixed(2)} €",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
