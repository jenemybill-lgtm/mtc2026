import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/bidding_comparison_screen.dart';

class ProjectPartnersScreen extends StatefulWidget {
  final Project project;
  const ProjectPartnersScreen({super.key, required this.project});

  @override
  State<ProjectPartnersScreen> createState() => _ProjectPartnersScreenState();
}

class _ProjectPartnersScreenState extends State<ProjectPartnersScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΣΥΝΕΡΓΑΤΕΣ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "bid_btn",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BiddingComparisonScreen(projectId: widget.project.id))),
            label: const Text("ΣΥΓΚΡΙΣΗ ΠΡΟΣΦΟΡΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
            icon: const Icon(Icons.compare_arrows_rounded),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "partner_btn",
            onPressed: () => _showAddPartnerPicker(context, provider),
            label: const Text("ΠΡΟΣΘΗΚΗ ΣΥΝΕΡΓΑΤΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            icon: const Icon(Icons.person_add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Partner>>(
        future: provider.getPartnersForProject(widget.project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final assignedPartners = snapshot.data ?? [];

          if (assignedPartners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
                    child: Icon(Icons.group_off_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 24),
                  const Text("Κανένας συνεργάτης στο έργο", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Πατήστε το κουμπί για προσθήκη", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: assignedPartners.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final partner = assignedPartners[index];
              return _AssignedPartnerCard(
                partner: partner,
                project: widget.project,
                provider: provider,
                onRemove: () async {
                  await provider.removePartnerFromProject(widget.project.id, partner.id);
                  setState(() {});
                },
                onAddAgreement: () => _showAgreementDialog(context, provider, partner),
                onEditAgreement: (agreement) => _showAgreementDialog(context, provider, partner, agreement: agreement),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPartnerPicker(BuildContext context, ProjectProvider provider) async {
    final allPartners = provider.partners;
    final assigned = await provider.getPartnersForProject(widget.project.id);
    final assignedIds = assigned.map((p) => p.id).toSet();
    
    final available = allPartners.where((p) => !assignedIds.contains(p.id)).toList();

    if (!context.mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Όλοι οι διαθέσιμοι συνεργάτες έχουν ήδη προστεθεί."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        )
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(32.0),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person, color: Colors.blue, size: 24),
                    ),
                    title: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                    subtitle: Text(p.trade, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    trailing: const Icon(Icons.add_circle_rounded, color: Colors.blue, size: 28),
                    onTap: () async {
                      await provider.addPartnerToProject(widget.project.id, p.id);
                      if (context.mounted) Navigator.pop(context);
                      setState(() {});
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

  void _showAgreementDialog(BuildContext context, ProjectProvider provider, Partner partner, {PartnerAgreement? agreement}) {
     final amountController = TextEditingController(text: agreement?.amount.toString() ?? "");
     String? selectedCategory = agreement?.category;

     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
         title: PremiumHeader(
           title: agreement == null ? "ΝΕΑ ΠΡΟΣΦΟΡΑ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΠΡΟΣΦΟΡΑΣ", 
           subtitle: partner.name.toUpperCase(),
           icon: Icons.assignment_turned_in_rounded
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             DropdownButtonFormField<String>(
               value: selectedCategory,
               decoration: const InputDecoration(labelText: "Κατηγορία Εργασίας"),
               items: AppDestinations.values.map((d) => DropdownMenuItem(value: d.name, child: Text(d.label, style: const TextStyle(fontSize: 14)))).toList(),
               onChanged: (v) => selectedCategory = v,
             ),
             const SizedBox(height: 20),
             TextField(
               controller: amountController,
               decoration: const InputDecoration(labelText: "Ποσό Συμφωνίας (€)", prefixIcon: Icon(Icons.euro_rounded)),
               keyboardType: TextInputType.number,
             ),
           ],
         ),
         actions: [
           if (agreement != null)
             TextButton(
               onPressed: () async {
                 await provider.deletePartnerAgreement(agreement.id);
                 if (context.mounted) Navigator.pop(context);
                 setState(() {});
               }, 
               style: TextButton.styleFrom(foregroundColor: Colors.red),
               child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
             ),
           TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
           ElevatedButton(
             onPressed: () async {
               if (selectedCategory != null && amountController.text.isNotEmpty) {
                 final newAgreement = PartnerAgreement(
                   id: agreement?.id ?? 0,
                   projectId: widget.project.id,
                   partnerId: partner.id,
                   category: selectedCategory!,
                   amount: double.tryParse(amountController.text) ?? 0.0,
                 );
                 
                 if (agreement == null) {
                   await provider.addPartnerAgreement(newAgreement);
                 } else {
                   await provider.updatePartnerAgreement(newAgreement);
                 }
                 
                 if (context.mounted) Navigator.pop(context);
                 setState(() {});
               }
             },
             child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
           ),
         ],
       ),
     );
  }
}

class _AssignedPartnerCard extends StatelessWidget {
  final Partner partner;
  final Project project;
  final ProjectProvider provider;
  final VoidCallback onRemove;
  final VoidCallback onAddAgreement;
  final Function(PartnerAgreement) onEditAgreement;

  const _AssignedPartnerCard({
    required this.partner, 
    required this.project,
    required this.provider,
    required this.onRemove,
    required this.onAddAgreement,
    required this.onEditAgreement,
  });

  @override
  Widget build(BuildContext context) {
    final isWorker = partner.trade == "Εργάτης";

    return FutureBuilder<List<PartnerAgreement>>(
      future: provider.getPartnerAgreements(project.id),
      builder: (context, snapshot) {
        final agreements = (snapshot.data ?? []).where((a) => a.partnerId == partner.id).toList();
        final totalAgreed = agreements.fold(0.0, (sum, a) => sum + a.amount);
        
        final paid = provider.currentProjectExpenses
            .where((e) => e.workerName == partner.name)
            .fold(0.0, (sum, e) => sum + e.amount);

        final remaining = totalAgreed - paid;
        final progress = totalAgreed > 0 ? (paid / totalAgreed).clamp(0.0, 1.0) : 0.0;

        return PremiumCard(
          accentColor: isWorker ? Colors.green : Colors.blue,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        isWorker ? Colors.green : Colors.blue, 
                        (isWorker ? Colors.green : Colors.blue).withValues(alpha: 0.7)
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: (isWorker ? Colors.green : Colors.blue).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(isWorker ? Icons.engineering_rounded : Icons.person_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(partner.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: (isWorker ? Colors.green : Colors.blue).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(partner.trade.toUpperCase(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isWorker ? Colors.green : Colors.blue, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  if (isWorker)
                     Padding(
                       padding: const EdgeInsets.only(right: 8.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           const Text("ΜΕΡΟΚ.", style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Colors.grey)),
                           Text("${partner.baseRate.toStringAsFixed(0)}€", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green)),
                         ],
                       ),
                     ),
                  _circleAction(Icons.phone_rounded, Colors.green, () => _callPartner(partner.phone)),
                  const SizedBox(width: 4),
                  _circleAction(Icons.person_remove_rounded, Colors.redAccent, onRemove),
                ],
              ),
              if (!isWorker) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _smallStatBox("ΣΥΜΦΩΝΗΘΕΝ", "${totalAgreed.toStringAsFixed(0)} €", Colors.blueGrey),
                    _smallStatBox("ΠΛΗΡΩΜΕΝΑ", "${paid.toStringAsFixed(0)} €", Colors.blue),
                    _smallStatBox("ΥΠΟΛΟΙΠΟ", "${remaining.toStringAsFixed(0)} €", remaining > 0 ? Colors.red : Colors.green),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.blue.withValues(alpha: 0.05), color: Colors.blue),
                ),
                if (agreements.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text("ΚΑΤΑΝΟΜΗ ΑΝΑ ΚΑΤΗΓΟΡΙΑ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: agreements.map((a) {
                      final catLabel = AppDestinations.values.firstWhere((d) => d.name == a.category, orElse: () => AppDestinations.GENERAL).label;
                      return InkWell(
                        onTap: () => onEditAgreement(a),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  catLabel, 
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("${a.amount.toInt()}€", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAddAgreement,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text("ΝΕΑ ΣΥΜΦΩΝΙΑ / ΚΑΤΗΓΟΡΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.blue.withValues(alpha: 0.05),
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.withValues(alpha: 0.1))),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _circleAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _smallStatBox(String l, String v, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.8), letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: c)),
    ],
  );

  void _callPartner(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
