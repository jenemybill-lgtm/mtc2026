import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/manage_prices_screen.dart';
import 'package:mtc2026/ui/screens/vehicle_log_screen.dart';
import 'package:mtc2026/ui/screens/global_calendar_screen.dart';
import 'package:mtc2026/ui/screens/weekly_payroll_screen.dart';
import 'package:mtc2026/ui/screens/location_selector_screen.dart';
import 'package:mtc2026/ui/screens/tool_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/partners_screen.dart';
import 'package:mtc2026/ui/screens/clients_screen.dart';
import 'package:mtc2026/ui/screens/company_expenses_screen.dart';
import 'package:mtc2026/ui/screens/market_archive_screen.dart';
import 'package:mtc2026/ui/screens/job_recipes_screen.dart';
import 'package:mtc2026/ui/screens/global_payroll_screen.dart';
import 'package:mtc2026/ui/screens/managers_screen.dart';
import 'package:mtc2026/ui/screens/human_resources_screen.dart';
import 'package:mtc2026/ui/screens/materials_management_screen.dart';
import 'package:mtc2026/ui/screens/jobs_management_screen.dart';

class CompanyHubScreen extends StatefulWidget {
  const CompanyHubScreen({super.key});

  @override
  State<CompanyHubScreen> createState() => _CompanyHubScreenState();
}

class _CompanyHubScreenState extends State<CompanyHubScreen> {
  String _viewMode = "MAIN";

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return WillPopScope(
      onWillPop: () async {
        if (_viewMode != "MAIN") {
          setState(() => _viewMode = "MAIN");
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE2E8F0),
        appBar: AppBar(
          title: Text(
            _viewMode == "MATERIALS"
                ? "ΔΙΑΧΕΙΡΙΣΗ ΥΛΙΚΟΥ"
                : _viewMode == "JOBS"
                    ? "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΣΙΩΝ"
                    : "ΚΕΝΤΡΟ ΕΛΕΓΧΟΥ",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_viewMode == "MAIN") {
                Navigator.pop(context);
              } else {
                setState(() => _viewMode = "MAIN");
              }
            },
          ),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: _buildBody(isDesktop),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    switch (_viewMode) {
      case "MATERIALS":
        return _buildMaterialsGrid(isDesktop);
      case "JOBS":
        return _buildJobsGrid(isDesktop);
      default:
        return _buildMainOptions(isDesktop);
    }
  }

