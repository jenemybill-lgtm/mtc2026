import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/pdf_generator.dart';
import 'package:mtc2026/utils/responsive.dart';
import 'package:mtc2026/utils/excel_exporter.dart';
import 'package:mtc2026/ui/components/attendance_dialogs.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class WeeklyPayrollScreen extends StatefulWidget {
  final int? projectId;
  final String? projectName;
  const WeeklyPayrollScreen({super.key, this.projectId, this.projectName});

  @override
  State<WeeklyPayrollScreen> createState() => _WeeklyPayrollScreenState();
}

class _WeeklyPayrollScreenState extends State<WeeklyPayrollScreen> {
  DateTime _calendarDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)); // Monday
  bool _isMonthly = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    
    DateTime startOfPeriod = _isMonthly 
        ? DateTime(_calendarDate.year, _calendarDate.month, 1) 
        : DateTime(_calendarDate.year, _calendarDate.month, _calendarDate.day);
    
    DateTime endOfPeriod = _isMonthly 
        ? DateTime(_calendarDate.year, _calendarDate.month + 1, 0, 23, 59, 59)
        : startOfPeriod.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final currentYear = _calendarDate.year;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.projectName != null ? "ΠΑΡΟΥΣΙΟΛΟΓΙΟ: ${widget.projectName!.toUpperCase()}" : "ΠΑΡΟΥΣΙΟΛΟΓΙΟ", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text(_isMonthly ? "ΜΗΝΙΑΙΑ ΠΡΟΒΟΛΗ" : "ΕΒΔΟΜΑΔΙΑΙΑ ΠΡΟΒΟΛΗ", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: Colors.orange), 
            tooltip: "Μαζική Καταχώρηση Εβδομάδας",
            onPressed: () => _showAddWeeklyAttendance(context)
          ),
          IconButton(icon: const Icon(Icons.post_add_rounded, color: Colors.blue), onPressed: () => _showAddAttendance(context)),
          IconButton(
            icon: Icon(_isMonthly ? Icons.view_week_rounded : Icons.calendar_month_rounded),
            onPressed: () => setState(() => _isMonthly = !_isMonthly),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Εξαγωγή PDF",
            onPressed: () => _generatePdf(context, startOfPeriod, endOfPeriod),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Colors.green),
            tooltip: "Εξαγωγή Excel",
            onPressed: () => _exportExcel(context, startOfPeriod, endOfPeriod),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTotalDebtCardPremium(provider, endOfPeriod),
            _buildPeriodNavigatorPremium(startOfPeriod, endOfPeriod),
            FutureBuilder<List<AttendanceEntity>>(
              future: provider.getAttendanceInRange(startOfPeriod.millisecondsSinceEpoch, endOfPeriod.millisecondsSinceEpoch),
              builder: (context, attendanceSnapshot) {
                return FutureBuilder<List<Expense>>(
                  future: provider.getPaymentsInRange(startOfPeriod.millisecondsSinceEpoch, endOfPeriod.millisecondsSinceEpoch),
                  builder: (context, paymentsSnapshot) {
                    if (attendanceSnapshot.connectionState == ConnectionState.waiting || paymentsSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                    }
                    
                    List<AttendanceEntity> attendance = attendanceSnapshot.data ?? [];
                    List<Expense> rawPayments = paymentsSnapshot.data ?? [];
                    
                    if (widget.projectId != null) {
                      attendance = attendance.where((a) => a.projectId == widget.projectId).toList();
                      rawPayments = rawPayments.where((p) => p.projectId == widget.projectId).toList();
                    }
                    
                    final payments = rawPayments.where((p) => provider.partners.any((partner) => partner.name == p.workerName)).toList();
                    final workers = (attendance.map((e) => e.workerName).toList() + (widget.projectId == null ? payments.map((e) => e.workerName).toList() : [])).toSet().toList()..sort();

                    return Column(
                      children: [
                        _buildPayrollGridPremium(attendance, payments, workers, startOfPeriod, endOfPeriod, provider),
                        _buildWeeklySummaryBarPremium(attendance, payments),
                        if (attendance.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _ProjectCategoryTotalsSectionPremium(attendance: attendance, projects: provider.projects),
                        ],
                        const SizedBox(height: 60),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDebtCardPremium(ProjectProvider provider, DateTime endOfPeriod) {
    return FutureBuilder<double>(
      future: _calculateTotalDebt(provider, endOfPeriod),
      builder: (context, snapshot) {
        final totalDebt = snapshot.data ?? 0.0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: PremiumCard(
            accentColor: Colors.blue,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ΣΥΝΟΛΙΚΗ ΟΦΕΙΛΗ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)),
                        Text("(Έως ${DateFormat('dd/MM').format(endOfPeriod)})", style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Text("${totalDebt.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<double> _calculateTotalDebt(ProjectProvider provider, DateTime endOfPeriod) async {
    final allAtt = await provider.getAttendanceInRange(0, endOfPeriod.millisecondsSinceEpoch);
    final allPays = await provider.getPaymentsInRange(0, endOfPeriod.millisecondsSinceEpoch);
    
    double earned;
    double paid;
    
    if (widget.projectId != null) {
      earned = allAtt.where((a) => a.projectId == widget.projectId).fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
      paid = allPays.where((p) => p.projectId == widget.projectId && provider.partners.any((part) => part.name == p.workerName)).fold(0.0, (sum, p) => sum + p.amount);
    } else {
      earned = allAtt.fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
      paid = allPays.where((p) => provider.partners.any((part) => part.name == p.workerName)).fold(0.0, (sum, p) => sum + p.amount);
    }
    
    return earned - paid;
  }

  Widget _buildPeriodNavigatorPremium(DateTime start, DateTime end) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navBtn(Icons.chevron_left_rounded, () => setState(() => _calendarDate = _isMonthly ? DateTime(_calendarDate.year, _calendarDate.month - 1, 1) : _calendarDate.subtract(const Duration(days: 7)))),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: Text(
              _isMonthly ? DateFormat('MMMM yyyy', 'el').format(start).toUpperCase() : "${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 24),
          _navBtn(Icons.chevron_right_rounded, () => setState(() => _calendarDate = _isMonthly ? DateTime(_calendarDate.year, _calendarDate.month + 1, 1) : _calendarDate.add(const Duration(days: 7)))),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
        child: Icon(icon, size: 24, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildPayrollGridPremium(List<AttendanceEntity> attendance, List<Expense> payments, List<String> workers, DateTime start, DateTime end, ProjectProvider provider) {
    final daysCount = _isMonthly ? DateTime(start.year, start.month + 1, 0).day : 7;
    final periodDays = List.generate(daysCount, (i) => start.add(Duration(days: i)));
    final isDesktop = Responsive.isDesktop(context);
    
    final workerWidth = isDesktop ? 180.0 : 100.0;
    final dayWidth = isDesktop ? 100.0 : 64.0;
    final balanceWidth = isDesktop ? 140.0 : 90.0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    SizedBox(width: workerWidth, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Text("ΕΡΓΑΤΗΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1)))),
                    ...periodDays.map((day) => Container(
                      width: dayWidth,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.03)))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('EEE', 'el').format(day).toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: (day.weekday >= 6) ? Colors.red : Colors.grey)),
                          Text(DateFormat('dd').format(day), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                    )),
                    SizedBox(width: balanceWidth, child: const Center(child: Text("ΥΠΟΛΟΙΠΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1)))),
                  ],
                ),
              ),
              ...workers.map((worker) => _WorkerRowPremium(
                worker: worker,
                days: periodDays,
                attendance: attendance.where((a) => a.workerName == worker).toList(),
                payments: payments.where((p) => p.workerName == worker).toList(),
                provider: provider,
                projectId: widget.projectId,
                endOfPeriod: end,
                workerWidth: workerWidth,
                dayWidth: dayWidth,
                balanceWidth: balanceWidth,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryBarPremium(List<AttendanceEntity> attendance, List<Expense> payments) {
    final totalEarned = attendance.fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final balance = totalEarned - totalPaid;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: PremiumCard(
        accentColor: Colors.blueGrey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PremiumHeader(title: "ΣΥΝΟΛΑ ΠΕΡΙΟΔΟΥ", color: Colors.blueGrey),
                Text("${balance.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: balance > 0 ? Colors.blue : const Color(0xFF1E293B), letterSpacing: -0.5)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _SummaryBox(label: "ΜΕΡΟΚΑΜΑΤΑ", amount: totalEarned, color: const Color(0xFF1E293B))),
                const SizedBox(width: 12),
                Expanded(child: _SummaryBox(label: "ΠΛΗΡΩΜΕΣ", amount: totalPaid, color: Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAttendance(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AddAttendanceDialog(
        partners: provider.partners,
        projects: provider.projects,
        initialProjectId: widget.projectId,
        onConfirm: (record) => provider.addAttendance(record).then((_) => setState(() {})),
      ),
    );
  }

  void _showAddWeeklyAttendance(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AddWeeklyAttendanceDialog(
        partners: provider.partners,
        projects: provider.projects,
        initialProjectId: widget.projectId,
        initialDate: _calendarDate,
        onConfirm: (records) => provider.addMultipleAttendance(records).then((_) => setState(() {})),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, DateTime start, DateTime end) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final attendance = await provider.getAttendanceInRange(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    if (widget.projectId != null) {
      attendance.retainWhere((a) => a.projectId == widget.projectId);
    }
    final payments = await provider.getPaymentsInRange(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    if (widget.projectId != null) {
      payments.retainWhere((p) => p.projectId == widget.projectId);
    }
    final title = widget.projectName != null ? "ΠΑΡΟΥΣΙΟΛΟΓΙΟ ${widget.projectName!.toUpperCase()}" : (_isMonthly ? DateFormat('MMMM yyyy', 'el').format(start) : "ΕΒΔΟΜΑΔΑ ${DateFormat('dd/MM').format(start)}");
    await PdfGenerator.generateAndSharePayroll(title: title, attendance: attendance, payments: payments, projects: provider.projects, settings: provider.settings);
  }

  Future<void> _exportExcel(BuildContext context, DateTime start, DateTime end) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final attendance = await provider.getAttendanceInRange(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    if (widget.projectId != null) {
      attendance.retainWhere((a) => a.projectId == widget.projectId);
    }
    final payments = await provider.getPaymentsInRange(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    if (widget.projectId != null) {
      payments.retainWhere((p) => p.projectId == widget.projectId);
    }
    final title = widget.projectName != null ? "ΠΑΡΟΥΣΙΟΛΟΓΙΟ ${widget.projectName!.toUpperCase()}" : (_isMonthly ? DateFormat('MMMM yyyy', 'el').format(start) : "ΕΒΔΟΜΑΔΑ ${DateFormat('dd/MM').format(start)}");
    await ExcelExporter.exportPayroll(title, attendance, payments);
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryBox({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text("${amount.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _WorkerRowPremium extends StatelessWidget {
  final String worker;
  final List<DateTime> days;
  final List<AttendanceEntity> attendance;
  final List<Expense> payments;
  final ProjectProvider provider;
  final int? projectId;
  final DateTime endOfPeriod;
  final double workerWidth, dayWidth, balanceWidth;

  const _WorkerRowPremium({required this.worker, required this.days, required this.attendance, required this.payments, required this.provider, this.projectId, required this.endOfPeriod, required this.workerWidth, required this.dayWidth, required this.balanceWidth});

  @override
  Widget build(BuildContext context) {
    final totalEarned = attendance.fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.03)))),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showPaymentDialog(context),
            child: Container(
              width: workerWidth,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.blue.withValues(alpha: 0.02),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(worker.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B))),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_card_rounded, size: 14, color: Colors.blue),
                ],
              ),
            ),
          ),
          ...days.map((day) {
            final dayAtt = attendance.where((a) => _isSameDay(DateTime.fromMillisecondsSinceEpoch(a.date), day)).toList();
            final dayPay = payments.where((p) => _isSameDay(DateTime.fromMillisecondsSinceEpoch(p.date), day)).fold(0.0, (sum, p) => sum + p.amount);
            return Container(
              width: dayWidth,
              height: 64,
              decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.03)))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (dayAtt.isNotEmpty)
                      ...dayAtt.map((a) {
                        final pName = provider.projects.firstWhere((p) => p.id == a.projectId, orElse: () => Project(name: "ΓΕΝΙΚΟ", clientName: "", address: "")).name;
                        return InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Colors.blue),
                                      title: const Text('Επεξεργασία Μεροκάματου'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        showDialog(
                                          context: context,
                                          builder: (dialogCtx) => AddAttendanceDialog(
                                            partners: provider.partners,
                                            projects: provider.projects,
                                            initialProjectId: a.projectId,
                                            initialRecord: a,
                                            onConfirm: (updatedRecord) {
                                              provider.updateAttendance(updatedRecord);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Διαγραφή Μεροκάματου', style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        provider.deleteAttendance(a.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                child: Text(pName.toUpperCase(), style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.blue)),
                              ),
                              if (a.overtimeAmount > 0) Text("+${a.overtimeAmount.toInt()}", style: const TextStyle(fontSize: 8, color: Color(0xFF38B000), fontWeight: FontWeight.w900)),
                            ],
                          ),
                        );
                      }),
                    if (dayPay > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text("-${dayPay.toInt()}€", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.red)),
                      ),
                  ],
                ),
              ),
            );
          }),
          FutureBuilder<double>(
            future: _calculateWorkerCumulativeBalance(worker, endOfPeriod),
            builder: (context, snapshot) {
              final balance = snapshot.data ?? 0.0;
              return Container(
                width: balanceWidth,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.03)))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${totalEarned.toInt()}€", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    if (totalPaid > 0) Text("-${totalPaid.toInt()}€", style: const TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold)),
                    Text("${balance.toInt()}€", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: balance > 1 ? const Color(0xFFF72585) : Colors.blueGrey)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<double> _calculateWorkerCumulativeBalance(String workerName, DateTime endOfPeriod) async {
    final allAtt = await provider.getAttendanceInRange(0, endOfPeriod.millisecondsSinceEpoch);
    final allPays = await provider.getPaymentsInRange(0, endOfPeriod.millisecondsSinceEpoch);
    
    double earned;
    double paid;
    
    if (projectId != null) {
      earned = allAtt.where((a) => a.workerName == workerName && a.projectId == projectId).fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
      paid = allPays.where((p) => p.workerName == workerName && p.projectId == projectId).fold(0.0, (sum, p) => sum + p.amount);
    } else {
      earned = allAtt.where((a) => a.workerName == workerName).fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
      paid = allPays.where((p) => p.workerName == workerName).fold(0.0, (sum, p) => sum + p.amount);
    }
    
    return earned - paid;
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _showPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: PremiumHeader(title: "ΠΛΗΡΩΜΗ", subtitle: worker.toUpperCase(), icon: Icons.payments_rounded),
        content: TextField(controller: amountController, decoration: const InputDecoration(labelText: "Ποσό (€)", prefixIcon: Icon(Icons.euro_rounded)), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(onPressed: () {
            final amount = double.tryParse(amountController.text) ?? 0.0;
            if (amount > 0) {
              provider.addExpense(projectId ?? 0, Expense(date: DateTime.now().millisecondsSinceEpoch, description: "ΠΛΗΡΩΜΗ ΕΝΑΝΤΙ", workerName: worker, amount: amount, expenseType: "PAYMENT", projectId: projectId));
              Navigator.pop(context);
            }
          }, child: const Text("ΚΑΤΑΧΩΡΗΣΗ", style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _ProjectCategoryTotalsSectionPremium extends StatelessWidget {
  final List<AttendanceEntity> attendance;
  final List<Project> projects;
  const _ProjectCategoryTotalsSectionPremium({required this.attendance, required this.projects});

  @override
  Widget build(BuildContext context) {
    final projectGroups = <int?, Map<String, double>>{};
    for (var a in attendance) {
      final projId = a.projectId;
      final cat = a.workCategory.isEmpty ? "ΓΕΝΙΚΑ" : a.workCategory;
      projectGroups.putIfAbsent(projId, () => {});
      projectGroups[projId]![cat] = (projectGroups[projId]![cat] ?? 0) + a.dailyRate + a.overtimeAmount;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: PremiumHeader(title: "ΑΝΑΛΥΣΗ ΑΝΑ ΕΡΓΟ & ΦΑΣΗ", color: Colors.blueGrey),
          ),
          ...projectGroups.entries.map((entry) {
            final pName = projects.firstWhere((p) => p.id == entry.key, orElse: () => Project(name: "ΓΕΝΙΚΟ", clientName: "", address: "")).name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: PremiumCard(
                accentColor: Colors.blue,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13, letterSpacing: 0.5)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    ...entry.value.entries.map((catEntry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(catEntry.key, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          Text("${catEntry.value.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                    )),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ΣΥΝΟΛΟ ΕΡΓΟΥ:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                        Text("${entry.value.values.fold(0.0, (sum, val) => sum + val).toStringAsFixed(2)} €", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
