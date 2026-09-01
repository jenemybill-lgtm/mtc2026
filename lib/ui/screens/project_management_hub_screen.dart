import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/project_economics_screen.dart';
import 'package:mtc2026/ui/screens/project_photos_screen.dart';
import 'package:mtc2026/ui/screens/project_documents_screen.dart';
import 'package:mtc2026/ui/screens/project_sketches_screen.dart';
import 'package:mtc2026/ui/screens/project_timeline_screen.dart';
import 'package:mtc2026/ui/screens/shopping_list_screen.dart';
import 'package:mtc2026/ui/screens/partners_screen.dart';
import 'package:mtc2026/ui/screens/tool_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/material_category_picker_screen.dart';
import 'package:mtc2026/ui/screens/invoices_materials_screen.dart';
import 'package:mtc2026/ui/screens/financial_charts_screen.dart';
import 'package:mtc2026/ui/screens/weekly_payroll_screen.dart';
import 'package:mtc2026/ui/screens/project_partners_screen.dart';
import 'package:mtc2026/ui/screens/project_checklist_screen.dart';
import 'package:mtc2026/ui/screens/project_material_needs_screen.dart';
import 'package:mtc2026/ui/screens/project_roi_screen.dart';
import 'package:mtc2026/ui/screens/project_notes_screen.dart';

class ProjectManagementHubScreen extends StatefulWidget {
  final Project project;

  const ProjectManagementHubScreen({super.key, required this.project});

  @override
  State<ProjectManagementHubScreen> createState() => _ProjectManagementHubScreenState();
}

class _ProjectManagementHubScreenState extends State<ProjectManagementHubScreen> {
  late Future<ProjectROIData> _roiFuture;
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
    _roiFuture = provider.calculateProjectROIData(widget.project.id);
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
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, int index, Project project, ProjectProvider provider, bool isDesktop) {
    if (index == 0) {
      return FutureBuilder<ProjectROIData>(
        future: _roiFuture,
        builder: (context, snapshot) {
          final roi = snapshot.data?.roiPercentage ?? 0.0;
          return _ManagementCategoryCard(
            title: "ΟΙΚΟΝΟΜΙΚΗ ΔΙΑΧΕΙΡΙΣΗ",
            subtitle: "ROI: ${roi.toStringAsFixed(1)}% • Έξοδα & Timeline",
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
              _MgmtModule("ROI", Icons.account_balance_wallet_rounded, const Color(0xFF0EA5E9), FutureBuilder<ProjectROIData>(
                future: provider.calculateProjectROIData(project.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ProjectROIScreen(projectName: project.name, roiData: snapshot.data!);
                },
              )),
              _MgmtModule("Timeline", Icons.timeline_rounded, const Color(0xFFFF9F1C), ProjectTimelineScreen(projectId: project.id)),
            ]),
            isDesktop: isDesktop,
            badge: "${roi.toInt()}%",
          );
        }
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
              _MgmtModule("Checklist", Icons.fact_check_rounded, Colors.orange, ProjectChecklistScreen(projectId: project.id)),
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
      backgroundColor: const Color(0xFFF1F5F9),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: isDesktop ? 60 : 52,
                      height: isDesktop ? 60 : 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: isDesktop ? 28 : 24),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13, letterSpacing: 0.2)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.toUpperCase(), 
                        style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
