import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/utils/responsive.dart';

class WorkerDispatchScreen extends StatefulWidget {
  const WorkerDispatchScreen({super.key});

  @override
  State<WorkerDispatchScreen> createState() => _WorkerDispatchScreenState();
}

class _WorkerDispatchScreenState extends State<WorkerDispatchScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow for planning
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = Responsive.isDesktop(context);
    final dateTimestamp = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ΠΡΟΓΡΑΜΜΑΤΙΣΜΟΣ ΑΠΟΣΤΟΛΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text("Οδηγίες, Πού θα πάνε αύριο & WhatsApp", style: TextStyle(fontSize: 10, color: Colors.blueGrey.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDispatchDialog(context, provider),
        label: const Text("ΝΕΑ ΑΠΟΣΤΟΛΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        icon: const Icon(Icons.add_location_alt_rounded),
        backgroundColor: const Color(0xFF4361EE),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: Responsive.maxWidth(context)),
          child: Column(
            children: [
              _buildDateBar(),
              Expanded(
                child: FutureBuilder<List<WorkerDispatch>>(
                  future: provider.getWorkerDispatches(_selectedDate),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final dispatches = snapshot.data!;

                    if (dispatches.isEmpty) {
                      return const PremiumEmptyState(
                        title: "ΔΕΝ ΥΠΑΡΧΟΥΝ ΑΠΟΣΤΟΛΕΣ",
                        subtitle: "Δεν έχετε προγραμματίσει αποστολές εργατών για αυτή την ημερομηνία.\nΠατήστε 'ΝΕΑ ΑΠΟΣΤΟΛΗ' για να ορίσετε πού θα πάνε.",
                        icon: Icons.alt_route_rounded,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      itemCount: dispatches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final dispatch = dispatches[index];
                        final project = provider.projects.firstWhere(
                          (p) => p.id == dispatch.projectId,
                          orElse: () => Project(name: "ΓΕΝΙΚΟ", clientName: "", address: "Χωρίς Διεύθυνση"),
                        );
                        final partner = provider.partners.firstWhere(
                          (p) => p.name == dispatch.workerName,
                          orElse: () => Partner(name: dispatch.workerName, phone: dispatch.workerPhone, trade: "Εργάτης"),
                        );

                        return _DispatchCard(
                          dispatch: dispatch,
                          project: project,
                          partner: partner,
                          onConfirm: () => _confirmDispatch(context, provider, dispatch, partner),
                          onDelete: () async {
                            await provider.deleteWorkerDispatch(dispatch.id);
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBar() {
    final isToday = _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day;
    final isTomorrow = _selectedDate.year == DateTime.now().add(const Duration(days: 1)).year && _selectedDate.month == DateTime.now().add(const Duration(days: 1)).month && _selectedDate.day == DateTime.now().add(const Duration(days: 1)).day;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Column(
                children: [
                  Text(
                    isToday ? "ΣΗΜΕΡΑ" : (isTomorrow ? "ΑΥΡΙΟ (ΠΡΟΓΡΑΜΜΑΤΙΣΜΟΣ)" : DateFormat('EEEE', 'el').format(_selectedDate).toUpperCase()),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF4361EE), letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMMM yyyy', 'el').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  void _showAddDispatchDialog(BuildContext context, ProjectProvider provider) {
    if (provider.partners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Δεν έχετε καταχωρημένους συνεργάτες/εργάτες.")));
      return;
    }
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Δεν έχετε καταχωρημένα έργα.")));
      return;
    }

    Partner selectedPartner = provider.partners.first;
    Project selectedProject = provider.projects.first;
    TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 30);
    final taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4361EE).withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: const PremiumHeader(title: "ΝΕΑ ΑΠΟΣΤΟΛΗ ΕΡΓΑΤΗ", icon: Icons.person_add_alt_1_rounded, color: Color(0xFF4361EE)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ΕΠΙΛΟΓΗ ΕΡΓΑΤΗ / ΣΥΝΕΡΓΑΤΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Partner>(
                          value: selectedPartner,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          items: provider.partners.map((p) => DropdownMenuItem(value: p, child: Text("${p.name.toUpperCase()} (${p.trade})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedPartner = v);
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text("ΕΠΙΛΟΓΗ ΕΡΓΟΥ / ΤΟΠΟΘΕΣΙΑΣ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Project>(
                          value: selectedProject,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          items: provider.projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedProject = v);
                          },
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(context: ctx, initialTime: selectedTime);
                                  if (time != null) setDialogState(() => selectedTime = time);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: Color(0xFF4361EE), size: 18),
                                      const SizedBox(width: 8),
                                      Text("${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: taskController,
                          decoration: InputDecoration(
                            labelText: "Περιγραφή Εργασίας / Οδηγίες",
                            hintText: "π.χ. Γυψοσανίδες στο σαλόνι",
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch;
                              final timeStr = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

                              final dispatch = WorkerDispatch(
                                workerName: selectedPartner.name,
                                workerPhone: selectedPartner.phone,
                                projectId: selectedProject.id,
                                date: startOfDay,
                                timeStr: timeStr,
                                taskDescription: taskController.text.trim(),
                                status: "PENDING",
                              );

                              await provider.addWorkerDispatch(dispatch);
                              if (ctx.mounted) Navigator.pop(ctx);
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4361EE),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("ΑΠΟΣΤΟΛΗ", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDispatch(BuildContext context, ProjectProvider provider, WorkerDispatch dispatch, Partner partner) {
    final rateController = TextEditingController(text: partner.baseRate.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const PremiumHeader(title: "ΕΠΙΒΕΒΑΙΩΣΗ ΠΑΡΟΥΣΙΑΣ", icon: Icons.check_circle_rounded, color: Color(0xFF10B981)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Επιβεβαιώνετε ότι ο εργάτης ${dispatch.workerName.toUpperCase()} προσήλθε κανονικά στο έργο;", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: "Ημερομίσθιο (€)", prefixIcon: Icon(Icons.euro_rounded)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text("Η εγγραφή θα μεταφερθεί αυτόματα στο επίσημο Παρουσιολόγιο.", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateController.text) ?? partner.baseRate;
              await provider.confirmWorkerDispatch(dispatch, rate);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text("ΕΠΙΒΕΒΑΙΩΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final WorkerDispatch dispatch;
  final Project project;
  final Partner partner;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _DispatchCard({
    required this.dispatch,
    required this.project,
    required this.partner,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = dispatch.status == "CONFIRMED";
    final cardColor = isConfirmed ? const Color(0xFF10B981) : const Color(0xFF4361EE);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_pin_circle_rounded, color: cardColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dispatch.workerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                      Text(partner.trade, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfirmed ? "✅ ΕΠΙΒΕΒΑΙΩΘΗΚΕ" : "⏳ ΕΚΚΡΕΜΕΙ",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isConfirmed ? const Color(0xFF10B981) : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 14, color: Color(0xFF4361EE)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Έργο: ${project.name.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B)),
                  ),
                ),
                const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF4361EE)),
                const SizedBox(width: 4),
                Text(dispatch.timeStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF4361EE))),
              ],
            ),
            if (project.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.map_rounded, size: 12, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(project.address, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600))),
                ],
              ),
            ],
            if (dispatch.taskDescription.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build_circle_rounded, size: 12, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(dispatch.taskDescription, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.bold))),
                ],
              ),
            ],
            const SizedBox(height: 14),

            Row(
              children: [
                // WhatsApp Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendWhatsApp(context, dispatch, project),
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text("WHATSAPP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // SMS Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendSMS(context, dispatch, project),
                    icon: const Icon(Icons.sms_rounded, size: 16),
                    label: const Text("SMS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (!isConfirmed) ...[
                  const SizedBox(width: 8),
                  // Confirm Button
                  IconButton(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                    tooltip: "Επιβεβαίωση Παρουσίας",
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  tooltip: "Διαγραφή",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendWhatsApp(BuildContext context, WorkerDispatch dispatch, Project project) async {
    final dateStr = DateFormat('dd/MM/yyyy', 'el').format(DateTime.fromMillisecondsSinceEpoch(dispatch.date));
    final msg = """
👷‍♂️ *MTC 2026 - ΟΔΗΓΙΕΣ ΕΡΓΑΣΙΑΣ*
📅 Ημερομηνία: $dateStr
⏰ Ώρα προσέλευσης: ${dispatch.timeStr}
📍 Έργο: ${project.name.toUpperCase()}
🗺️ Διεύθυνση: ${project.address.isNotEmpty ? project.address : 'Χωρίς Διεύθυνση'}
🛠️ Εργασία: ${dispatch.taskDescription.isNotEmpty ? dispatch.taskDescription : 'Γενικές Εργασίες'}

Παρακαλώ επιβεβαιώστε τη λήψη.
""";

    String cleanPhone = dispatch.workerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('30')) {
        cleanPhone = '+$cleanPhone';
      } else {
        cleanPhone = '+30$cleanPhone';
      }
    }

    final url = "https://wa.me/${cleanPhone.replaceAll('+', '')}?text=${Uri.encodeComponent(msg)}";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα άνοιγματος WhatsApp: $e")));
      }
    }
  }

  void _sendSMS(BuildContext context, WorkerDispatch dispatch, Project project) async {
    final dateStr = DateFormat('dd/MM/yyyy', 'el').format(DateTime.fromMillisecondsSinceEpoch(dispatch.date));
    final msg = """
MTC 2026 ΟΔΗΓΙΕΣ:
Ημερομηνία: $dateStr
Ώρα: ${dispatch.timeStr}
Έργο: ${project.name.toUpperCase()}
Διεύθυνση: ${project.address.isNotEmpty ? project.address : 'Χωρίς Διεύθυνση'}
Εργασία: ${dispatch.taskDescription.isNotEmpty ? dispatch.taskDescription : 'Γενικές Εργασίες'}
""";

    String cleanPhone = dispatch.workerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse("sms:$cleanPhone?body=${Uri.encodeComponent(msg)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα άνοιγματος SMS: $e")));
      }
    }
  }
}
