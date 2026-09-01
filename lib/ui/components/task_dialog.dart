import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';

class TaskDialog extends StatefulWidget {
  final List<Project> projects;
  final Task? initialTask;
  final Function(Task) onConfirm;

  const TaskDialog({super.key, required this.projects, this.initialTask, required this.onConfirm});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int? _selectedProjectId;
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(widget.initialTask!.date);
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _selectedProjectId = widget.initialTask!.projectId == 0 ? null : widget.initialTask!.projectId;
      _descController.text = widget.initialTask!.description;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? "Νέα Εργασία" : "Επεξεργασία"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Text(DateFormat('dd/MM').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: _selectedTime);
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Περιγραφή")),
            DropdownButtonFormField<int>(
              value: _selectedProjectId,
              decoration: const InputDecoration(labelText: "Έργο"),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text("Γενική Εταιρείας")),
                ...widget.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (v) => setState(() => _selectedProjectId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () {
            if (_descController.text.isNotEmpty) {
              final finalDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
              widget.onConfirm(Task(
                id: widget.initialTask?.id ?? 0,
                projectId: _selectedProjectId ?? 0,
                date: finalDate.millisecondsSinceEpoch,
                description: _descController.text,
                isCompleted: widget.initialTask?.isCompleted ?? false,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text("ΑΠΟΘΗΚΕΥΣΗ"),
        ),
      ],
    );
  }
}
