import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/project_economics_screen.dart';
import 'package:mtc2026/ui/screens/project_photos_screen.dart';
import 'package:mtc2026/ui/screens/project_documents_screen.dart';
import 'package:mtc2026/ui/screens/project_sketches_screen.dart';
import 'package:mtc2026/ui/screens/project_timeline_screen.dart';
import 'package:mtc2026/ui/screens/shopping_list_screen.dart';
import 'package:mtc2026/ui/screens/tool_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/material_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/invoices_materials_screen.dart';
import 'package:mtc2026/ui/screens/financial_charts_screen.dart';
import 'package:mtc2026/ui/screens/weekly_payroll_screen.dart';
import 'package:mtc2026/ui/screens/project_partners_screen.dart';
import 'package:mtc2026/ui/screens/project_checklist_screen.dart';
import 'package:mtc2026/ui/screens/project_material_needs_screen.dart';
import 'package:mtc2026/ui/screens/project_notes_screen.dart';
import 'package:mtc2026/ui/screens/project_specifications_screen.dart';

class ProjectManagementHubScreen extends StatefulWidget {
  final Project project;

  const ProjectManagementHubScreen({super.key, required this.project});

  @override
  State<ProjectManagementHubScreen> createState() => _ProjectManagementHubScreenState();
}

