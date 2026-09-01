import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/ui/components/task_dialog.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/project_roi_screen.dart';

class ProjectEconomicsScreen extends StatefulWidget {
  final Project project;

  const ProjectEconomicsScreen({super.key, required this.project});

  @override
  State<ProjectEconomicsScreen> createState() => _ProjectEconomicsScreenState();
}

class _ProjectEconomicsScreenState extends State<ProjectEconomicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjectData(widget.project.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("ΟΙΚΟΝΟΜΙΚΑ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(widget.project.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () => PdfGenerator.generateAndShareProjectFinancials(
              projectName: widget.project.name,
              expenses: provider.currentProjectExpenses,
              incomes: provider.currentProjectIncomes,
              settings: provider.settings,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => ExcelExporter.exportProjectFinancials(widget.project.name, provider.currentProjectExpenses, provider.currentProjectIncomes),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: Colors.blue),
            tooltip: "Ανάλυση ROI",
            onPressed: () async {
              final roi = await provider.calculateProjectROIData(widget.project.id);
              if (context.mounted) {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (c, a1, a2) => ProjectROIScreen(projectName: widget.project.name, roiData: roi),
                  transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
                ));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "ΕΞΟΔΑ"),
            Tab(text: "ΕΙΣΠΡΑΞΕΙΣ"),
            Tab(text: "ΕΡΓΑΣΙΕΣ"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) _showExpenseDialog(context);
          else if (_tabController.index == 1) _showIncomeDialog(context);
          else if (_tabController.index == 2) _showTaskDialog(context);
        },
        label: Text(
          _tabController.index == 0 ? "ΝΕΟ ΕΞΟΔΟ" : _tabController.index == 1 ? "ΝΕΑ ΕΙΣΠΡΑΞΗ" : "ΝΕΑ ΕΡΓΑΣΙΑ",
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        icon: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpenseTab(project: widget.project, expenses: provider.currentProjectExpenses),
          _IncomeTab(project: widget.project, incomes: provider.currentProjectIncomes),
          _TaskTab(project: widget.project, tasks: provider.tasks.where((t) => t.projectId == widget.project.id).toList()),
        ],
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, {Expense? expense}) {
    showDialog(context: context, builder: (context) => _AddEditExpenseDialog(projectId: widget.project.id, initialExpense: expense));
  }

  void _showIncomeDialog(BuildContext context, {Income? income}) {
    showDialog(context: context, builder: (context) => _AddEditIncomeDialog(projectId: widget.project.id, initialIncome: income));
  }

  void _showTaskDialog(BuildContext context, {Task? task}) {
    showDialog(context: context, builder: (context) => TaskDialog(
      projects: [widget.project],
      initialTask: task,
      onConfirm: (t) => task == null ? Provider.of<ProjectProvider>(context, listen: false).addTask(t) : Provider.of<ProjectProvider>(context, listen: false).updateTask(t),
    ));
  }
}

class _ExpenseTab extends StatelessWidget {
  final Project project;
  final List<Expense> expenses;
  const _ExpenseTab({required this.project, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final totalPaid = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final netTotal = expenses.fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));
    final vatTotal = totalPaid - netTotal;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildSummaryCard(
          label: "ΣΥΝΟΛΟ ΕΞΟΔΩΝ", 
          amount: totalPaid, 
          netAmount: netTotal,
          vatAmount: vatTotal,
          color: Colors.red
        ),
        _GroupedListView(
          items: expenses,
          dateSelector: (e) => e.date,
          itemBuilder: (context, e) => _ExpenseItemCardPremium(
            expense: e,
            onDelete: () => Provider.of<ProjectProvider>(context, listen: false).deleteExpense(project.id, e.id),
            onTap: () => showDialog(context: context, builder: (context) => _AddEditExpenseDialog(projectId: project.id, initialExpense: e)),
          ),
        ),
      ],
    );
  }
}

class _IncomeTab extends StatelessWidget {
  final Project project;
  final List<Income> incomes;
  const _IncomeTab({required this.project, required this.incomes});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final totalReceived = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final netIncome = incomes.fold(0.0, (sum, i) => sum + (i.hasVat ? i.amount / 1.24 : i.amount));
    final vatIncome = totalReceived - netIncome;
    
