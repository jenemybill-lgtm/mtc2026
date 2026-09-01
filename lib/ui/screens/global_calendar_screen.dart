import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/task_dialog.dart';

class GlobalCalendarScreen extends StatefulWidget {
  const GlobalCalendarScreen({super.key});

  @override
  State<GlobalCalendarScreen> createState() => _GlobalCalendarScreenState();
}

class _GlobalCalendarScreenState extends State<GlobalCalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ΗΜΕΡΟΛΟΓΙΟ ΕΡΓΑΣΙΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Μήνας"),
            Tab(text: "Προσεχείς"),
            Tab(text: "Όλες"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: Colors.blue),
            onPressed: () => _showTaskDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: TabBarView(
            controller: _tabController,
            children: [
              _MonthView(
                currentMonth: _currentMonth,
                selectedDate: _selectedDate,
                tasks: provider.tasks,
                projects: provider.projects,
                onDateSelected: (date) => setState(() => _selectedDate = date),
                onMonthChanged: (month) => setState(() => _currentMonth = month),
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => _showTaskDialog(context, task: task),
              ),
              _WeeklyTasksView(
                tasks: provider.tasks,
                projects: provider.projects,
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => _showTaskDialog(context, task: task),
              ),
              _AllTasksView(
                tasks: provider.tasks,
                projects: provider.projects,
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => _showTaskDialog(context, task: task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, {Task? task}) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        projects: provider.projects,
        initialTask: task,
        onConfirm: (newTask) {
          if (task == null) {
            provider.addTask(newTask);
          } else {
            provider.updateTask(newTask);
          }
        },
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<Task> tasks;
  final List<Project> projects;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;
  final Function(Task) onTaskUpdate;
  final Function(int) onTaskDelete;
  final Function(Task) onTaskClick;

  const _MonthView({
    required this.currentMonth,
    required this.selectedDate,
    required this.tasks,
    required this.projects,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onTaskClick,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDateTasks = tasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.year == selectedDate.year && dt.month == selectedDate.month && dt.day == selectedDate.day;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1))),
              Text(DateFormat('MMMM yyyy', 'el').format(currentMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blueGrey)),
              IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1))),
            ],
          ),
        ),
        _buildMonthGrid(),
        const Divider(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded, color: Colors.blue, size: 18),
              const SizedBox(width: 12),
              Text(DateFormat('EEEE, d MMMM', 'el').format(selectedDate).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, fontSize: 13, letterSpacing: 1)),
            ],
          ),
        ),
        Expanded(
          child: selectedDateTasks.isEmpty 
            ? const Center(child: Text("Καμία προγραμματισμένη εργασία", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: selectedDateTasks.length,
                itemBuilder: (context, index) {
                  final task = selectedDateTasks[index];
                  return _TaskItem(
                    task: task,
                    projectName: projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: "")).name,
                    onUpdate: onTaskUpdate,
                    onTaskDelete: onTaskDelete,
                    onClick: () => onTaskClick(task),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = (firstDay.weekday + 6) % 7; 
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.2),
      itemCount: 42, 
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
        final hasTasks = tasks.any((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
          return dt.year == date.year && dt.month == date.month && dt.day == date.day;
        });

        return InkWell(
          onTap: () => onDateSelected(date),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day
                ? Border.all(color: Colors.blue.withValues(alpha: 0.3)) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal, fontSize: 13)),
                if (hasTasks) Container(margin: const EdgeInsets.only(top: 4), width: 5, height: 5, decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.orange, shape: BoxShape.circle)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyTasksView extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final Function(Task) onTaskUpdate;
  final Function(int) onTaskDelete;
  final Function(Task) onTaskClick;

  const _WeeklyTasksView({required this.tasks, required this.projects, required this.onTaskUpdate, required this.onTaskDelete, required this.onTaskClick});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 14));
    
    final weeklyTasks = tasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) && dt.isBefore(end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    if (weeklyTasks.isEmpty) return const Center(child: Text("Δεν υπάρχουν εργασίες για τις επόμενες 2 εβδομάδες.", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: weeklyTasks.length,
      itemBuilder: (context, index) {
        final task = weeklyTasks[index];
        return _TaskItem(
          task: task,
          projectName: projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: "")).name,
          onUpdate: onTaskUpdate,
          onTaskDelete: onTaskDelete,
          onClick: () => onTaskClick(task),
        );
      },
    );
  }
}

class _AllTasksView extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final Function(Task) onTaskUpdate;
  final Function(int) onTaskDelete;
  final Function(Task) onTaskClick;

  const _AllTasksView({required this.tasks, required this.projects, required this.onTaskUpdate, required this.onTaskDelete, required this.onTaskClick});

  @override
  Widget build(BuildContext context) {
    final sortedTasks = tasks.toList()..sort((a, b) => b.date.compareTo(a.date));
    if (sortedTasks.isEmpty) return const Center(child: Text("Δεν υπάρχουν εργασίες.", style: TextStyle(color: Colors.grey)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return _TaskItem(
          task: task,
          projectName: projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: "")).name,
          onUpdate: onTaskUpdate,
          onTaskDelete: onTaskDelete,
          onClick: () => onTaskClick(task),
        );
      },
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final String projectName;
  final Function(Task) onUpdate;
  final Function(int) onTaskDelete;
  final VoidCallback onClick;

  const _TaskItem({required this.task, required this.projectName, required this.onUpdate, required this.onTaskDelete, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final color = task.isCompleted ? Colors.green : Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onClick,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Checkbox(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            value: task.isCompleted,
            activeColor: Colors.green,
            onChanged: (val) => onUpdate(task.copyWith(isCompleted: val!)),
          ),
          title: Text(task.description, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w900, fontSize: 13, color: const Color(0xFF1E293B))),
          subtitle: Row(
            children: [
              Text(DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date)), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(projectName.toUpperCase(), style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          trailing: IconButton(icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.black12), onPressed: () => onTaskDelete(task.id)),
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
