import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/components/compact_calendar.dart';

class ProjectOverviewScreen extends StatefulWidget {
  final Project project;
  final Function(int) onModuleClick;

  const ProjectOverviewScreen({super.key, required this.project, required this.onModuleClick});

  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen> {
  late Future<ProjectROIData> _roiFuture;

  @override
  void initState() {
    super.initState();
    _roiFuture = Provider.of<ProjectProvider>(context, listen: false)
        .calculateProjectROIData(widget.project.id)
        .timeout(const Duration(seconds: 3), onTimeout: () => ProjectROIData(quoteAmount: 0, actualIncome: 0, laborCosts: 0, materialExpenses: 0, fixedCostsContribution: 0, netProfit: 0, roiPercentage: 0, realNetProfit: 0, realRoiPercentage: 0));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final projectTasks = provider.tasks.where((t) => t.projectId == widget.project.id).toList();

        return FutureBuilder<ProjectROIData>(
          future: _roiFuture,
          builder: (context, snapshot) {
            final roi = snapshot.data;
            final income = roi?.actualIncome ?? 0.0;
            final labor = roi?.laborCosts ?? 0.0;
            final materials = roi?.materialExpenses ?? 0.0;
            final quote = roi?.quoteAmount ?? 0.0;
            final balance = income - (labor + materials);

            return ListView(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              children: [
                if (isDesktop) 
                  _buildDesktopLayout(context, provider, income, labor, materials, quote, balance, projectTasks)
                else 
                  _buildMobileLayout(context, provider, income, labor, materials, quote, balance, projectTasks),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ProjectProvider provider, double income, double labor, double materials, double quote, double balance, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _PremiumProjectSummaryCard(
                    netBalance: balance,
                    income: income,
                    quoteRevenue: quote,
                    labor: labor,
                    materials: materials,
                  ),
                  const SizedBox(height: 32),
                  _PremiumClientCard(project: widget.project),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _PremiumCalendarCard(tasks: tasks),
                  const SizedBox(height: 32),
                  _PremiumProjectAlertsCard(projectId: widget.project.id, tasks: tasks),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        const PremiumHeader(title: "ΓΡΗΓΟΡΕΣ ΕΝΕΡΓΕΙΕΣ", color: Color(0xFF4361EE), icon: Icons.bolt_rounded),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 2.2,
          children: [
            _PremiumModuleCard(label: "Προσφορά", icon: Icons.assignment_rounded, color: Colors.indigo, onClick: () => widget.onModuleClick(1)),
            _PremiumModuleCard(label: "Ημερολόγιο", icon: Icons.today_rounded, color: const Color(0xFF4361EE), onClick: () => widget.onModuleClick(3)),
            _PremiumModuleCard(label: "Διαχείριση", icon: Icons.settings_suggest_rounded, color: const Color(0xFF7209B7), onClick: () => widget.onModuleClick(4)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ProjectProvider provider, double income, double labor, double materials, double quote, double balance, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _PremiumProjectSummaryCard(
            netBalance: balance,
            income: income,
            quoteRevenue: quote,
            labor: labor,
            materials: materials,
            isMobile: true,
          ),
          const SizedBox(height: 24),
          _PremiumClientCard(project: widget.project),
          const SizedBox(height: 32),
          _PremiumCalendarCard(tasks: tasks),
          const SizedBox(height: 32),
          const PremiumHeader(title: "ΓΡΗΓΟΡΕΣ ΕΝΕΡΓΕΙΕΣ", color: Color(0xFF4361EE), icon: Icons.bolt_rounded),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _QuickActionItem(label: "ΠΡΟΣΦΟΡΑ", icon: Icons.assignment_rounded, color: Colors.indigo, width: double.infinity, onClick: () => widget.onModuleClick(1))),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionItem(label: "ΗΜΕΡΟΛΟΓΙΟ", icon: Icons.today_rounded, color: const Color(0xFF4361EE), width: double.infinity, onClick: () => widget.onModuleClick(3))),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionItem(label: "ΚΕΝΤΡΟ ΔΙΑΧΕΙΡΙΣΗΣ", icon: Icons.settings_suggest_rounded, color: const Color(0xFF7209B7), width: double.infinity, onClick: () => widget.onModuleClick(4)),
          const SizedBox(height: 60),
      ],
    );
  }
}

class _PremiumProjectSummaryCard extends StatelessWidget {
  final double netBalance, income, quoteRevenue, labor, materials;
  final bool isMobile;
  const _PremiumProjectSummaryCard({required this.netBalance, required this.income, required this.quoteRevenue, required this.labor, required this.materials, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final totalSpent = labor + materials;
    final progress = quoteRevenue > 0 ? (totalSpent / quoteRevenue).clamp(0.0, 1.0) : 0.0;
    final collectionRate = quoteRevenue > 0 ? (income / quoteRevenue).clamp(0.0, 1.0) : 0.0;
    final color = netBalance >= 0 ? const Color(0xFF38B000) : const Color(0xFFEF4444);

    return PremiumCard(
      accentColor: Colors.blue,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PremiumHeader(title: "ΟΙΚΟΝΟΜΙΚΗ ΕΠΙΣΚΟΠΗΣΗ", color: Colors.blue),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("${netBalance.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color, letterSpacing: -0.5)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _summaryRow("ΣΥΝΟΛΟ ΠΡΟΣΦΟΡΑΣ", quoteRevenue, Colors.blueGrey, Icons.assignment_rounded),
          const SizedBox(height: 12),
          _summaryRow("ΣΥΝΟΛΟ ΕΙΣΠΡΑΞΕΩΝ", income, Colors.blue, Icons.payments_rounded, trailing: "${(collectionRate * 100).toInt()}%"),
          const SizedBox(height: 12),
          _summaryRow("ΚΕΡΔΟΣ (ΠΡΑΓΜΑΤΙΚΟ)", netBalance, color, Icons.account_balance_wallet_rounded, isBold: true),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(),
          ),
          
          Row(
            children: [
              Expanded(child: _miniStat("Εργατικά", labor, const Color(0xFF4361EE))),
              Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(child: _miniStat("Υλικά", materials, Colors.orange)),
              if (!isMobile) ...[
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${(progress * 100).toInt()}% Απορρόφηση", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(4), color: Colors.blue, backgroundColor: Colors.blue.withValues(alpha: 0.05)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color color, IconData icon, {String? trailing, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.9), letterSpacing: 0.5)),
          const Spacer(),
          if (trailing != null) ...[
            Text(trailing, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6))),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${amount.toStringAsFixed(2)} €", 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: isBold ? 18 : 15, color: color, letterSpacing: -0.2)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text("${amount.toStringAsFixed(0)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: -0.5)),
      ],
    );
  }
}

class _PremiumClientCard extends StatelessWidget {
  final Project project;
  const _PremiumClientCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: Colors.blueGrey,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: "ΣΤΟΙΧΕΙΑ ΠΕΛΑΤΗ", icon: Icons.person_pin_rounded, color: Colors.blueGrey),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  Icons.phone_android_rounded, 
                  "ΤΗΛΕΦΩΝΟ", 
                  project.clientPhone.isEmpty ? "-" : project.clientPhone, 
                  Colors.blue,
                  onTap: () => project.clientPhone.isNotEmpty ? launchUrl(Uri.parse("tel:${project.clientPhone}")) : null
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoRow(
                  Icons.email_rounded, 
                  "EMAIL", 
                  project.clientEmail.isEmpty ? "-" : project.clientEmail, 
                  Colors.purple,
                  onTap: () => project.clientEmail.isNotEmpty ? launchUrl(Uri.parse("mailto:${project.clientEmail}")) : null
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_rounded, 
            "ΔΙΕΥΘΥΝΣΗ ΕΡΓΟΥ", 
            project.address.isEmpty ? "-" : project.address, 
            Colors.orange,
            onTap: () => project.address.isNotEmpty ? launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(project.address)}")) : null
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                  Text(
                    value, 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onTap != null && value != "-" ? Colors.blue : const Color(0xFF334155)),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
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

class _PremiumCalendarCard extends StatelessWidget {
  final List<Task> tasks;
  const _PremiumCalendarCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: CompactCalendar(tasks: tasks),
    );
  }
}

class _PremiumProjectAlertsCard extends StatelessWidget {
  final int projectId;
  final List<Task> tasks;
  const _PremiumProjectAlertsCard({required this.projectId, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();

    return PremiumCard(
      accentColor: Colors.orange,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: "ΕΙΔΟΠΟΙΗΣΕΙΣ ΕΡΓΟΥ", icon: Icons.notification_important_rounded, color: Colors.orange),
          const SizedBox(height: 24),
          if (pendingTasks.isEmpty)
            const Center(child: Text("Όλα σε τάξη", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)))
          else
            ...pendingTasks.take(4).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF451A03)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }
}

class _PremiumModuleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;
  const _PremiumModuleCard({required this.label, required this.icon, required this.color, required this.onClick});
  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      accentColor: color,
      onTap: onClick,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 13, letterSpacing: 0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double width;
  final VoidCallback onClick;

  const _QuickActionItem({required this.label, required this.icon, required this.color, required this.width, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      accentColor: color,
      onTap: onClick,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }
}