    final netExpense = provider.currentProjectExpenses.fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));
    final currentBalance = netIncome - netExpense;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildSummaryCard(
          label: "ΣΥΝΟΛΟ ΕΙΣΠΡΑΞΕΩΝ", 
          amount: totalReceived, 
          netAmount: netIncome,
          vatAmount: vatIncome,
          color: Colors.blue,
          customFooter: "ΠΡΑΓΜΑΤΙΚΟ ΚΕΡΔΟΣ (ΚΑΘΑΡΑ): ${currentBalance.toStringAsFixed(2)} €"
        ),
        _GroupedListView(
          items: incomes,
          dateSelector: (i) => i.date,
          itemBuilder: (context, i) => _IncomeItemCardPremium(
            income: i,
            onDelete: () => provider.deleteIncome(project.id, i.id),
            onTap: () => showDialog(context: context, builder: (context) => _AddEditIncomeDialog(projectId: project.id, initialIncome: i)),
          ),
        ),
      ],
    );
  }
}

class _TaskTab extends StatelessWidget {
  final Project project;
  final List<Task> tasks;
  const _TaskTab({required this.project, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return _GroupedListView(
      items: tasks,
      dateSelector: (t) => t.date,
      itemBuilder: (context, t) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (t.isCompleted ? Colors.green : Colors.blueGrey).withValues(alpha: 0.08),
              (t.isCompleted ? Colors.green : Colors.blueGrey).withValues(alpha: 0.01),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (t.isCompleted ? Colors.green : Colors.blueGrey).withValues(alpha: 0.12)),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Checkbox(
              value: t.isCompleted,
              activeColor: Colors.green,
              onChanged: (v) => Provider.of<ProjectProvider>(context, listen: false).updateTask(t.copyWith(isCompleted: v!)),
            ),
            title: Text(t.description, style: TextStyle(decoration: t.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B))),
            subtitle: Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(t.date)), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black12), onPressed: () => Provider.of<ProjectProvider>(context, listen: false).deleteTask(t.id)),
            onTap: () => showDialog(context: context, builder: (context) => TaskDialog(projects: [project], initialTask: t, onConfirm: (nt) => Provider.of<ProjectProvider>(context, listen: false).updateTask(nt))),
          ),
        ),
      ),
    );
  }
}

Widget _buildSummaryCard({
  required String label, 
  required double amount, 
  required double netAmount, 
  required double vatAmount, 
  required Color color,
  String? customFooter
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: PremiumCard(
      accentColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              Text("${amount.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat("ΚΑΘΑΡΟ", "${netAmount.toStringAsFixed(2)} €", color.withValues(alpha: 0.6)),
              const Spacer(),
              _miniStat("ΦΠΑ", "${vatAmount.toStringAsFixed(2)} €", Colors.blueGrey.withValues(alpha: 0.4)),
            ],
          ),
          if (customFooter != null) ...[
            const SizedBox(height: 12),
            Text(
              customFooter, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.blue, letterSpacing: 0.2),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _miniStat(String label, String value, Color labelColor, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
  return Column(
    crossAxisAlignment: align,
    children: [
      Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: labelColor, letterSpacing: 1)),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ),
    ],
  );
}

class _GroupedListView<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T) dateSelector;
  final Widget Function(BuildContext, T) itemBuilder;

  const _GroupedListView({required this.items, required this.dateSelector, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final sorted = items.toList()..sort((a, b) => dateSelector(b).compareTo(dateSelector(a)));
    final grouped = <String, List<T>>{};
    for (var item in sorted) {
      final date = DateFormat('dd MMMM yyyy', 'el').format(DateTime.fromMillisecondsSinceEpoch(dateSelector(item)));
      grouped.putIfAbsent(date.toUpperCase(), () => []).add(item);
    }

    return Column(
      children: List.generate(grouped.length, (index) {
        final date = grouped.keys.elementAt(index);
        final dayItems = grouped[date]!;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            initiallyExpanded: false,
            title: Text(date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E293B), letterSpacing: 0.5)),
            leading: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blueGrey),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: dayItems.map((item) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: itemBuilder(context, item),
            )).toList(),
          ),
        );
      }),
    );
  }
}

