import 'dart:math';

import 'package:expense_tracker/models/spending.dart';
import 'package:expense_tracker/setting/bloc/setting_cubit.dart';
import 'package:expense_tracker/setting/bloc/setting_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

bool isSameMonth(DateTime day1, DateTime day2) =>
    day1.year == day2.year && day1.month == day2.month;

class CustomTableCalendar extends StatelessWidget {
  const CustomTableCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    this.dataSpending,
    this.onPageChanged,
    this.onDaySelected,
  }) : super(key: key);
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Spending>? dataSpending;
  final Function(DateTime)? onPageChanged;
  final Function(DateTime, DateTime)? onDaySelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingCubit, SettingState>(
        buildWhen: (previous, current) => previous != current,
        builder: (_, settingState) {
          final theme = Theme.of(context);
          final surface = theme.colorScheme.surfaceVariant;
          final onSurface = theme.colorScheme.onSurfaceVariant;
          final accent = theme.colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: TableCalendar(
                  locale: settingState.locale.languageCode,
                  firstDay: DateTime.utc(2000),
                  lastDay: DateTime.utc(2100),
                  focusedDay: focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  availableGestures: AvailableGestures.horizontalSwipe,
                  rowHeight: 52,
                  onPageChanged: (focusedDay) {
                    if (onPageChanged != null) onPageChanged!(focusedDay);
                  },
                  onDaySelected: (mySelectedDay, myFocusedDay) {
                    if (!isSameDay(selectedDay, mySelectedDay) &&
                        isSameMonth(focusedDay, mySelectedDay) &&
                        onDaySelected != null) {
                      onDaySelected!(mySelectedDay, myFocusedDay);
                    }
                  },
                  eventLoader: (day) {
                    return dataSpending != null
                        ? dataSpending!
                            .where((element) => isSameDay(element.dateTime, day))
                            .toList()
                        : [];
                  },
                  calendarStyle: CalendarStyle(
                    isTodayHighlighted: true,
                    cellMargin: const EdgeInsets.all(6),
                    cellPadding: EdgeInsets.zero,
                    tablePadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    selectedDecoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    defaultDecoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    weekendDecoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    outsideDaysVisible: false,
                    markersMaxCount: 3,
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    rightChevronPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ),
                    leftChevronPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ),
                    headerPadding: const EdgeInsets.symmetric(vertical: 6),
                    titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ) ??
                        const TextStyle(fontSize: 18),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: onSurface,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, day) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormat.yMMMM(settingState.locale.languageCode)
                            .format(day),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                    prioritizedBuilder: (context, day, focusedDay) {
                      if (day.month != focusedDay.month ||
                          day.year != focusedDay.year) {
                        return const SizedBox.shrink();
                      }
                      return null;
                    },
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty || !isSameMonth(focusedDay, day)) {
                        return const SizedBox.shrink();
                      }

                      final dotCount = min(events.length, 3);
                      return Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(dotCount, (index) {
                            return Container(
                              margin:
                                  EdgeInsets.only(left: index == 0 ? 0 : 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      );
                    },
                    dowBuilder: (context, day) {
                      if (day.weekday == DateTime.sunday ||
                          day.weekday == DateTime.saturday) {
                        return Center(
                          child: Text(
                            DateFormat.E().format(day),
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          );
        });
  }
}