  Widget _buildMainOptions(bool isDesktop) {
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
      children: [
        const SizedBox(height: 20),
        _PremiumHubCategoryCard(
          label: "ΑΝΘΡΩΠΙΝΟ ΔΥΝΑΜΙΚΟ",
          subtitle: "Συνεργάτες, Παρουσιολόγιο, Πελάτες & Υπεύθυνοι Έργων",
          icon: Icons.badge_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HumanResourcesScreen())),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 16),
        _PremiumHubCategoryCard(
          label: "ΔΙΑΧΕΙΡΙΣΗ ΥΛΙΚΟΥ",
          subtitle: "Αποθήκη, Βαν, Εργαλεία & Οχήματα",
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MaterialsManagementScreen())),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 16),
        _PremiumHubCategoryCard(
          label: "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΑΣΙΩΝ",
          subtitle: "Ταμείο, Τιμοκατάλογος, Αγορές & Συνταγές",
          icon: Icons.engineering_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JobsManagementScreen())),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 16),
        _PremiumHubCategoryCard(
          label: "ΗΜΕΡΟΛΟΓΙΟ",
          subtitle: "Πρόγραμμα, Παραδόσεις & Ραντεβού",
          icon: Icons.date_range_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalCalendarScreen())),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 16),
        _PremiumHubCategoryCard(
          label: "ΟΙΚΟΝΟΜΙΚΑ ΕΤΑΙΡΕΙΑΣ",
          subtitle: "Πάγια Έξοδα, Ισολογισμός & ΦΠΑ",
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFF4361EE),
          onClick: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyExpensesScreen())),
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 32),
        _buildAllProjectsNotesSection(context, isDesktop),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAllProjectsNotesSection(BuildContext context, bool isDesktop) {
    final provider = Provider.of<ProjectProvider>(context);
    return FutureBuilder<List<ProjectNote>>(
      future: DatabaseHelper().getAllProjectNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        return PremiumCard(
          accentColor: const Color(0xFFFF9800),
          padding: EdgeInsets.all(isDesktop ? 28 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PremiumHeader(
                    title: "ΣΗΜΕΙΩΣΕΙΣ ΟΛΩΝ ΤΩΝ ΕΡΓΩΝ",
                    icon: Icons.assignment_rounded,
                    color: Color(0xFFFF9800),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _showNoteDialog(context, provider),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Δεν υπάρχουν καταγεγραμμένες σημειώσεις στα έργα. Πατήστε + για προσθήκη.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                isDesktop && notes.length >= 2
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 165,
                        ),
                        itemCount: notes.length,
                        itemBuilder: (context, index) => _buildNoteCardItem(context, notes[index], provider),
                      )
                    : Column(
                        children: notes.map((note) => _buildNoteCardItem(context, note, provider)).toList(),
                      ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteCardItem(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note.dateAdded));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showNoteOptions(context, note, provider),
          onLongPress: () => _showNoteOptions(context, note, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          proj.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, ProjectNote note, ProjectProvider provider) {
    final proj = provider.projects.firstWhere(
      (p) => p.id == note.projectId,
      orElse: () => Project(name: "ΕΡΓΟ #${note.projectId}", clientName: "", address: ""),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(proj.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                ),
                const SizedBox(width: 8),
                const Text("ΕΠΙΛΟΓΕΣ ΣΗΜΕΙΩΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              ),
              title: const Text("Επεξεργασία Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(context, provider, noteToEdit: note);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: const Text("Διαγραφή Σημείωσης", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await provider.deleteProjectNote(note.projectId, note.id);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, ProjectProvider provider, {ProjectNote? noteToEdit}) {
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχουν έργα για προσθήκη σημείωσης.")),
      );
      return;
    }

    int? selectedProjectId = noteToEdit?.projectId ?? provider.projects.first.id;
    final noteController = TextEditingController(text: noteToEdit?.content ?? "");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: PremiumHeader(
            title: noteToEdit == null ? "ΝΕΑ ΣΗΜΕΙΩΣΗ ΕΡΓΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΣΗΜΕΙΩΣΗΣ",
            icon: noteToEdit == null ? Icons.note_add_rounded : Icons.edit_note_rounded,
            color: const Color(0xFFFF9800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: selectedProjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Επιλογή Έργου",
                  prefixIcon: Icon(Icons.business_center_rounded),
                  border: OutlineInputBorder(),
                ),
                items: provider.projects.map((p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedProjectId = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Περιεχόμενο Σημείωσης",
                  hintText: "Γράψτε εδώ τη σημείωσή σας...",
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = noteController.text.trim();
                if (content.isNotEmpty && selectedProjectId != null) {
                  if (noteToEdit == null) {
                    await provider.addProjectNote(
                      ProjectNote(
                        projectId: selectedProjectId!,
                        content: content,
                        dateAdded: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                  } else {
                    await provider.updateProjectNote(
                      noteToEdit.copyWith(
                        projectId: selectedProjectId!,
                        content: content,
                      ),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: Text(noteToEdit == null ? "ΠΡΟΣΘΗΚΗ" : "ΑΠΟΘΗΚΕΥΣΗ", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsGrid(bool isDesktop) {
    final hubs = [
      _HomeHub(label: "ΑΠΟΘΗΚΗ", icon: Icons.warehouse_rounded, id: "LOCATION_WAREHOUSE", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΒΑΝ / ΑΜΑΞΙ", icon: Icons.local_shipping_rounded, id: "LOCATION_VAN", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΔΙΑΧΕΙΡΙΣΗ ΒΑΝ", icon: Icons.directions_car_rounded, id: "VEHICLE_LOG", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΟΛΟ ΕΡΓΑΛΕΙΩΝ", icon: Icons.home_repair_service_rounded, id: "TOTAL_TOOLS_PICKER", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΕΡΓΕΙΟ", icon: Icons.build_rounded, id: "REPAIR_TOOLS", color: const Color(0xFF4361EE)),
    ];
    return _HubGrid(hubs: hubs, isDesktop: isDesktop);
  }

  Widget _buildJobsGrid(bool isDesktop) {
    final hubs = [
      _HomeHub(label: "ΑΝΘΡΩΠΙΝΟ ΔΥΝΑΜΙΚΟ", icon: Icons.badge_rounded, id: "HUMAN_RESOURCES", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΕΡΓΑΤΕΣ", icon: Icons.groups_rounded, id: "PARTNERS", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΚΕΝΤΡΙΚΟ ΤΑΜΕΙΟ", icon: Icons.account_balance_wallet_rounded, id: "GLOBAL_PAYROLL", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΠΑΡΟΥΣΙΟΛΟΓΙΟ", icon: Icons.price_check_rounded, id: "WEEKLY_PAYROLL", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΠΡΟΤΥΠΑ ΤΙΜΩΝ", icon: Icons.style_rounded, id: "MANAGE_PRICES", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΑΡΧΕΙΟ ΑΓΟΡΩΝ", icon: Icons.archive_rounded, id: "MARKET_ARCHIVE", color: const Color(0xFF4361EE)),
      _HomeHub(label: "ΣΥΝΤΑΓΕΣ ΕΡΓΩΝ", icon: Icons.auto_fix_high_rounded, id: "JOB_RECIPES", color: const Color(0xFF4361EE)),
    ];
    return _HubGrid(hubs: hubs, isDesktop: isDesktop);
  }
}

class _PremiumHubCategoryCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;
  final bool isDesktop;

  const _PremiumHubCategoryCard({required this.label, required this.subtitle, required this.icon, required this.color, required this.onClick, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return PremiumPageNavButtonFilled(
      text: label,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onPressed: onClick,
    );
  }
}
class _HomeHub {
  final String label;
  final IconData icon;
  final String id;
  final Color color;
  _HomeHub({required this.label, required this.icon, required this.id, required this.color});
}

class _HubGrid extends StatelessWidget {
  final List<_HomeHub> hubs;
  final bool isDesktop;
  const _HubGrid({required this.hubs, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: isDesktop ? 16 : 12,
        mainAxisSpacing: isDesktop ? 16 : 12,
        childAspectRatio: isDesktop ? 1.6 : 1.1,
      ),
      itemCount: hubs.length,
      itemBuilder: (context, index) {
        final hub = hubs[index];
        return _PremiumHubCard(
          hub: hub,
          isDesktop: isDesktop,
          onClick: () {
            if (hub.id == "HUMAN_RESOURCES") Navigator.push(context, MaterialPageRoute(builder: (context) => const HumanResourcesScreen()));
            else if (hub.id == "PARTNERS") Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnersScreen()));
            else if (hub.id == "CLIENTS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
            else if (hub.id == "GLOBAL_PAYROLL") Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalPayrollScreen()));
            else if (hub.id == "LOCATION_WAREHOUSE") Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSelectorScreen(locationName: "ΑΠΟΘΗΚΗ", locationType: "WAREHOUSE")));
            else if (hub.id == "LOCATION_VAN") Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSelectorScreen(locationName: "ΒΑΝ / ΑΜΑΞΙ", locationType: "VAN")));
            else if (hub.id == "VEHICLE_LOG") Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleLogScreen()));
            else if (hub.id == "TOTAL_TOOLS_PICKER") Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolCategoryPickerScreen(title: "ΣΥΝΟΛΟ ΕΡΓΑΛΕΙΩΝ", locationType: "TOTAL")));
            else if (hub.id == "REPAIR_TOOLS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolCategoryPickerScreen(title: "ΣΥΝΕΡΓΕΙΟ ΕΠΙΣΚΕΥΩΝ", locationType: "REPAIR")));
            else if (hub.id == "WEEKLY_PAYROLL") Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPayrollScreen()));
            else if (hub.id == "CALENDAR") Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalCalendarScreen()));
            else if (hub.id == "MANAGE_PRICES") Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePricesScreen()));
            else if (hub.id == "ECONOMICS") Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyExpensesScreen()));
            else if (hub.id == "MARKET_ARCHIVE") Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketArchiveScreen()));
            else if (hub.id == "JOB_RECIPES") Navigator.push(context, MaterialPageRoute(builder: (context) => const JobRecipesScreen()));
            else if (hub.id == "MANAGERS") Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagersScreen()));
          },
        );
      },
    );
  }
}

class _PremiumHubCard extends StatelessWidget {
  final _HomeHub hub;
  final bool isDesktop;
  final VoidCallback onClick;

  const _PremiumHubCard({required this.hub, required this.isDesktop, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hub.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(hub.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hub.label.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: isDesktop ? 12 : 11, 
                      color: Colors.white, 
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
