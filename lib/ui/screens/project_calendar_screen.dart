import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/task_dialog.dart';
import 'package:mtc2026/ui/components/attendance_dialogs.dart';

class ProjectCalendarScreen extends StatefulWidget {
  final Project project;

  const ProjectCalendarScreen({super.key, required this.project});

  @override
  State<ProjectCalendarScreen> createState() => _ProjectCalendarScreenState();
}

class _ProjectCalendarScreenState extends State<ProjectCalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.blueGrey,
            indicatorColor: Colors.blue,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
            tabs: const [
              Tab(text: "ΕΡΓΑΣΙΕΣ"),
              Tab(text: "ΠΑΡΟΥΣΙΕΣ"),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksTab(provider),
                  _buildAttendanceTab(provider),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab(ProjectProvider provider) {
    final projectTasks = provider.tasks.where((t) => t.projectId == widget.project.id).toList();
    final selectedDateTasks = projectTasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.blue.withValues(alpha: 0.12))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildMonthHeader(),
                      _buildWeekdayHeader(),
                      const SizedBox(height: 8),
                      _buildMonthGrid(projectTasks),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.blue.withValues(alpha: 0.12))),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 13),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showTaskDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (selectedDateTasks.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Καμία εργασία για την επιλεγμένη ημέρα",
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: selectedDateTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedDateTasks[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.15)),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    activeColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    onChanged: (v) => provider.updateTask(task.copyWith(isCompleted: v!)),
                                  ),
                                  title: Text(
                                    task.description,
                                    style: TextStyle(
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: task.isCompleted ? Colors.grey : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date)),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                    onPressed: () => provider.deleteTask(task.id),
                                  ),
                                  onTap: () => _showTaskDialog(context, task: task),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMonthHeader(),
          _buildWeekdayHeader(),
          _buildMonthGrid(projectTasks),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 12),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTaskDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          if (selectedDateTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  "Καμία εργασία για την επιλεγμένη ημέρα",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: selectedDateTasks.length,
              itemBuilder: (context, index) {
                final task = selectedDateTasks[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.15)),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      activeColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: (v) => provider.updateTask(task.copyWith(isCompleted: v!)),
                    ),
                    title: Text(
                      task.description,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: task.isCompleted ? Colors.grey : const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date)),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () => provider.deleteTask(task.id),
                    ),
                    onTap: () => _showTaskDialog(context, task: task),
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(ProjectProvider provider) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return FutureBuilder<List<AttendanceEntity>>(
      future: provider.getAttendanceInRange(
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch,
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59).millisecondsSinceEpoch,
      ),
      builder: (context, snapshot) {
        final attendance = snapshot.data?.where((a) => a.projectId == widget.project.id).toList() ?? [];

        if (isDesktop) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.blue.withValues(alpha: 0.12))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMonthHeader(),
                          _buildWeekdayHeader(),
                          const SizedBox(height: 8),
                          _buildMonthGrid([]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.blue.withValues(alpha: 0.12))),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 13),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddAttendance(context),
                                icon: const Icon(Icons.person_add_rounded, size: 16),
                                label: const Text("ΠΡΟΣΘΗΚΗ ΠΑΡΟΥΣΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (attendance.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Καμία παρουσία για την επιλεγμένη ημέρα",
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: attendance.length,
                                itemBuilder: (context, index) {
                                  final record = attendance[index];
                                  return _AttendanceCard(record: record, onDelete: () => provider.deleteAttendance(record.id).then((_) => setState(() {})));
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildMonthHeader(),
              _buildWeekdayHeader(),
              _buildMonthGrid([]),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 12),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAttendance(context),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text("ΠΡΟΣΘΗΚΗ ΠΑΡΟΥΣΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              if (attendance.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "Καμία παρουσία για την επιλεγμένη ημέρα",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: attendance.length,
                  itemBuilder: (context, index) {
                    final record = attendance[index];
                    return _AttendanceCard(record: record, onDelete: () => provider.deleteAttendance(record.id).then((_) => setState(() {})));
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1))),
          Text(DateFormat('MMMM yyyy', 'el').format(_currentMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1))),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['ΔΕΥ', 'ΤΡΙ', 'ΤΕΤ', 'ΠΕΜ', 'ΠΑΡ', 'ΣΑΒ', 'ΚΥΡ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(List<Task> tasks) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = (firstDay.weekday + 6) % 7; 
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.2),
      itemCount: 42, 
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
        final hasTasks = tasks.any((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
          return dt.year == date.year && dt.month == date.month && dt.day == date.day;
        });

        return InkWell(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                if (hasTasks) Container(width: 4, height: 4, decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.blue, shape: BoxShape.circle)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTaskDialog(BuildContext context, {Task? task}) {
    showDialog(context: context, builder: (context) => TaskDialog(
      projects: [widget.project],
      initialTask: task,
      onConfirm: (t) => task == null ? Provider.of<ProjectProvider>(context, listen: false).addTask(t.copyWith(projectId: widget.project.id)) : Provider.of<ProjectProvider>(context, listen: false).updateTask(t),
    ));
  }

  void _showAddAttendance(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AddAttendanceDialog(
        partners: provider.partners,
        projects: [widget.project],
        initialProjectId: widget.project.id,
        onConfirm: (record) => provider.addAttendance(record.copyWith(date: _selectedDate.millisecondsSinceEpoch)),
      ),
    ).then((_) => setState(() {}));
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceEntity record;
  final VoidCallback onDelete;
  const _AttendanceCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.blue.withValues(alpha: 0.4), width: 1.2)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: const Icon(Icons.person, color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.workerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(record.workCategory, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${record.dailyRate.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on Task {
  Task copyWith({int? id, int? projectId, int? date, String? description, bool? isCompleted}) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

extension on AttendanceEntity {
  AttendanceEntity copyWith({int? id, int? projectId, int? date, String? workerName, double? dailyRate, String? workCategory, String? note}) {
    return AttendanceEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      workerName: workerName ?? this.workerName,
      dailyRate: dailyRate ?? this.dailyRate,
      workCategory: workCategory ?? this.workCategory,
      note: note ?? this.note,
    );
  }
}