class _ExpenseItemCardPremium extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete, onTap;
  const _ExpenseItemCardPremium({required this.expense, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final net = expense.hasVat ? expense.amount / 1.24 : expense.amount;
    final vat = expense.amount - net;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      accentColor: Colors.red,
      onTap: onTap,
      onLongPress: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Icon(expense.expenseType == "INVOICE" ? Icons.receipt_long_rounded : Icons.payments_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text("${expense.workerName} • ${expense.expenseType == 'INVOICE' ? 'ΤΙΜΟΛΟΓΙΟ' : 'ΠΛΗΡΩΜΗ'}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              Text("${expense.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black12), onPressed: onDelete),
            ],
          ),
          if (expense.hasVat || (expense.invoiceNumber != null && expense.invoiceNumber!.isNotEmpty)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (expense.hasVat) Row(children: [_smallDetailItem("ΚΑΘΑΡΟ", "${net.toStringAsFixed(2)}€"), const SizedBox(width: 20), _smallDetailItem("ΦΠΑ", "${vat.toStringAsFixed(2)}€")])
                else const Text("ΑΠΑΛΛΑΓΗ ΦΠΑ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                if (expense.invoiceNumber != null && expense.invoiceNumber!.isNotEmpty) _smallDetailItem("ΑΡ. ΤΙΜΟΛΟΓΙΟΥ", expense.invoiceNumber!, color: Colors.blue),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallDetailItem(String l, String v, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.8))), const SizedBox(height: 2), Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF1E293B)))]);
}

class _IncomeItemCardPremium extends StatelessWidget {
  final Income income;
  final VoidCallback onDelete, onTap;
  const _IncomeItemCardPremium({required this.income, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final net = income.hasVat ? income.amount / 1.24 : income.amount;
    final vat = income.amount - net;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      accentColor: Colors.blue,
      onTap: onTap,
      onLongPress: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.add_chart_rounded, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(income.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(income.hasVat ? "ΕΙΣΠΡΑΞΗ ΜΕ ΦΠΑ" : "ΚΑΘΑΡΗ ΕΙΣΠΡΑΞΗ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              Text("${income.amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 16, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black12), onPressed: onDelete),
            ],
          ),
          if (income.hasVat) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Row(children: [_smallDetailItem("ΚΑΘΑΡΟ ΠΟΣΟ", "${net.toStringAsFixed(2)}€"), const SizedBox(width: 24), _smallDetailItem("ΦΠΑ (24%)", "${vat.toStringAsFixed(2)}€")]),
          ],
        ],
      ),
    );
  }
  Widget _smallDetailItem(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.8))), const SizedBox(height: 2), Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))]);
}

class _AddEditExpenseDialog extends StatefulWidget {
  final int projectId;
  final Expense? initialExpense;
  const _AddEditExpenseDialog({required this.projectId, this.initialExpense});
  @override
  State<_AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends State<_AddEditExpenseDialog> {
  late TextEditingController _descController, _amountController, _invoiceController, _supplierController;
  late bool _hasVat;
  late int _date;
  String _type = "PAYMENT";
  String _categoryType = "LABOR";
  String? _selectedWorker;
  String? _selectedCategory;
  List<Partner> _projectPartners = [];

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.initialExpense?.description ?? "");
    _amountController = TextEditingController(text: widget.initialExpense?.amount.toString() ?? "");
    _invoiceController = TextEditingController(text: widget.initialExpense?.invoiceNumber ?? "");
    _supplierController = TextEditingController(text: (widget.initialExpense?.workerName == "ΓΕΝΙΚΟ / ΑΓΟΡΑ") ? "" : (widget.initialExpense?.workerName ?? ""));
    _hasVat = widget.initialExpense?.hasVat ?? false;
    _date = widget.initialExpense?.date ?? DateTime.now().millisecondsSinceEpoch;
    _type = widget.initialExpense?.expenseType ?? "PAYMENT";
    _selectedWorker = widget.initialExpense?.workerName;
    if (_selectedWorker == "ΓΕΝΙΚΟ / ΑΓΟΡΑ") _selectedWorker = null;
    
    // Default to MATERIAL if it's a new generic expense, otherwise LABOR
    _categoryType = widget.initialExpense?.categoryType ?? (_selectedWorker == null ? "MATERIAL" : "LABOR");
    _selectedCategory = widget.initialExpense?.linkedCategory;
    
