import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/task_dialog.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

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
            onPressed: () => showTaskEntryDialog(context),
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
              MonthView(
                currentMonth: _currentMonth,
                selectedDate: _selectedDate,
                tasks: provider.tasks,
                projects: provider.projects,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  showCalendarSheet(context, date, provider);
                },
                onMonthChanged: (month) => setState(() => _currentMonth = month),
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => showTaskEntryDialog(context, task: task),
              ),
              _WeeklyTasksView(
                tasks: provider.tasks,
                projects: provider.projects,
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => showTaskEntryDialog(context, task: task),
              ),
              _AllTasksView(
                tasks: provider.tasks,
                projects: provider.projects,
                onTaskUpdate: (task) => provider.updateTask(task),
                onTaskDelete: (id) => provider.deleteTask(id),
                onTaskClick: (task) => showTaskEntryDialog(context, task: task),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCalendarSheet(BuildContext context, DateTime date, ProjectProvider provider) {
  showDialog(
    context: context,
    builder: (context) => CalendarSheetDialog(
      date: date,
      tasks: provider.tasks.where((t) {
        final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
        return dt.year == date.year && dt.month == date.month && dt.day == date.day;
      }).toList(),
      projects: provider.projects,
      onTaskUpdate: (task) => provider.updateTask(task),
      onTaskDelete: (id) => provider.deleteTask(id),
      onAddTask: () => showTaskEntryDialog(context, initialDate: date),
    ),
  );
}

void showTaskEntryDialog(BuildContext context, {Task? task, DateTime? initialDate}) {
  final provider = Provider.of<ProjectProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => TaskDialog(
      projects: provider.projects,
      initialTask: task,
      initialDate: initialDate,
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

class CalendarSheetDialog extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final List<Project> projects;
  final Function(Task) onTaskUpdate;
  final Function(int) onTaskDelete;
  final VoidCallback onAddTask;

  const CalendarSheetDialog({
    super.key,
    required this.date,
    required this.tasks,
    required this.projects,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top part of the "sheet" - Traditional Calendar Look
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'el').format(date).toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d').format(date),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 90, height: 1, letterSpacing: -2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE', 'el').format(date).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
            // Bottom part with tasks
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ΠΡΌΓΡΑΜΜΑ ΗΜΈΡΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1.5)),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          onPressed: () {
                            Navigator.pop(context);
                            onAddTask();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_note_rounded, size: 40, color: Colors.blueGrey.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                "Καμία προγραμματισμένη εργασία",
                                style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final projectName = projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: "")).name;
                            return CalendarTaskItem(
                              task: task,
                              projectName: projectName,
                              onUpdate: onTaskUpdate,
                              onTaskDelete: onTaskDelete,
                              onClick: () {
                                Navigator.pop(context);
                                showTaskEntryDialog(context, task: task);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.blueGrey,
                        ),
                        child: const Text("ΕΠΙΣΤΡΟΦΗ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthView extends StatefulWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<Task> tasks;
  final List<Project> projects;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;
  final Function(Task) onTaskUpdate;
  final Function(int) onTaskDelete;
  final Function(Task) onTaskClick;
  final bool showHeader;

  const MonthView({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.tasks,
    required this.projects,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onTaskClick,
    this.showHeader = true,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded), 
                  onPressed: () => widget.onMonthChanged(DateTime(widget.currentMonth.year, widget.currentMonth.month - 1))
                ),
                Text(
                  DateFormat('MMMM yyyy', 'el').format(widget.currentMonth).toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded), 
                  onPressed: () => widget.onMonthChanged(DateTime(widget.currentMonth.year, widget.currentMonth.month + 1))
                ),
              ],
            ),
          ),
        _buildMonthGrid(),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(widget.currentMonth.year, widget.currentMonth.month, 1);
    final lastDay = DateTime(widget.currentMonth.year, widget.currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = (firstDay.weekday + 6) % 7; 
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1),
      itemCount: 42, 
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        
        final date = DateTime(widget.currentMonth.year, widget.currentMonth.month, day);
        final isSelected = date.year == widget.selectedDate.year && date.month == widget.selectedDate.month && date.day == widget.selectedDate.day;
        final hasTasks = widget.tasks.any((t) {
          final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
          return dt.year == date.year && dt.month == date.month && dt.day == date.day;
        });

        return InkWell(
          onTap: () => widget.onDateSelected(date),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day
                ? Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 1.5) : null,
              boxShadow: isSelected ? [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(), 
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B), 
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, 
                    fontSize: 14
                  )
                ),
                if (hasTasks) 
                  Container(
                    margin: const EdgeInsets.only(top: 4), 
                    width: 6, 
                    height: 6, 
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.orange, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: (isSelected ? Colors.white : Colors.orange).withValues(alpha: 0.4), blurRadius: 4)
                      ]
                    )
                  ),
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
        return CalendarTaskItem(
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
        return CalendarTaskItem(
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

class CalendarTaskItem extends StatelessWidget {
  final Task task;
  final String projectName;
  final Function(Task) onUpdate;
  final Function(int) onTaskDelete;
  final VoidCallback onClick;

  const CalendarTaskItem({required this.task, required this.projectName, required this.onUpdate, required this.onTaskDelete, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final color = task.isCompleted ? const Color(0xFF38B000) : const Color(0xFF4361EE);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    value: task.isCompleted,
                    activeColor: const Color(0xFF38B000),
                    onChanged: (val) => onUpdate(task.copyWith(isCompleted: val!)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description, 
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null, 
                          fontWeight: FontWeight.w800, 
                          fontSize: 13, 
                          color: task.isCompleted ? Colors.grey : const Color(0xFF1E293B)
                        )
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 10, color: Colors.blueGrey.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date)), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(projectName.toUpperCase(), style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), 
                  onPressed: () => onTaskDelete(task.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
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
