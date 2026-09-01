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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMonthHeader(),
          _buildMonthGrid(projectTasks),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 12)),
          ),
          if (selectedDateTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Καμία εργασία")),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: selectedDateTasks.length,
              itemBuilder: (context, index) {
                final task = selectedDateTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(value: task.isCompleted, onChanged: (v) => provider.updateTask(task.copyWith(isCompleted: v!))),
                    title: Text(task.description, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date))),
                    trailing: IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => provider.deleteTask(task.id)),
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
    return FutureBuilder<List<AttendanceEntity>>(
      future: provider.getAttendanceInRange(
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch,
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59).millisecondsSinceEpoch,
      ),
      builder: (context, snapshot) {
        final attendance = snapshot.data?.where((a) => a.projectId == widget.project.id).toList() ?? [];

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildMonthHeader(),
              _buildMonthGrid([]),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(DateFormat('EEEE, dd MMMM', 'el').format(_selectedDate).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 12)),
              ),
              if (attendance.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("Καμία παρουσία")),
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
