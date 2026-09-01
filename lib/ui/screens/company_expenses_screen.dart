import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/financial_charts_screen.dart';

class CompanyExpensesScreen extends StatefulWidget {
  final int initialTabIndex;
  const CompanyExpensesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CompanyExpensesScreen> createState() => _CompanyExpensesScreenState();
}

class _CompanyExpensesScreenState extends State<CompanyExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΟΙΚΟΝΟΜΙΚΑ ΕΤΑΙΡΕΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          _buildActionButton(
            context,
            label: "ΕΤΗΣΙΑ ΑΝΑΦΟΡΑ",
            icon: Icons.calendar_month_rounded,
            color: Colors.blue,
            onTap: () => _showYearlyReportDialog(context, provider),
            isDesktop: isDesktop,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            label: "ΕΚΤΥΠΩΣΗ PDF",
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
            onTap: () async {
              final data = await provider.getCompanyAnalyticalFinancials();
              final breakdowns = <int, Map<String, dynamic>>{};
              for (var p in provider.projects) {
                final b = await provider.getProjectDetailedBreakdown(p.id);
                if (b.isNotEmpty) breakdowns[p.id] = b;
              }
              PdfGenerator.generateAndShareCompanyFullReport(
                totalIncomes: data['actualIncome'],
                projectExpenses: data['labor'] + data['materials'],
                generalExpenses: data['fixed'],
                projects: provider.projects,
                detailedBreakdowns: breakdowns,
                settings: provider.settings,
              );
            },
            isDesktop: isDesktop,
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
          tabs: const [
            Tab(text: "ΣΥΝΟΨΗ & ΕΡΓΑ"),
            Tab(text: "ΠΑΓΙΑ & ΣΥΝΤΗΡΗΣΗ"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context),
        label: const Text("ΝΕΟ ΕΞΟΔΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryAndProjectsTab(provider, isDesktop),
          _buildOperationsTab(provider, isDesktop),
        ],
      ),
    );
  }

  Widget _buildSummaryAndProjectsTab(ProjectProvider provider, bool isDesktop) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: FutureBuilder<Map<String, dynamic>>(
          future: provider.getCompanyAnalyticalFinancials(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _AnalyticalBalanceCard(data: data, isDesktop: isDesktop),
                const SizedBox(height: 48),
                const PremiumHeader(title: "ΑΝΑΛΥΣΗ ΚΕΡΔΟΦΟΡΙΑΣ ΑΝΑ ΕΡΓΟ", color: Colors.blue),
                const SizedBox(height: 20),
                _ProjectsProfitabilityList(provider: provider, isDesktop: isDesktop),
                const SizedBox(height: 48),
                const Text("ΤΡΙΜΗΝΙΑΙΑ ΑΝΑΦΟΡΑ ΦΠΑ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 12),
                _QuarterlyVatSection(provider: provider),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOperationsTab(ProjectProvider provider, bool isDesktop) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
             const PremiumHeader(title: "ΠΑΓΙΑ ΕΞΟΔΑ & ΛΕΙΤΟΥΡΓΙΑ", color: Colors.redAccent),
             const SizedBox(height: 24),
             _GeneralExpensesList(provider: provider),
             const SizedBox(height: 48),
             const PremiumHeader(title: "ΣΥΝΤΗΡΗΣΗ ΟΧΗΜΑΤΩΝ", icon: Icons.car_repair_rounded, color: Colors.orange),
             const SizedBox(height: 16),
             _VehicleMaintenanceList(provider: provider),
             const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap, required bool isDesktop}) {
    if (!isDesktop) return IconButton(icon: Icon(icon, color: color), onPressed: onTap);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
        style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  void _showYearlyReportDialog(BuildContext context, ProjectProvider provider) {
    final year = DateTime.now().year;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΕΤΗΣΙΑ ΑΝΑΦΟΡΑ"),
        content: Text("Θέλετε να εκδώσετε την αναλυτική οικονομική αναφορά για το έτος $year;"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final report = await provider.getQuarterlyVatReport();
              PdfGenerator.generateAndShareYearlyTaxReport(year: year, monthlyData: report, settings: provider.settings);
            },
            child: const Text("ΕΚΔΟΣΗ PDF"),
          ),
        ],
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, {CompanyExpenseEntity? initialExpense}) {
    final descController = TextEditingController(text: initialExpense?.description ?? "");
    final totalAmountController = TextEditingController(text: initialExpense?.amount.toString() ?? "");
    final invoiceController = TextEditingController(text: initialExpense?.invoiceNumber ?? "");
    bool hasVat = initialExpense?.hasVat ?? false;
    int date = initialExpense?.date ?? DateTime.now().millisecondsSinceEpoch;
    bool isDistribute = false;
    Map<int, double> projectDistributions = {};
    
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final activeProjects = provider.projects.where((p) => !p.isCompleted).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final totalAmount = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0.0;
          final distributedAmount = projectDistributions.values.fold(0.0, (a, b) => a + b);
          final remainingAmount = totalAmount - distributedAmount;
          final isOverAllocated = distributedAmount > totalAmount + 0.01;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: PremiumHeader(
              title: initialExpense == null ? "ΚΑΤΑΧΩΡΗΣΗ ΕΞΟΔΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΕΞΟΔΟΥ", 
              icon: initialExpense == null ? Icons.add_card_rounded : Icons.edit_note_rounded
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Περιγραφή Εξόδου", prefixIcon: Icon(Icons.description_outlined))),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.fromMillisecondsSinceEpoch(date),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() => date = pickedDate.millisecondsSinceEpoch);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        "ΗΜΕΡΟΜΗΝΙΑ: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(date))}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: totalAmountController, 
                      decoration: const InputDecoration(labelText: "Συνολικό Ποσό (€)", prefixIcon: Icon(Icons.euro_rounded)), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: invoiceController, decoration: const InputDecoration(labelText: "Αρ. Τιμολογίου (Προαιρετικό)", prefixIcon: Icon(Icons.receipt_long_outlined))),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: CheckboxListTile(
                        title: const Text("Περιλαμβάνει ΦΠΑ 24%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), 
                        value: hasVat, 
                        onChanged: (v) => setState(() => hasVat = v!), 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    if (initialExpense == null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text("ΕΠΙΜΕΡΙΣΜΟΣ ΣΕ ΕΡΓΑ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 1)),
                        subtitle: const Text("Μοίρασε το ποσό σε ένα ή περισσότερα έργα", style: TextStyle(fontSize: 9)),
                        value: isDistribute,
                        onChanged: (v) => setState(() => isDistribute = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (isDistribute) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOverAllocated ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isOverAllocated ? "ΥΠΕΡΒΑΣΗ ΠΟΣΟΥ!" : "ΥΠΟΛΟΙΠΟ ΓΙΑ ΜΟΙΡΑΣΜΑ:",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isOverAllocated ? Colors.red : Colors.blue),
                              ),
                              Text(
                                "${remainingAmount.toStringAsFixed(2)} €",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isOverAllocated ? Colors.red : Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...activeProjects.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(hintText: "0.00 €", contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                  onChanged: (v) {
                                    final amt = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                                    setState(() {
                                      if (amt > 0) projectDistributions[p.id] = amt;
                                      else projectDistributions.remove(p.id);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
              ElevatedButton(
                onPressed: (isDistribute && isOverAllocated) ? null : () async {
                  if (descController.text.isEmpty) return;
                  final totalAmount = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0.0;

                  if (isDistribute && initialExpense == null) {
                    for (var entry in projectDistributions.entries) {
                      final projectAmt = entry.value;
                      await provider.addExpense(entry.key, Expense(
                        projectId: entry.key,
                        date: date,
                        description: "[ΕΠΙΜΕΡΙΣΜΟΣ] ${descController.text}",
                        workerName: "ΕΤΑΙΡΕΙΑ / ΑΠΟΘΗΚΗ",
                        amount: projectAmt,
                        hasVat: hasVat,
                        expenseType: invoiceController.text.isNotEmpty ? "INVOICE" : "PAYMENT",
                        invoiceNumber: invoiceController.text.isNotEmpty ? invoiceController.text : null,
                        categoryType: "MATERIAL",
                      ));
                    }
                  } else {
                    final e = CompanyExpenseEntity(
                      id: initialExpense?.id ?? 0,
                      description: descController.text, 
                      amount: totalAmount, 
                      hasVat: hasVat, 
                      invoiceNumber: invoiceController.text.isNotEmpty ? invoiceController.text : null,
                      date: date
                    );
                    if (initialExpense == null) {
                      await provider.addCompanyExpense(e);
                    } else {
                      await provider.updateCompanyExpense(e);
                    }
                  }
                  if (context.mounted) Navigator.pop(context);
                }, 
                child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900))
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticalBalanceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;
  const _AnalyticalBalanceCard({required this.data, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final projectProfit = data['projectProfit'] ?? 0.0;
    final fixedCosts = data['fixed'] ?? 0.0;
    final netProfit = projectProfit - fixedCosts;
    final vatBalance = (data['vatCollected'] ?? 0.0) - (data['vatPaid'] ?? 0.0);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ΓΕΝΙΚΟΣ ΙΣΟΛΟΓΙΣΜΟΣ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                        SizedBox(height: 4),
                        Text("ΟΙΚΟΝΟΜΙΚΗ ΚΑΤΑΣΤΑΣΗ ΕΤΑΙΡΕΙΑΣ", style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isDesktop ? 40.0 : 28.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BigStatItem(label: "ΜΙΚΤΟ ΚΕΡΔΟΣ ΕΡΓΩΝ", amount: projectProfit, color: const Color(0xFF38B000)),
                        _BigStatItem(label: "ΛΕΙΤΟΥΡΓΙΚΑ ΕΞΟΔΑ", amount: fixedCosts, color: Colors.red, align: CrossAxisAlignment.end),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ΠΡΑΓΜΑΤΙΚΟ ΚΑΘΑΡΟ ΚΕΡΔΟΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${netProfit.toStringAsFixed(2)} €", 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900, 
                                    fontSize: isDesktop ? 48 : 36, 
                                    color: netProfit >= 0 ? const Color(0xFF4361EE) : Colors.red,
                                    letterSpacing: -1.5
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: vatBalance >= 0 ? Colors.blue.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (vatBalance >= 0 ? Colors.blue : Colors.red).withValues(alpha: 0.1)),
                            boxShadow: [BoxShadow(color: (vatBalance >= 0 ? Colors.blue : Colors.red).withValues(alpha: 0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                vatBalance >= 0 ? "ΦΠΑ ΠΡΟΣ ΑΠΟΔΟΣΗ" : "ΠΙΣΤΩΤΙΚΟ ΦΠΑ", 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: vatBalance >= 0 ? Colors.blue : Colors.red)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${vatBalance.abs().toStringAsFixed(2)} €", 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: vatBalance >= 0 ? Colors.blue : Colors.red)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _ProjectMoneyStats(data: data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _BigStatItem({required String label, required double amount, required Color color, CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.6), letterSpacing: 1.2)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
        ),
      ],
    );
  }
}

class _ProjectMoneyStats extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProjectMoneyStats({required this.data});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: Colors.blueGrey,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const PremiumHeader(title: "ΑΝΑΛΥΣΗ ΡΟΗΣ", icon: Icons.analytics_rounded, color: Colors.blueGrey),
          const SizedBox(height: 24),
          _moneyRow("ΣΥΝΟΛΙΚΕΣ ΕΙΣΠΡΑΞΕΙΣ (ΚΑΘΑΡΑ)", data['actualIncome'], Colors.blue),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
          _moneyRow("ΣΥΝΟΛΙΚΑ ΕΡΓΑΤΙΚΑ (ΜΕΡΟΚΑΜΑΤΑ)", data['labor'], Colors.blueGrey),
          const SizedBox(height: 12),
          _moneyRow("ΣΥΝΟΛΙΚΑ ΥΛΙΚΑ & ΤΙΜΟΛΟΓΙΑ", data['materials'], Colors.orange),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)),
        Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _ProjectsProfitabilityList extends StatelessWidget {
  final ProjectProvider provider;
  final bool isDesktop;
  const _ProjectsProfitabilityList({required this.provider, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final activeProjects = provider.projects.where((p) => !p.isCompleted).toList();
    return isDesktop
      ? GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 2.5),
          itemCount: activeProjects.length,
          itemBuilder: (context, index) => _ProjectDetailedCard(project: activeProjects[index], provider: provider),
        )
      : Column(children: activeProjects.map((p) => _ProjectDetailedCard(project: p, provider: provider)).toList());
  }
}

class _ProjectDetailedCard extends StatelessWidget {
  final Project project;
  final ProjectProvider provider;
  const _ProjectDetailedCard({required this.project, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectROIData>(
      future: provider.calculateProjectROIData(project.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final roi = snapshot.data!;
        const color = Colors.blue;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.01)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4)),
            ],
          ),
          child: InkWell(
            onTap: () async {
              final breakdown = await provider.getProjectDetailedBreakdown(project.id);
              Navigator.push(context, MaterialPageRoute(builder: (context) => FinancialChartsScreen(projectName: project.name, roiData: roi, detailedBreakdown: breakdown)));
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(width: 45, height: 45, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: (roi.roiPercentage / 100).clamp(0, 1), backgroundColor: Colors.grey.withValues(alpha: 0.1), color: roi.roiPercentage > 20 ? Colors.green : Colors.orange, strokeWidth: 5), Text("${roi.roiPercentage.toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(project.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1),
                          Text(project.clientName, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      const Icon(Icons.analytics_rounded, color: Colors.blue, size: 20),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _smallStat("ΠΡΟΣΦΟΡΑ", roi.quoteAmount),
                      _smallStat("ΚΑΘ. ΚΕΡΔΟΣ", roi.netProfit, color: roi.netProfit >= 0 ? Colors.green : Colors.red),
                      _smallStat("ΕΡΓΑΤΙΚΑ", roi.laborCosts),
                      _smallStat("ΥΛΙΚΑ", roi.materialExpenses),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _smallStat(String label, double amount, {Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey)),
      Text("${amount.toStringAsFixed(0)}€", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _BigStat({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  const _BalanceRow({required this.label, required this.amount, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), 
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.blueGrey),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _QuarterlyVatSection extends StatelessWidget {
  final ProjectProvider provider;
  const _QuarterlyVatSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, Map<String, double>>>(
      future: provider.getQuarterlyVatReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final report = snapshot.data!;
        final quarterTitles = ["Α' ΤΡΙΜΗΝΟ (Ιαν-Μαρ)", "Β' ΤΡΙΜΗΝΟ (Απρ-Ιουν)", "Γ' ΤΡΙΜΗΝΟ (Ιουλ-Σεπ)", "Δ' ΤΡΙΜΗΝΟ (Οκτ-Δεκ)"];
        return Column(
          children: report.entries.map((entry) {
            final balance = entry.value['collected']! - entry.value['paid']!;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                iconColor: Colors.blue,
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  quarterTitles[entry.key],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B)),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: balance >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${balance.toStringAsFixed(2)} €",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: balance >= 0 ? Colors.green : Colors.red),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        _smallVatRow("ΦΠΑ Εισπράξεων:", entry.value['collected']!, Colors.green),
                        const SizedBox(height: 12),
                        _smallVatRow("ΦΠΑ Πληρωμών:", entry.value['paid']!, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  Widget _smallVatRow(String label, double amount, Color color) { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)), Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color))]); }
}

class _GeneralExpensesList extends StatelessWidget {
  final ProjectProvider provider;
  const _GeneralExpensesList({required this.provider});
  @override
  Widget build(BuildContext context) {
    final expenses = provider.companyExpenses;
    if (expenses.isEmpty) return const SizedBox.shrink();
    return Column(
      children: expenses.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withValues(alpha: 0.08), Colors.red.withValues(alpha: 0.01)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.12), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
        ),
        child: InkWell(
          onTap: () => _showExpenseDialog(context, initialExpense: e),
          onLongPress: () => _showExpenseDialog(context, initialExpense: e),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.description.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: Color(0xFF1E293B)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date)),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            if (e.invoiceNumber != null && e.invoiceNumber!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text("ΤΙΜ: ${e.invoiceNumber}", style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${e.amount.toStringAsFixed(2)} €",
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black12),
                      onPressed: () => provider.deleteCompanyExpense(e.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _VehicleMaintenanceList extends StatelessWidget {
  final ProjectProvider provider;
  const _VehicleMaintenanceList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VehicleEntity>(
      future: provider.getVehicle(),
      builder: (context, vSnap) {
        if (!vSnap.hasData) return const SizedBox.shrink();
        final vehicle = vSnap.data!;
        return FutureBuilder<List<VehicleMaintenanceEntity>>(
          future: provider.getMaintenance(vehicle.id),
          builder: (context, mSnap) {
            if (!mSnap.hasData) return const Center(child: CircularProgressIndicator());
            final maintenance = mSnap.data!;
            if (maintenance.isEmpty) return const Center(child: Text("Δεν βρέθηκαν καταχωρήσεις συντήρησης", style: TextStyle(fontSize: 10, color: Colors.grey)));
            
            return Column(
              children: maintenance.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.build_circle_rounded, color: Colors.orange),
                  title: Text(m.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(m.date)), style: const TextStyle(fontSize: 9)),
                  trailing: Text("${m.cost.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                ),
              )).toList(),
            );
          },
        );
      },
    );
  }
}
