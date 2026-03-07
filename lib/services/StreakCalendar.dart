import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendar extends StatelessWidget {
  final List<DateTime> completedDates; 

  StreakCalendar({required this.completedDates});

  bool _isDayCompleted(DateTime day) {
    return completedDates.any((d) => 
      d.year == day.year && d.month == day.month && d.day == day.day
    );
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(formatButtonVisible: false),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildStreakCell(day);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildStreakCell(day, isToday: true);
        },
      ),
    );
  }

  Widget _buildStreakCell(DateTime day, {bool isToday = false}) {
    bool isCompleted = _isDayCompleted(day);

    if (!isCompleted) {
      return Center(
        child: Text('${day.day}', 
          style: TextStyle(color: isToday ? Colors.blue : Colors.black)
        ),
      );
    }
    bool isFirstDayOfWeek = day.weekday == DateTime.sunday; 
    bool isLastDayOfWeek = day.weekday == DateTime.saturday;

    bool isPrevCompleted = _isDayCompleted(day.subtract(const Duration(days: 1)));
    bool isNextCompleted = _isDayCompleted(day.add(const Duration(days: 1)));

    bool isStartOfStreak = isFirstDayOfWeek || !isPrevCompleted;
    bool isEndOfStreak = isLastDayOfWeek || !isNextCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.horizontal(
          left: isStartOfStreak ? const Radius.circular(20) : Radius.zero,
          right: isEndOfStreak ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}

int calculateCurrentStreak(List<DateTime> completedDates) {
  if (completedDates.isEmpty) return 0;
  
  List<DateTime> normalizedDates = completedDates.map((d) => 
    DateTime(d.year, d.month, d.day)
  ).toSet().toList();

  normalizedDates.sort((a, b) => b.compareTo(a));

  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (normalizedDates.first != today && normalizedDates.first != yesterday) {
    return 0;
  }

  int streak = 1;
  for (int i = 0; i < normalizedDates.length - 1; i++) {
    DateTime current = normalizedDates[i];
    DateTime previous = normalizedDates[i + 1];
    
    if (current.difference(previous).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  
  return streak;
}

List<DateTime> generateStreakDates(int streak, DateTime lastCompletedDate) {
  List<DateTime> generatedDates = [];
  
  DateTime referenceDate = DateTime(
    lastCompletedDate.year, 
    lastCompletedDate.month, 
    lastCompletedDate.day
  );

  for (int i = 0; i < streak; i++) {
    generatedDates.add(referenceDate.subtract(Duration(days: i)));
  }

  return generatedDates;
}