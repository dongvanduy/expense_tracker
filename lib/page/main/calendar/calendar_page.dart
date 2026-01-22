import 'package:expense_tracker/constants/function/find_index.dart';
import 'package:expense_tracker/controls/spending_repository.dart';
import 'package:expense_tracker/models/spending.dart';
import 'package:expense_tracker/page/main/calendar/widget/build_spending.dart';
import 'package:expense_tracker/page/main/calendar/widget/custom_table_calendar.dart';
import 'package:expense_tracker/page/main/calendar/widget/total_spending.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Spending>? _currentSpendingList;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  var numberFormat = NumberFormat.currency(locale: "vi_VI");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<Spending>>(
            valueListenable: SpendingRepository.spendingNotifier,
            builder: (context, dataSpending, _) {
              return StatefulBuilder(builder: (context, setState) {
                final spendingForMonth = dataSpending
                    .where(
                      (element) => isSameMonth(element.dateTime, _focusedDay),
                    )
                    .toList();

                if (isSameMonth(_focusedDay, _selectedDay)) {
                  _currentSpendingList = spendingForMonth
                      .where((element) => isSameDay(
                          element.dateTime, _selectedDay))
                      .toList();
                }

                return Column(
                  children: [
                    CustomTableCalendar(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        dataSpending: spendingForMonth,
                        onPageChanged: (focusedDay) =>
                            setState(() => _focusedDay = focusedDay),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _selectedDay = selectedDay;
                          });
                        }),
                    const SizedBox(height: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (_currentSpendingList != null &&
                                _currentSpendingList!.isNotEmpty)
                              TotalSpending(list: _currentSpendingList),
                            BuildSpending(
                              spendingList: _currentSpendingList,
                              date: _selectedDay,
                              change: (spending) {
                                setState(() {
                                  if (isSameDay(
                                      spending.dateTime, _selectedDay)) {
                                    _currentSpendingList![findIndex(
                                        _currentSpendingList!,
                                        spending.id!)] = spending;
                                  } else {
                                    _currentSpendingList!.removeWhere(
                                        (element) =>
                                            element.id!.compareTo(
                                                spending.id!) ==
                                            0);
                                  }
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              });
            }),
      ),
    );
  }

  Widget loadingData() {
    return Column(
      children: [
        CustomTableCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
        ),
        const TotalSpending(),
        const Expanded(child: BuildSpending())
      ],
    );
  }
}
