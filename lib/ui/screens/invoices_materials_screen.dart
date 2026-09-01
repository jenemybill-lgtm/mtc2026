import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';

class InvoicesMaterialsScreen extends StatelessWidget {
  final List<Expense> expenses;
  final Function(Expense) onDelete;

  const InvoicesMaterialsScreen({super.key, required this.expenses, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final invoices = expenses.where((e) => e.expenseType == "INVOICE" || e.workerName.toLowerCase().contains("υλικά")).toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));

    final grouped = <String, List<Expense>>{};
    for (var inv in invoices) {
      final date = DateFormat('dd MMMM yyyy', 'el').format(DateTime.fromMillisecondsSinceEpoch(inv.date));
      grouped.putIfAbsent(date.toUpperCase(), () => []).add(inv);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΤΙΜΟΛΟΓΙΑ & ΥΛΙΚΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              PdfGenerator.generateAndShareInvoiceList(invoices: invoices, settings: provider.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => ExcelExporter.exportInvoices(invoices),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: invoices.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final date = grouped.keys.elementAt(index);
                final dayInvoices = grouped[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
                      child: PremiumHeader(title: date, color: Colors.blueGrey),
                    ),
                    ...dayInvoices.map((inv) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _InvoiceCardPremium(invoice: inv, onDelete: () => onDelete(inv)),
                    )),
                    const SizedBox(height: 16),
                  ],
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text("Δεν βρέθηκαν τιμολόγια", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
          const Text("Προσθέστε έξοδα με τύπο 'Τιμολόγιο'", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InvoiceCardPremium extends StatelessWidget {
  final Expense invoice;
  final VoidCallback onDelete;
  const _InvoiceCardPremium({required this.invoice, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      accentColor: Colors.blue,
      onTap: () => _showInvoiceDetails(context, invoice),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                Text(invoice.workerName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${invoice.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 15)),
              if (invoice.invoiceNumber != null && invoice.invoiceNumber!.isNotEmpty)
                Text("ΑΡ: ${invoice.invoiceNumber}", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black12), onPressed: onDelete),
        ],
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Expense inv) {
    final net = inv.hasVat ? inv.amount / 1.24 : inv.amount;
    final vat = inv.amount - net;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const PremiumHeader(title: "ΛΕΠΤΟΜΕΡΕΙΕΣ ΤΙΜΟΛΟΓΙΟΥ", icon: Icons.description_rounded),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("ΠΕΡΙΓΡΑΦΗ", inv.description.toUpperCase(), Colors.blueGrey),
            _detailRow("ΠΡΟΜΗΘΕΥΤΗΣ / ΣΥΝΕΡΓΑΤΗΣ", inv.workerName.toUpperCase(), Colors.blue),
            if (inv.invoiceNumber != null && inv.invoiceNumber!.isNotEmpty)
              _detailRow("ΑΡΙΘΜΟΣ ΤΙΜΟΛΟΓΙΟΥ", inv.invoiceNumber!, Colors.indigo),
            _detailRow("ΗΜΕΡΟΜΗΝΙΑ", DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(inv.date)), Colors.grey),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ΚΑΘΑΡΟ ΠΟΣΟ:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text("${net.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ΦΠΑ (24%):", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text("${vat.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ΤΕΛΙΚΟ ΣΥΝΟΛΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  Text("${inv.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΚΛΕΙΣΙΜΟ", style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
