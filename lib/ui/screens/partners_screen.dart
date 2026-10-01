import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/ui/screens/aluminum_ai_training_screen.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final partners = projectProvider.partners;
    final groupedPartners = _groupPartnersByTrade(partners);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text("ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΤΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () => PdfGenerator.generateAndSharePartnerList(partners: partners, settings: projectProvider.settings),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => ExcelExporter.exportPartners(partners),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPartnerDialog(context),
        label: const Text("ΝΕΟΣ ΕΡΓΑΤΗΣ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: const Color(0xFF38B000),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
          child: partners.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text("Δεν βρέθηκαν καταχωρημένοι εργάτες", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
            )
          : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: groupedPartners.length,
            itemBuilder: (context, index) {
              final trade = groupedPartners.keys.elementAt(index);
              final tradePartners = groupedPartners[trade]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16, top: 8),
                    child: Row(
                      children: [
                        Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF4361EE), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Text(trade.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 11, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 2.5 : 3.8,
                    ),
                    itemCount: tradePartners.length,
                    itemBuilder: (context, i) => _WorkerCardPremium(
                      partner: tradePartners[i],
                      onTap: () => _showPartnerDialog(context, partner: tradePartners[i]),
                      onDelete: () => _showDeleteConfirm(context, tradePartners[i]),
                      onCall: () => _callPartner(tradePartners[i].phone),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Map<String, List<Partner>> _groupPartnersByTrade(List<Partner> partners) {
    final Map<String, List<Partner>> groups = {};
    for (var p in partners) {
      groups.putIfAbsent(p.trade, () => []).add(p);
    }
    return groups;
  }

  void _callPartner(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showPartnerDialog(BuildContext context, {Partner? partner}) {
    showDialog(
      context: context,
      builder: (context) => _PartnerEntryDialog(
        initialPartner: partner,
        onConfirm: (name, phone, trade, rate) {
          if (partner == null) {
            Provider.of<ProjectProvider>(context, listen: false).addPartner(Partner(name: name, phone: phone, trade: trade, baseRate: rate));
          } else {
            Provider.of<ProjectProvider>(context, listen: false).updatePartner(Partner(id: partner.id, name: name, phone: phone, trade: trade, baseRate: rate));
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Partner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΕΡΓΑΤΗ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε τον εργάτη '${partner.name}';"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProjectProvider>(context, listen: false).deletePartner(partner.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ"),
          ),
        ],
      ),
    );
  }
}

class _WorkerCardPremium extends StatelessWidget {
  final Partner partner;
  final VoidCallback onTap, onDelete, onCall;

  const _WorkerCardPremium({required this.partner, required this.onTap, required this.onDelete, required this.onCall});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4361EE);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(partner.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.euro_rounded, size: 10, color: Color(0xFF38B000)),
                          const SizedBox(width: 2),
                          Text("${partner.baseRate.toStringAsFixed(0)} €", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF38B000))),
                          const SizedBox(width: 8),
                          const Icon(Icons.phone_android_rounded, size: 10, color: Colors.blueGrey),
                          const SizedBox(width: 2),
                          Expanded(child: Text(partner.phone, style: const TextStyle(fontSize: 10, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (partner.trade == "Αλουμινάς")
                  IconButton(
                    tooltip: "AI Εκπαίδευση",
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AluminumAiTrainingScreen(partner: partner)));
                    },
                    icon: const Icon(Icons.psychology_rounded, color: Color(0xFF7209B7), size: 20),
                  ),
                const SizedBox(width: 8),
                IconButton(padding: const EdgeInsets.all(4), constraints: const BoxConstraints(), onPressed: onCall, icon: const Icon(Icons.call_rounded, color: Colors.blue, size: 18)),
                const SizedBox(width: 8),
                IconButton(padding: const EdgeInsets.all(4), constraints: const BoxConstraints(), onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerEntryDialog extends StatefulWidget {
  final Partner? initialPartner;
  final Function(String, String, String, double) onConfirm;

  const _PartnerEntryDialog({this.initialPartner, required this.onConfirm});

  @override
  State<_PartnerEntryDialog> createState() => _PartnerEntryDialogState();
}

class _PartnerEntryDialogState extends State<_PartnerEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedTrade;
  late TextEditingController _rateController;

  final List<String> _defaultTrades = ["Εργάτης", "Ανακύκλωση Μπάζων", "Προμηθευτής Μαρμάρων", "Εκσκαφές", "Μπετά", "Χτίστης", "Ηλεκτρολόγος", "Υδραυλικός", "Σοβατζής", "Μαρμαράς", "Πλακάς", "Γυψοσανιδάς", "Μονωτής", "Αλουμινάς", "Ξυλουργός", "Ελαιοχρωματιστής", "Σιδεράς", "Γεμίσματα", "Θερμοπρόσοψη", "Πατωματζής"];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPartner?.name ?? "");
    _phoneController = TextEditingController(text: widget.initialPartner?.phone ?? "");
    _selectedTrade = widget.initialPartner?.trade ?? "Εργάτης";
    _rateController = TextEditingController(text: widget.initialPartner?.baseRate.toString() ?? "0");
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4361EE);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.initialPartner == null ? Icons.person_add_rounded : Icons.edit_rounded, color: color, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.initialPartner == null ? "ΝΕΟΣ ΣΥΝΕΡΓΑΤΗΣ" : "ΕΠΕΞΕΡΓΑΣΙΑ",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    _buildMinimalTextField(_nameController, "Ονοματεπώνυμο", Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildMinimalTextField(_phoneController, "Τηλέφωνο", Icons.phone_outlined, type: TextInputType.phone),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTrade,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Ειδικότητα", 
                        prefixIcon: const Icon(Icons.engineering_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: _defaultTrades.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (v) {
                        setState(() {
                           _selectedTrade = v!;
                           if (_selectedTrade != "Εργάτης") {
                             _rateController.text = "0";
                           }
                        });
                      },
                    ),
                    if (_selectedTrade == "Εργάτης") ...[
                      const SizedBox(height: 16),
                      _buildMinimalTextField(_rateController, "Βασικό Μεροκάματο (€)", Icons.euro_rounded, type: TextInputType.number),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blueGrey)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            widget.onConfirm(_nameController.text, _phoneController.text, _selectedTrade, double.tryParse(_rateController.text) ?? 0.0);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6), // Απαλό γκρι όπως στη φώτο
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4361EE), width: 2)),
      ),
    );
  }
}