    _loadPartners();
  }

  void _simulateOcrScan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Ανάλυση παραστατικού μέσω AI...", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate network delay for OCR
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _amountController.text = "124.50";
        _invoiceController.text = "INV-2026-001";
        _type = "INVOICE";
        _hasVat = true;
        _descController.text = "ΑΓΟΡΑ ΥΛΙΚΩΝ (OCR SCAN)";
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Η σάρωση ολοκληρώθηκε! Επιβεβαιώστε τα στοιχεία.")));
    }
  }

  void _loadPartners() async {
    final partners = await Provider.of<ProjectProvider>(context, listen: false).getPartnersForProject(widget.projectId);
    setState(() => _projectPartners = partners);
  }

  void _showAddPartnerToProjectPicker() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final allPartners = provider.partners;
    final assigned = await provider.getPartnersForProject(widget.projectId);
    final assignedIds = assigned.map((p) => p.id).toSet();
    
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
                      await provider.addPartnerToProject(widget.projectId, p.id);
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
    const color = Colors.redAccent;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: const PremiumHeader(title: "ΚΑΤΑΧΩΡΗΣΗ ΕΞΟΔΟΥ", icon: Icons.payments_rounded, color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(controller: _descController, decoration: const InputDecoration(labelText: "Περιγραφή", prefixIcon: Icon(Icons.description_outlined))),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: (_selectedWorker == null || _projectPartners.any((p) => p.name == _selectedWorker)) 
                                ? _selectedWorker 
                                : null, // Safely handle values not in items list
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "Συνεργάτης (Προαιρετικό)", prefixIcon: Icon(Icons.person_pin_rounded)),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text("ΓΕΝΙΚΟ / ΑΓΟΡΑ", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic))),
                              ..._projectPartners.map((p) => DropdownMenuItem<String?>(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 14)))),
                              if (_selectedWorker != null && !_projectPartners.any((p) => p.name == _selectedWorker) && _selectedWorker != "ΓΕΝΙΚΟ / ΑΓΟΡΑ")
                                DropdownMenuItem<String?>(value: _selectedWorker, child: Text(_selectedWorker!, style: const TextStyle(fontSize: 14))),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectedWorker = v;
                                if (v == null) _categoryType = "MATERIAL"; // Auto-switch to Material if Generic
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _showAddPartnerToProjectPicker, 
                          icon: const Icon(Icons.person_add_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_type == "INVOICE" || _selectedWorker == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          controller: _supplierController, 
                          decoration: const InputDecoration(labelText: "Όνομα Προμηθευτή", prefixIcon: Icon(Icons.store_rounded))
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Κατηγορία", prefixIcon: Icon(Icons.category_outlined)),
                      items: AppDestinations.values.map((d) => DropdownMenuItem(value: d.name, child: Text(d.label, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel("ΤΥΠΟΣ ΕΞΟΔΟΥ"),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "LABOR", label: Text("Εργασία", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        ButtonSegment(value: "MATERIAL", label: Text("Υλικά", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                      selected: {_categoryType},
                      onSelectionChanged: (s) => setState(() => _categoryType = s.first),
                    ),
                    _sectionHeader("ΣΤΟΙΧΕΙΑ ΠΑΡΑΣΤΑΤΙΚΟΥ", color),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.fromMillisecondsSinceEpoch(_date),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() => _date = pickedDate.millisecondsSinceEpoch);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        "ΗΜΕΡΟΜΗΝΙΑ: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(_date))}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _amountController, decoration: const InputDecoration(labelText: "Ποσό (€)", prefixIcon: Icon(Icons.euro_rounded)), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: _simulateOcrScan, 
                          icon: const Icon(Icons.document_scanner_rounded, size: 20),
                          tooltip: "Σάρωση Τιμολογίου (AI)",
                        ),
                      ],
                    ),
                    if (_type == "INVOICE") ...[
                      const SizedBox(height: 12), 
                      TextField(controller: _invoiceController, decoration: const InputDecoration(labelText: "Αρ. Τιμολογίου", prefixIcon: Icon(Icons.receipt_long_outlined)))
                    ],
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: CheckboxListTile(
                        title: const Text("Περιλαμβάνει ΦΠΑ 24%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), 
                        value: _hasVat, 
                        onChanged: (v) => setState(() => _hasVat = v!), 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        activeColor: color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "PAYMENT", label: Text("ΠΛΗΡΩΜΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                        ButtonSegment(value: "INVOICE", label: Text("ΤΙΜΟΛΟΓΙΟ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (_descController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Συμπληρώστε περιγραφή")));
                              return;
                            }
                            if (_amountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Συμπληρώστε ποσό")));
                              return;
                            }

                            String worker = _selectedWorker ?? "ΓΕΝΙΚΟ / ΑΓΟΡΑ";
                            // Prioritize the manual supplier entry if provided and dropdown is Generic
                            if ((worker == "ΓΕΝΙΚΟ / ΑΓΟΡΑ" || worker.isEmpty) && _supplierController.text.trim().isNotEmpty) {
                              worker = _supplierController.text.trim();
                            }
                            
                            final e = Expense(
                              id: widget.initialExpense?.id ?? 0, 
                              projectId: widget.projectId, 
                              date: _date, 
                              description: _descController.text.trim(), 
                              workerName: worker, 
                              amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0, 
                              hasVat: _hasVat, 
                              expenseType: _type, 
                              linkedCategory: _selectedCategory, 
                              categoryType: _categoryType, 
                              invoiceNumber: _type == "INVOICE" ? _invoiceController.text.trim() : null
                            );

                            final provider = Provider.of<ProjectProvider>(context, listen: false);
                            if (widget.initialExpense == null) {
                              await provider.addExpense(widget.projectId, e);
                            } else {
                              await provider.updateExpense(widget.projectId, e);
                            }
                            
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα κατά την αποθήκευση: $e")));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: color),
                        child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
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

  Widget _sectionLabel(String l) => Row(children: [Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)), const SizedBox(width: 8), const Expanded(child: Divider())]);

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.1))),
        ],
      ),
    );
  }
}

