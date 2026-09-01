import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';

class AddAttendanceDialog extends StatefulWidget {
  final List<Partner> partners;
  final List<Project> projects;
  final int? initialProjectId;
  final AttendanceEntity? initialRecord;
  final Function(AttendanceEntity) onConfirm;

  const AddAttendanceDialog({
    super.key, 
    required this.partners, 
    required this.projects, 
    this.initialProjectId,
    this.initialRecord,
    required this.onConfirm
  });

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  late DateTime _selectedDate;
  String? _selectedWorker;
  int? _selectedProjectId;
  String _selectedCategory = AppDestinations.GENERAL.label;
  final _rateController = TextEditingController();
  final _overtimeController = TextEditingController(text: "0");
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedProjectId = widget.initialProjectId;
    
    if (widget.initialRecord != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.initialRecord!.date);
      _selectedWorker = widget.initialRecord!.workerName;
      _selectedProjectId = widget.initialRecord!.projectId;
      _selectedCategory = widget.initialRecord!.workCategory;
      _rateController.text = widget.initialRecord!.dailyRate.toString();
      _overtimeController.text = widget.initialRecord!.overtimeAmount.toString();
      _noteController.text = widget.initialRecord!.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialRecord == null ? "Καταγραφή Παρουσίας" : "Επεξεργασία Παρουσίας", style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Ημερομηνία: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}", style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedWorker,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Εργάτης", border: OutlineInputBorder()),
              items: widget.partners.where((p) => p.trade == "Εργάτης").isEmpty 
                ? [const DropdownMenuItem(value: null, child: Text("Δεν βρέθηκαν εργάτες"))]
                : widget.partners.where((p) => p.trade == "Εργάτης").map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedWorker = v;
                  try {
                    final partner = widget.partners.firstWhere((p) => p.name == v);
                    _rateController.text = partner.baseRate.toString();
                  } catch (e) {
                    debugPrint("Error finding partner: $e");
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (widget.initialProjectId == null)
              DropdownButtonFormField<int>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: "Έργο", border: OutlineInputBorder()),
                items: widget.projects.isEmpty
                  ? [const DropdownMenuItem(value: null, child: Text("Δεν βρέθηκαν έργα"))]
                  : widget.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _rateController, decoration: const InputDecoration(labelText: "Ποσό (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _overtimeController, decoration: const InputDecoration(labelText: "Υπερωρία (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: "Κατηγορία", border: OutlineInputBorder()),
              items: AppDestinations.values.map((d) => DropdownMenuItem(value: d.label, child: Text(d.label, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: "Σημείωση / Εργασία", border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () {
            if (_selectedWorker != null) {
              widget.onConfirm(AttendanceEntity(
                id: widget.initialRecord?.id ?? 0,
                projectId: _selectedProjectId,
                date: _selectedDate.millisecondsSinceEpoch,
                workerName: _selectedWorker!,
                dailyRate: double.tryParse(_rateController.text) ?? 0.0,
                overtimeAmount: double.tryParse(_overtimeController.text) ?? 0.0,
                workCategory: _selectedCategory,
                note: _noteController.text,
                isConfirmed: widget.initialRecord?.isConfirmed ?? false,
              ));
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Παρακαλώ επιλέξτε εργάτη")));
            }
          },
          child: const Text("ΑΠΟΘΗΚΕΥΣΗ"),
        ),
      ],
    );
  }
}

class AddWeeklyAttendanceDialog extends StatefulWidget {
  final List<Partner> partners;
  final List<Project> projects;
  final int? initialProjectId;
  final DateTime? initialDate;
  final Function(List<AttendanceEntity>) onConfirm;

  const AddWeeklyAttendanceDialog({
    super.key, 
    required this.partners, 
    required this.projects, 
    this.initialProjectId,
    this.initialDate,
    required this.onConfirm
  });

  @override
  State<AddWeeklyAttendanceDialog> createState() => _AddWeeklyAttendanceDialogState();
}

class _AddWeeklyAttendanceDialogState extends State<AddWeeklyAttendanceDialog> {
  late DateTime _startDate;
  String? _selectedWorker;
  int? _selectedProjectId;
  String _selectedCategory = AppDestinations.GENERAL.label;
  final _rateController = TextEditingController();
  final _overtimeController = TextEditingController(text: "0");
  final List<bool> _selectedDays = [true, true, true, true, true, true, false]; // Mon-Sat selected by default
  final List<String> _dayNames = ["ΔΕΥ", "ΤΡΙ", "ΤΕΤ", "ΠΕΜ", "ΠΑΡ", "ΣΑΒ", "ΚΥΡ"];

  @override
  void initState() {
    super.initState();
    final baseDate = widget.initialDate ?? DateTime.now();
    _startDate = baseDate.subtract(Duration(days: baseDate.weekday - 1)); // Monday
    _selectedProjectId = widget.initialProjectId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Μαζική Καταγραφή (Εβδομάδα)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Έναρξη Εβδομάδας: ${DateFormat('dd/MM/yyyy').format(_startDate)}", style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (date != null) {
                   setState(() {
                     _startDate = date.subtract(Duration(days: date.weekday - 1));
                   });
                }
              },
            ),
            const Divider(),
            const Text("Επιλογή Ημερών:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: _selectedDays,
              onPressed: (index) => setState(() => _selectedDays[index] = !_selectedDays[index]),
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              children: _dayNames.map((n) => Text(n, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWorker,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Εργάτης", border: OutlineInputBorder()),
              items: widget.partners.where((p) => p.trade == "Εργάτης").map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedWorker = v;
                  try {
                    final partner = widget.partners.firstWhere((p) => p.name == v);
                    _rateController.text = partner.baseRate.toString();
                  } catch (_) {}
                });
              },
            ),
            const SizedBox(height: 12),
            if (widget.initialProjectId == null)
              DropdownButtonFormField<int>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: "Έργο", border: OutlineInputBorder()),
                items: widget.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _rateController, decoration: const InputDecoration(labelText: "Ποσό (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _overtimeController, decoration: const InputDecoration(labelText: "Υπερωρία (€)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: "Κατηγορία", border: OutlineInputBorder()),
              items: AppDestinations.values.map((d) => DropdownMenuItem(value: d.label, child: Text(d.label, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () {
            if (_selectedWorker != null && _selectedProjectId != null) {
              List<AttendanceEntity> records = [];
              for (int i = 0; i < 7; i++) {
                if (_selectedDays[i]) {
                  final date = _startDate.add(Duration(days: i));
                  records.add(AttendanceEntity(
                    projectId: _selectedProjectId,
                    date: date.millisecondsSinceEpoch,
                    workerName: _selectedWorker!,
                    dailyRate: double.tryParse(_rateController.text) ?? 0.0,
                    overtimeAmount: double.tryParse(_overtimeController.text) ?? 0.0,
                    workCategory: _selectedCategory,
                    isConfirmed: false,
                  ));
                }
              }
              if (records.isNotEmpty) {
                widget.onConfirm(records);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Επιλέξτε τουλάχιστον μία ημέρα")));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Επιλέξτε εργάτη και έργο")));
            }
          },
          child: const Text("ΚΑΤΑΧΩΡΗΣΗ"),
        ),
      ],
    );
  }
}