class _ProjectManagementHubScreenState extends State<ProjectManagementHubScreen> {
  late Future<List<Partner>> _partnersFuture;
  late Future<List<MaterialEntity>> _materialsFuture;
  late Future<List<ProjectPhotoEntity>> _photosFuture;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    _loadFutures(provider);
  }

  void _loadFutures(ProjectProvider provider) {
    _partnersFuture = provider.getPartnersForProject(widget.project.id);
    _materialsFuture = provider.getMaterials(widget.project.id, "PROJECT", "ΟΛΑ");
    _photosFuture = provider.getProjectPhotos(widget.project.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1300),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          children: [
            if (isDesktop)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 32,
                  crossAxisSpacing: 32,
                  childAspectRatio: 2.4,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => _buildCategoryCard(context, index, widget.project, provider, isDesktop),
              )
            else
              Column(
                children: [
                  _buildCategoryCard(context, 0, widget.project, provider, false),
                  const SizedBox(height: 16),
                  _buildCategoryCard(context, 1, widget.project, provider, false),
                  const SizedBox(height: 16),
                  _buildCategoryCard(context, 2, widget.project, provider, false),
                  const SizedBox(height: 16),
                  _buildCategoryCard(context, 3, widget.project, provider, false),
                ],
              ),
            const SizedBox(height: 32),
            _buildProjectNotesSection(context, provider),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, int index, Project project, ProjectProvider provider, bool isDesktop) {
    if (index == 0) {
      return _ManagementCategoryCard(
        title: "ΟΙΚΟΝΟΜΙΚΗ ΔΙΑΧΕΙΡΙΣΗ",
        subtitle: "Έξοδα, Γραφήματα & Timeline",
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF0EA5E9),
        onClick: () => _openCategory(context, "ΟΙΚΟΝΟΜΙΚΗ ΔΙΑΧΕΙΡΙΣΗ", [
          _MgmtModule("Οικονομικά", Icons.account_balance_rounded, const Color(0xFF0EA5E9), ProjectEconomicsScreen(project: project)),
          _MgmtModule("Γραφήματα", Icons.pie_chart_rounded, const Color(0xFF0284C7), FutureBuilder<Map<String, dynamic>>(
            future: _prepareChartData(provider, project.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return FinancialChartsScreen(
                projectName: project.name,
                roiData: snapshot.data!['roi'],
                detailedBreakdown: snapshot.data!['breakdown'],
              );
            },
          )),
          _MgmtModule("Τιμολόγια", Icons.receipt_rounded, const Color(0xFF0369A1), InvoicesMaterialsScreen(expenses: provider.currentProjectExpenses, onDelete: (e) => provider.deleteExpense(project.id, e.id))),
          _MgmtModule("Προδιαγραφές Υλικών", Icons.verified_rounded, Colors.teal, ProjectSpecificationsScreen(project: project)),
          _MgmtModule("Checklist", Icons.fact_check_rounded, Colors.orange, ProjectChecklistScreen(project: project)),
          _MgmtModule("Timeline", Icons.timeline_rounded, const Color(0xFFFF9F1C), ProjectTimelineScreen(projectId: project.id)),
        ]),
        isDesktop: isDesktop,
      );
    } else if (index == 1) {
      return FutureBuilder<List<Partner>>(
        future: _partnersFuture,
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _ManagementCategoryCard(
            title: "ΠΡΟΣΩΠΙΚΟ ΕΡΓΟΥ",
            subtitle: "$count Συνεργάτες • Παρουσίες",
            icon: Icons.groups_rounded,
            color: const Color(0xFF10B981),
            onClick: () => _openCategory(context, "ΠΡΟΣΩΠΙΚΟ ΕΡΓΟΥ", [
              _MgmtModule("Συνεργάτες Έργου", Icons.assignment_ind_rounded, const Color(0xFF10B981), ProjectPartnersScreen(project: project)),
              _MgmtModule("Παρουσιολόγιο", Icons.how_to_reg_rounded, const Color(0xFF047857), WeeklyPayrollScreen(projectId: project.id, projectName: project.name)),
            ]),
            isDesktop: isDesktop,
            badge: count.toString(),
          );
        }
      );
    } else if (index == 2) {
      return FutureBuilder<List<MaterialEntity>>(
        future: _materialsFuture,
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _ManagementCategoryCard(
            title: "ΥΛΙΚΑ & ΕΞΟΠΛΙΣΜΟΣ",
            subtitle: "$count Είδη • Εργαλεία & Ελλείψεις",
            icon: Icons.inventory_rounded,
            color: const Color(0xFF6366F1),
            onClick: () => _openCategory(context, "ΥΛΙΚΑ & ΕΞΟΠΛΙΣΜΟΣ", [
              _MgmtModule("Ανάγκες", Icons.fact_check_rounded, const Color(0xFF6366F1), ProjectMaterialNeedsScreen(project: project)),
              _MgmtModule("Εργαλεία", Icons.build_rounded, const Color(0xFF4F46E5), ToolCategoryPickerScreen(title: "ΕΡΓΑΛΕΙΑ ΕΡΓΟΥ", locationType: "PROJECT", locationId: project.id)),
              _MgmtModule("Υλικά", Icons.inventory_rounded, const Color(0xFF4338CA), MaterialCategoryPickerScreen(title: "ΥΛΙΚΑ ΕΡΓΟΥ", locationType: "PROJECT", projectId: project.id)),
              _MgmtModule("Ελλείψεις", Icons.shopping_cart_rounded, const Color(0xFF818CF8), ShoppingListScreen(projectId: project.id)),
            ]),
            isDesktop: isDesktop,
            badge: count.toString(),
          );
        }
      );
    } else {
      return FutureBuilder<List<ProjectPhotoEntity>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _ManagementCategoryCard(
            title: "ΓΕΝΙΚΑ ΕΡΓΟΥ",
            subtitle: "$count Φωτογραφίες • Έγγραφα & Σχέδια",
            icon: Icons.folder_special_rounded,
            color: const Color(0xFF607D8B),
            onClick: () => _openCategory(context, "ΓΕΝΙΚΑ ΕΡΓΟΥ", [
              _MgmtModule("Φωτογραφίες", Icons.camera_roll_rounded, const Color(0xFF64748B), ProjectPhotosScreen(projectId: project.id)),
              _MgmtModule("Έγγραφα", Icons.folder_copy_rounded, const Color(0xFF475569), ProjectDocumentsScreen(projectId: project.id)),
                  _MgmtModule("Σχέδια", Icons.edit_rounded, const Color(0xFF334155), ProjectSketchesScreen(projectId: project.id)),
              _MgmtModule("Checklist", Icons.fact_check_rounded, Colors.orange, ProjectChecklistScreen(project: project)),
              _MgmtModule("Σημειωματάριο", Icons.notes_rounded, Colors.blue, ProjectNotesScreen(project: project)),
            ]),
            isDesktop: isDesktop,
            badge: count.toString(),
          );
        }
      );
    }
  }

  Future<Map<String, dynamic>> _prepareChartData(ProjectProvider provider, int projectId) async {
    final breakdown = await provider.getProjectDetailedBreakdown(projectId);
    final roi = await provider.calculateProjectROIData(projectId);
    return {'breakdown': breakdown, 'roi': roi};
  }

  Widget _buildProjectNotesSection(BuildContext context, ProjectProvider provider) {
    return FutureBuilder<List<ProjectNote>>(
      future: DatabaseHelper().getProjectNotes(widget.project.id),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        return PremiumCard(
          accentColor: const Color(0xFFFF9800),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PremiumHeader(
                    title: "ΣΗΜΕΙΩΣΕΙΣ ΕΡΓΟΥ",
                    icon: Icons.note_alt_rounded,
                    color: Color(0xFFFF9800),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectNotesScreen(project: widget.project),
                        ),
                      ).then((_) => setState(() {}));
                    },
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
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Δεν υπάρχουν σημειώσεις για αυτό το έργο. Πατήστε + για προσθήκη.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Column(
                  children: notes.map((note) {
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note.dateAdded));
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
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
                          onTap: () => _showNoteOptions(context, provider, note),
                          onLongPress: () => _showNoteOptions(context, provider, note),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text(dateStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(note.content, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditNoteDialog(BuildContext context, ProjectProvider provider, ProjectNote note) {
    final noteController = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const PremiumHeader(
          title: "ΕΠΕΞΕΡΓΑΣΙΑ ΣΗΜΕΙΩΣΗΣ",
          icon: Icons.edit_note_rounded,
          color: Color(0xFFFF9800),
        ),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = noteController.text.trim();
              if (content.isNotEmpty) {
                await provider.updateProjectNote(note.copyWith(content: content));
                if (context.mounted) Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNoteOptions(BuildContext context, ProjectProvider provider, ProjectNote note) {
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
                  child: Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
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
                _showEditNoteDialog(context, provider, note);
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
                await provider.deleteProjectNote(widget.project.id, note.id);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, String title, List<_MgmtModule> modules) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => ProjectManagementCategoryScreen(title: title, modules: modules),
        transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
      ),
    );
  }
}

class _MgmtModule {
  final String label;
  final IconData icon;
  final Color color;
  final Widget screen;
  _MgmtModule(this.label, this.icon, this.color, this.screen);
}

class ProjectManagementCategoryScreen extends StatelessWidget {
  final String title;
  final List<_MgmtModule> modules;

  const ProjectManagementCategoryScreen({super.key, required this.title, required this.modules});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: isDesktop ? 1.4 : 1.1,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final m = modules[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [m.color.withValues(alpha: 0.1), m.color.withValues(alpha: 0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: m.color.withValues(alpha: 0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: m.color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => m.screen)),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [m.color, m.color.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Icon(m.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            m.label.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: Color(0xFF1E293B))
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ManagementCategoryCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;
  final bool isDesktop;
  final String? badge;

  const _ManagementCategoryCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onClick, required this.isDesktop, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: isDesktop ? 60 : 52,
                      height: isDesktop ? 60 : 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: isDesktop ? 28 : 24),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          fontSize: 15, 
                          letterSpacing: 0.5
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.toUpperCase(), 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8), 
                          fontSize: 10, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 0.5
                        ), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.5), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
