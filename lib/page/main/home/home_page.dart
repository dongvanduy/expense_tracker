import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/controls/spending_repository.dart';
import 'package:expense_tracker/models/spending.dart';
import 'package:expense_tracker/constants/function/extension.dart';
import 'package:expense_tracker/constants/function/get_data_spending.dart';
import 'package:expense_tracker/page/main/home/widget/item_spending_widget.dart';
// Bằng dòng này (hoặc giữ cả 2 nếu cần dùng cả 2):
import 'package:expense_tracker/page/main/home/widget/item_spending_day.dart';

// Import Widget giao diện mới của bạn
import 'widget/modern_balance_card.dart';

import '../../../constants/app_styles.dart';
import '../../../setting/localization/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _monthController;
  List<DateTime> months = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabBar controller cho 19 tháng
    _monthController = TabController(length: 19, vsync: this);
    _monthController.index = 17; // Mặc định chọn tháng hiện tại
    _monthController.addListener(() {
      setState(() {});
    });

    // Tạo danh sách tháng
    DateTime now = DateTime(DateTime.now().year, DateTime.now().month);
    months = [DateTime(now.year, now.month + 1), now];
    for (int i = 1; i < 19; i++) {
      now = DateTime(now.year, now.month - 1);
      months.add(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<Spending>>(
          valueListenable: SpendingRepository.spendingNotifier,
          builder: (context, fullList, child) {

            // 1. Xác định tháng đang chọn
            final selectedMonth = months[18 - _monthController.index];

            // 2. Lọc danh sách chi tiêu thuộc tháng đó
            final filteredList = fullList
                .where((element) => isSameMonth(element.dateTime, selectedMonth))
                .toList();

            // 3. --- LOGIC TÍNH TOÁN (ĐÃ SỬA) ---
            double income = 0;
            double expense = 0;

            // Danh sách các index được coi là Thu nhập trong list.dart:
            // 29: Thu nợ, 30: Đi vay, 34: Thu lãi, 36: Lương, 37: Thu nhập khác
            final List<int> incomeIndexes = [29, 30, 34, 36, 37, 40];

            for (var item in filteredList) {
              if (incomeIndexes.contains(item.type)) {
                // Nếu là thu nhập
                income += item.money;
              } else {
                // Còn lại là chi tiêu (bao gồm cả Cho vay, Trả nợ...)
                expense += item.money;
              }
            }

            // Tổng số dư trong tháng
            double totalBalance = income + expense;

            return Column(
              children: [
                const SizedBox(height: 10),

                // --- Thanh Tab chọn tháng ---
                SizedBox(
                  height: 40,
                  child: TabBar(
                    controller: _monthController,
                    isScrollable: true,
                    labelColor: Colors.black87,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelColor: const Color.fromRGBO(45, 216, 198, 1),
                    unselectedLabelStyle: AppStyles.p,
                    indicatorColor: Colors.green,
                    tabs: List.generate(19, (index) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        child: Tab(
                          text: index == 17
                              ? AppLocalizations.of(context).translate('this_month').capitalize()
                              : (index == 18
                              ? AppLocalizations.of(context).translate('next_month').capitalize()
                              : (index == 16
                              ? AppLocalizations.of(context).translate('last_month').capitalize()
                              : DateFormat("MM/yyyy").format(months[18 - index]))),
                        ),
                      );
                    }),
                  ),
                ),

                // --- HIỂN THỊ CARD TỔNG QUAN (ModernBalanceCard) ---
                ModernBalanceCard(
                  totalBalance: totalBalance,
                  income: income,
                  expense: expense,
                ),

                const SizedBox(height: 10),

                // --- Tiêu đề danh sách ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${AppLocalizations.of(context).translate('spending_list')} ${_monthController.index == 17 ? AppLocalizations.of(context).translate('this_month') : DateFormat("MM/yyyy").format(selectedMonth)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey
                      ),
                    ),
                  ),
                ),

                // --- DANH SÁCH CHI TIÊU ---
                filteredList.isNotEmpty
                    ? Expanded(
                  // Sử dụng ItemSpendingWidget gốc để hiển thị full list theo ngày
                  child: ItemSpendingDay(spendingList: filteredList),
                )
                    : Expanded(
                  child: Center(
                    child: Text(
                      "${AppLocalizations.of(context).translate('no_data')} ${_monthController.index == 17 ? AppLocalizations.of(context).translate('this_month') : DateFormat("MM/yyyy").format(months[18 - _monthController.index])}!",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black45
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}