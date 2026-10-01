import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/category_screen.dart';

// Ensure _QuoteTab is available here or exported for use in project_economics_screen.dart
class QuoteTab extends StatelessWidget {
  final Project project;
  final List<QuoteItem> quoteItems;

  const QuoteTab({super.key, required this.project, required this.quoteItems});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3,
          ),
          itemCount: AppDestinations.values.length,
          itemBuilder: (context, index) {
            final cat = AppDestinations.values[index];
            final itemsCount = quoteItems.where((i) => i.category == cat).length;
            final cost = quoteItems.where((i) => i.category == cat).fold(0.0, (s, i) => s + i.cost);
            final clientPrice = quoteItems.where((i) => i.category == cat).fold(0.0, (s, i) => s + i.priceForClient);

            return InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: cat, projectId: project.id),
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(16),
                  color: cat.color.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("$itemsCount εγγραφές", style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (itemsCount > 0)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${cost.toStringAsFixed(0)}€", style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          Text("${clientPrice.toStringAsFixed(0)}€", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w900)),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PartnersTab extends StatefulWidget {
  final Project project;
  const PartnersTab({super.key, required this.project});

  @override
  State<PartnersTab> createState() => _PartnersTabState();
}

class _PartnersTabState extends State<PartnersTab> {
  List<Partner> _projectPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  void _loadPartners() async {
    final partners = await Provider.of<ProjectProvider>(context, listen: false).getPartnersForProject(widget.project.id);
    setState(() {
      _projectPartners = partners;
      _isLoading = false;
    });
  }

  void _showAddPartnerToProjectPicker() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final allPartners = provider.partners;
    final assignedIds = _projectPartners.map((p) => p.id).toSet();
    
    final available = allPartners.where((p) => !assignedIds.contains(p.id)).toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν άλλοι διαθέσιμοι συνεργάτες.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: PremiumHeader(title: "ΕΠΙΛΟΓΗ ΣΥΝΕΡΓΑΤΗ", icon: Icons.person_add_alt_1_rounded),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: available.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final p = available[index];
                  return ListTile(
                    title: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    subtitle: Text(p.trade, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
                    onTap: () async {
                      await provider.addPartnerToProject(widget.project.id, p.id);
                      _loadPartners();
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PremiumHeader(title: "ΣΥΝΕΡΓΑΤΕΣ ΕΡΓΟΥ", icon: Icons.groups_rounded, color: Colors.teal),
            IconButton.filledTonal(
              onPressed: _showAddPartnerToProjectPicker, 
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.teal.withValues(alpha: 0.1), foregroundColor: Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_projectPartners.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("Κανένας συνεργάτης δεν έχει ανατεθεί στο έργο", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
        else
          ..._projectPartners.map((p) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.teal.withValues(alpha: 0.2))),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal.withValues(alpha: 0.1), child: const Icon(Icons.person, color: Colors.teal)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(p.trade),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_rounded, color: Colors.red),
                onPressed: () async {
                  await Provider.of<ProjectProvider>(context, listen: false).removePartnerFromProject(widget.project.id, p.id);
                  _loadPartners();
                },
              ),
            ),
          )).toList(),
      ],
    );
  }
}
