import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/models/project_models.dart';

class CompactCalendar extends StatefulWidget {
  final List<Task> tasks;
  const CompactCalendar({super.key, required this.tasks});

  @override
  State<CompactCalendar> createState() => _CompactCalendarState();
}

class _CompactCalendarState extends State<CompactCalendar> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = (firstDay.weekday + 6) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'el').format(_currentMonth).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Δ', 'Τ', 'Τ', 'Π', 'Π', 'Σ', 'Κ'].map((d) => Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - firstWeekday + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
              final hasTasks = widget.tasks.any((t) {
                final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
                return dt.year == date.year && dt.month == date.month && dt.day == date.day;
              });

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.withValues(alpha: 0.1) : null,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(day.toString(), style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.blue : Colors.black87)),
                    if (hasTasks)
                      Positioned(
                        bottom: 4,
                        child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