class _AddEditIncomeDialog extends StatefulWidget {
  final int projectId;
  final Income? initialIncome;
  const _AddEditIncomeDialog({required this.projectId, this.initialIncome});
  @override
  State<_AddEditIncomeDialog> createState() => _AddEditIncomeDialogState();
}

class _AddEditIncomeDialogState extends State<_AddEditIncomeDialog> {
  late TextEditingController _descController, _amountController;
  late bool _hasVat;
  late int _date;
  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.initialIncome?.description ?? "");
    _amountController = TextEditingController(text: widget.initialIncome?.amount.toString() ?? "");
    _hasVat = widget.initialIncome?.hasVat ?? false;
    _date = widget.initialIncome?.date ?? DateTime.now().millisecondsSinceEpoch;
  }
  @override
  Widget build(BuildContext context) {
    const color = Colors.blue;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: const PremiumHeader(title: "ΝΈΑ ΕΊΣΠΡΑΞΗ", icon: Icons.add_chart_rounded, color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: "Αιτιολογία", prefixIcon: Icon(Icons.description_outlined))),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.fromMillisecondsSinceEpoch(_date),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() => _date = pickedDate.millisecondsSinceEpoch);
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(
                      "ΗΜΕΡΟΜΗΝΙΑ: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(_date))}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _amountController, decoration: const InputDecoration(labelText: "Ποσό (€)", prefixIcon: Icon(Icons.euro_rounded)), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                    child: CheckboxListTile(
                      title: const Text("Περιλαμβάνει ΦΠΑ 24%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), 
                      value: _hasVat, 
                      onChanged: (v) => setState(() => _hasVat = v!), 
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      activeColor: color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_descController.text.isEmpty) return;
                        final i = Income(id: widget.initialIncome?.id ?? 0, projectId: widget.projectId, date: _date, description: _descController.text, amount: double.tryParse(_amountController.text) ?? 0.0, hasVat: _hasVat);
                        if (widget.initialIncome == null) Provider.of<ProjectProvider>(context, listen: false).addIncome(widget.projectId, i);
                        else Provider.of<ProjectProvider>(context, listen: false).updateIncome(widget.projectId, i);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
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

extension on Task {
  Task copyWith({int? id, int? projectId, int? date, String? description, bool? isCompleted}) {
    return Task(id: id ?? this.id, projectId: projectId ?? this.projectId, date: date ?? this.date, description: description ?? this.description, isCompleted: isCompleted ?? this.isCompleted);
  }
}
