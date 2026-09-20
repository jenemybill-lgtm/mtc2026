import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class TaskDialog extends StatefulWidget {
  final List<Project> projects;
  final Task? initialTask;
  final DateTime? initialDate;
  final Function(Task) onConfirm;

  const TaskDialog({super.key, required this.projects, this.initialTask, this.initialDate, required this.onConfirm});

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
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4361EE);
    const accentPurple = Color(0xFF7209B7);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Soft off-white for eye comfort
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.initialTask == null ? "ΝΈΑ ΕΡΓΑΣΊΑ" : "ΕΠΕΞΕΡΓΑΣΊΑ",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 12),
                child: Column(
                  children: [
                    // Date and Time Row with stylized picker buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerButton(
                            icon: Icons.calendar_today_rounded,
                            label: "ΗΜΕΡΟΜΗΝΙΑ",
                            value: DateFormat('dd/MM').format(_selectedDate),
                            color: Colors.blue,
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                              if (date != null) setState(() => _selectedDate = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerButton(
                            icon: Icons.access_time_rounded,
                            label: "ΩΡΑ",
                            value: _selectedTime.format(context),
                            color: accentPurple,
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _selectedTime);
                              if (time != null) setState(() => _selectedTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description TextField with "soft" styling
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: "ΠΕΡΙΓΡΑΦΗ",
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5, color: Colors.blueGrey),
                        hintText: "Τι πρέπει να γίνει...",
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: primaryColor, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Project Dropdown with consistent styling
                    DropdownButtonFormField<int>(
                      value: _selectedProjectId,
                      isExpanded: true,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: "ΕΠΙΛΟΓΗ ΕΡΓΟΥ",
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5, color: Colors.blueGrey),
                        prefixIcon: const Icon(Icons.business_center_rounded, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("ΓΕΝΙΚΗ ΕΤΑΙΡΕΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                        ),
                        ...widget.projects.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name.toUpperCase()),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedProjectId = v),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                        child: Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.4), letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: PremiumButton(
                        label: widget.initialTask == null ? "ΠΡΟΣΘΗΚΗ" : "ΑΠΟΘΗΚΕΥΣΗ",
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () {
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
                        color: primaryColor,
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

  Widget _buildPickerButton({required IconData icon, required String label, required String value, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: color.withValues(alpha: 0.6), letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}
