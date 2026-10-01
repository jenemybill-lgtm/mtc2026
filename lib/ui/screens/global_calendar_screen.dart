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
            onPressed: () => showTaskEntryDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1300 : double.infinity),
          child: TabBarView(
            controller: _tabController,
            children: [
              isDesktop
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.12), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: MonthView(
                                currentMonth: _currentMonth,
                                selectedDate: _selectedDate,
                                tasks: provider.tasks,
                                projects: provider.projects,
                                onDateSelected: (date) => setState(() => _selectedDate = date),
                                onMonthChanged: (month) => setState(() => _currentMonth = month),
                                onTaskUpdate: (task) => provider.updateTask(task),
                                onTaskDelete: (id) => provider.deleteTask(id),
                                onTaskClick: (task) => showTaskEntryDialog(context, task: task),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: Container(
                              height: 520,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.12), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: _DesktopDailySchedulePanel(
                                selectedDate: _selectedDate,
                                provider: provider,
                                onDateChanged: (newDate) => setState(() => _selectedDate = newDate),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : MonthView(
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
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MobileCalendarSheet(
        initialDate: date,
        provider: provider,
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => CalendarSheetDialog(
        initialDate: date,
        provider: provider,
      ),
    );
  }
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

class CalendarSheetDialog extends StatefulWidget {
  final DateTime initialDate;
  final ProjectProvider provider;

  const CalendarSheetDialog({
    super.key,
    required this.initialDate,
    required this.provider,
  });

  @override
  State<CalendarSheetDialog> createState() => _CalendarSheetDialogState();
}

class _CalendarSheetDialogState extends State<CalendarSheetDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final tasks = provider.tasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
    }).toList();

    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'el').format(_selectedDate);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 60, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top part of the "sheet" with Day Nav < and >
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                    tooltip: "Προηγούμενη Ημέρα",
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "ΠΡΟΓΡΑΜΜΑ ΗΜΕΡΑΣ",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 48, height: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                    tooltip: "Επόμενη Ημέρα",
                  ),
                ],
              ),
            ),
            // Bottom part with list
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${tasks.length} ${tasks.length == 1 ? 'Εργασία' : 'Εργασίες'}",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blue),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showTaskEntryDialog(context, initialDate: _selectedDate);
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_available_rounded, size: 48, color: Colors.blue.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                "Δεν υπάρχουν προγραμματισμένες εργασίες",
                                style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final projectName = provider.projects
                                .firstWhere(
                                  (p) => p.id == task.projectId,
                                  orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: ""),
                                )
                                .name;
                            return _MobileTaskCard(
                              task: task,
                              projectName: projectName,
                              onToggle: (val) => provider.updateTask(task.copyWith(isCompleted: val)),
                              onDelete: () => provider.deleteTask(task.id),
                              onEdit: () {
                                Navigator.pop(context);
                                showTaskEntryDialog(context, task: task);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: const Color(0xFF475569),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("ΚΛΕΙΣΙΜΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

class _SimpleDailyTaskItem extends StatelessWidget {
  final Task task;
  final String projectName;
  final Function(Task) onUpdate;
  final Function(int) onDelete;
  final VoidCallback onEdit;

  const _SimpleDailyTaskItem({required this.task, required this.projectName, required this.onUpdate, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: task.isCompleted,
            activeColor: const Color(0xFF38B000),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (val) => onUpdate(task.copyWith(isCompleted: val!)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted ? Colors.grey : const Color(0xFF1E293B),
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date)),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      projectName.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.6), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => onDelete(task.id),
          visualDensity: VisualDensity.compact,
        ),
      ],
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
        _buildWeekdayHeader(),
        _buildMonthGrid(),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['ΔΕΥ', 'ΤΡΙ', 'ΤΕΤ', 'ΠΕΜ', 'ΠΑΡ', 'ΣΑΒ', 'ΚΥΡ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
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

class _MobileCalendarSheet extends StatefulWidget {
  final DateTime initialDate;
  final ProjectProvider provider;

  const _MobileCalendarSheet({required this.initialDate, required this.provider});

  @override
  State<_MobileCalendarSheet> createState() => _MobileCalendarSheetState();
}

class _MobileCalendarSheetState extends State<_MobileCalendarSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final tasks = provider.tasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
    }).toList();

    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'el').format(_selectedDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, -5)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                        tooltip: "Προηγούμενη Ημέρα",
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "ΠΡΟΓΡΑΜΜΑ ΗΜΕΡΑΣ",
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                        tooltip: "Επόμενη Ημέρα",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${tasks.length} ${tasks.length == 1 ? 'Εργασία' : 'Εργασίες'}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blue),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showTaskEntryDialog(context, initialDate: _selectedDate);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, size: 56, color: Colors.blue.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            const Text(
                              "Δεν υπάρχουν προγραμματισμένες εργασίες",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Πατήστε '+ ΝΕΑ ΕΡΓΑΣΙΑ' για προσθήκη",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final projectName = provider.projects
                              .firstWhere(
                                (p) => p.id == task.projectId,
                                orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: ""),
                              )
                              .name;
                          return _MobileTaskCard(
                            task: task,
                            projectName: projectName,
                            onToggle: (val) => provider.updateTask(task.copyWith(isCompleted: val)),
                            onDelete: () => provider.deleteTask(task.id),
                            onEdit: () {
                              Navigator.pop(context);
                              showTaskEntryDialog(context, task: task);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileTaskCard extends StatelessWidget {
  final Task task;
  final String projectName;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MobileTaskCard({
    required this.task,
    required this.projectName,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = task.isCompleted ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final timeStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(task.date));

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: task.isCompleted,
                    activeColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onChanged: (val) => onToggle(val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: task.isCompleted ? Colors.grey : const Color(0xFF1E293B),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              projectName.toUpperCase(),
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopDailySchedulePanel extends StatelessWidget {
  final DateTime selectedDate;
  final ProjectProvider provider;
  final ValueChanged<DateTime> onDateChanged;

  const _DesktopDailySchedulePanel({
    required this.selectedDate,
    required this.provider,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final tasks = provider.tasks.where((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      return dt.year == selectedDate.year && dt.month == selectedDate.month && dt.day == selectedDate.day;
    }).toList();

    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'el').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
                tooltip: "Προηγούμενη Ημέρα",
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "ΠΡΟΓΡΑΜΜΑ ΗΜΕΡΑΣ",
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                onPressed: () => onDateChanged(selectedDate.add(const Duration(days: 1))),
                tooltip: "Επόμενη Ημέρα",
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${tasks.length} ${tasks.length == 1 ? 'Εργασία' : 'Εργασίες'}",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blue),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => showTaskEntryDialog(context, initialDate: selectedDate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("ΝΕΑ ΕΡΓΑΣΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded, size: 56, color: Colors.blue.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text(
                        "Δεν υπάρχουν προγραμματισμένες εργασίες",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Πατήστε '+ ΝΕΑ ΕΡΓΑΣΙΑ' για προσθήκη",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final projectName = provider.projects
                        .firstWhere(
                          (p) => p.id == task.projectId,
                          orElse: () => Project(name: "ΓΕΝΙΚΗ", clientName: "", address: ""),
                        )
                        .name;
                    return _MobileTaskCard(
                      task: task,
                      projectName: projectName,
                      onToggle: (val) => provider.updateTask(task.copyWith(isCompleted: val)),
                      onDelete: () => provider.deleteTask(task.id),
                      onEdit: () => showTaskEntryDialog(context, task: task),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
