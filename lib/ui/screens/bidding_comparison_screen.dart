import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class BiddingComparisonScreen extends StatefulWidget {
  final int projectId;
  const BiddingComparisonScreen({super.key, required this.projectId});

  @override
  State<BiddingComparisonScreen> createState() => _BiddingComparisonScreenState();
}

class _BiddingComparisonScreenState extends State<BiddingComparisonScreen> {
  String _selectedCategory = "GENERAL";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΣΥΓΚΡΙΣΗ ΠΡΟΣΦΟΡΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBidDialog(context, provider),
        label: const Text("ΝΕΑ ΠΡΟΣΦΟΡΑ"),
        icon: const Icon(Icons.add_chart_rounded),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<List<PartnerBid>>(
              future: provider.getPartnerBids(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final bids = snapshot.data!.where((b) => b.category == _selectedCategory).toList();

                if (bids.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: bids.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    return _BidCard(
                      bid: bid, 
                      isBest: index == 0, // Sorted by amount in helper
                      onAccept: () => _acceptBid(context, provider, bid),
                      onDelete: () => provider.deletePartnerBid(bid.id).then((_) => setState(() {})),
                    );
                  },
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
        itemCount: AppDestinations.values.length,
        itemBuilder: (context, index) {
          final cat = AppDestinations.values[index];
          final isSelected = cat.name == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.white : Colors.blueGrey)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat.name),
              selectedColor: Colors.blue,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          Icon(Icons.compare_arrows_rounded, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text("Καμία προσφορά για αυτή την κατηγορία", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddBidDialog(BuildContext context, ProjectProvider provider) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    Partner? selectedPartner;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const PremiumHeader(title: "ΚΑΤΑΧΩΡΗΣΗ ΠΡΟΣΦΟΡΑΣ", icon: Icons.add_task_rounded),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Partner>(
                value: selectedPartner,
                decoration: const InputDecoration(labelText: "Επιλογή Συνεργάτη"),
                items: provider.partners.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => selectedPartner = v),
              ),
              const SizedBox(height: 16),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: "Ποσό Προσφοράς (€)"), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: "Σημειώσεις / Παροχές"), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
            ElevatedButton(
              onPressed: () async {
                if (selectedPartner != null && amountController.text.isNotEmpty) {
                  await provider.addPartnerBid(PartnerBid(
                    projectId: widget.projectId,
                    partnerId: selectedPartner!.id,
                    partnerName: selectedPartner!.name,
                    category: _selectedCategory,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    notes: notesController.text,
                  ));
                  if (context.mounted) Navigator.pop(context);
                  this.setState(() {});
                }
              }, 
              child: const Text("ΠΡΟΣΘΗΚΗ"),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptBid(BuildContext context, ProjectProvider provider, PartnerBid bid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΑΠΟΔΟΧΗ ΠΡΟΣΦΟΡΑΣ"),
        content: Text("Θέλετε να αποδεχτείτε την προσφορά του ${bid.partnerName} (€${bid.amount}) και να δημιουργηθεί αυτόματα συμφωνητικό;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ΟΧΙ")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("ΝΑΙ")),
        ],
      ),
    );

    if (confirm == true) {
      await provider.addPartnerToProject(widget.projectId, bid.partnerId);
      await provider.addPartnerAgreement(PartnerAgreement(
        projectId: widget.projectId,
        partnerId: bid.partnerId,
        category: bid.category,
        amount: bid.amount,
      ));
      await provider.updatePartnerBid(PartnerBid(
        id: bid.id,
        projectId: bid.projectId,
        partnerId: bid.partnerId,
        partnerName: bid.partnerName,
        category: bid.category,
        amount: bid.amount,
        isAccepted: true,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Η προσφορά έγινε αποδεκτή!")));
        setState(() {});
      }
    }
  }
}

class _BidCard extends StatelessWidget {
  final PartnerBid bid;
  final bool isBest;
  final VoidCallback onAccept;
  final VoidCallback onDelete;

  const _BidCard({required this.bid, required this.isBest, required this.onAccept, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: bid.isAccepted ? Colors.green : (isBest ? Colors.blue : Colors.blueGrey),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (bid.isAccepted ? Colors.green : Colors.blue).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(bid.isAccepted ? Icons.check_circle_rounded : Icons.person_rounded, color: bid.isAccepted ? Colors.green : Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.partnerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    if (isBest && !bid.isAccepted)
                      const Text("ΚΑΛΥΤΕΡΗ ΤΙΜΗ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1)),
                  ],
                ),
              ),
              Text("${bid.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
            ],
          ),
          if (bid.notes.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Text(bid.notes, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: bid.isAccepted 
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text("ΕΓΚΡΙΘΗΚΕ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                    )
                  : ElevatedButton.icon(
                      onPressed: onAccept, 
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text("ΑΠΟΔΟΧΗ", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
              ),
              if (!bid.isAccepted) ...[
                const SizedBox(width: 12),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}