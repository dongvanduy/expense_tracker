import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Import Repository để lấy dữ liệu offline
import 'package:expense_tracker/controls/spending_repository.dart';
import 'package:expense_tracker/models/spending.dart';
import 'package:expense_tracker/constants/function/extension.dart';
import '../../../constants/app_styles.dart';
import '../../../setting/localization/app_localizations.dart';

// Import widget Bento Grid (Đảm bảo bạn đã tạo file này theo hướng dẫn trước)
import 'analytic_bento_view.dart';

class AnalyticPage extends StatefulWidget {
  const AnalyticPage({Key? key}) : super(key: key);

  @override
  State<AnalyticPage> createState() => _AnalyticPageState();
}

class _AnalyticPageState extends State<AnalyticPage> with TickerProviderStateMixin {
  // Controller cho danh sách tháng (19 tháng)
  late TabController _monthController;
  // Controller cho loại giao dịch (Chi tiêu / Thu nhập)
  late TabController _typeController;

  List<DateTime> months = [];

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo Controller cho 2 Tab: Chi tiêu & Thu nhập
    _typeController = TabController(length: 2, vsync: this);

    // 2. Khởi tạo Controller cho 19 tháng (Quá khứ -> Tương lai)
    _monthController = TabController(length: 19, vsync: this);
    _monthController.index = 17; // Mặc định chọn tháng hiện tại (index 17)

    // Lắng nghe sự kiện vuốt tháng để reload lại giao diện
    _monthController.addListener(() {
      if (_monthController.indexIsChanging) return;
      setState(() {});
    });

    // 3. Tạo dữ liệu danh sách tháng
    DateTime now = DateTime(DateTime.now().year, DateTime.now().month);
    // Tháng sau (Future)
    months = [DateTime(now.year, now.month + 1), now];
    // 17 tháng trước (Past)
    for (int i = 1; i < 19; i++) {
      now = DateTime(now.year, now.month - 1);
      months.add(now);
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền xám nhạt hiện đại (Soft UI)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).translate('analytic'),
          style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 20
          ),
        ),
        // TabBar chọn Chi tiêu / Thu nhập nằm dưới AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _typeController,
              labelColor: const Color(0xFF4A00E0), // Màu tím/xanh đậm khi chọn
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              indicatorColor: const Color(0xFF4A00E0),
              indicatorWeight: 3,
              tabs: [
                Tab(text: AppLocalizations.of(context).translate('expense')),
                Tab(text: AppLocalizations.of(context).translate('income')),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- PHẦN 1: THANH CHỌN THÁNG (Month Selector) ---
          Container(
            height: 60,
            color: Colors.white,
            child: TabBar(
              controller: _monthController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              // Trang trí nút tháng được chọn (Hình viên thuốc màu xanh)
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A00E0).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: List.generate(19, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Tab(
                    child: Text(
                      index == 17
                          ? AppLocalizations.of(context).translate('this_month').capitalize()
                          : (index == 18
                          ? AppLocalizations.of(context).translate('next_month').capitalize()
                          : DateFormat("MM/yyyy").format(months[18 - index])),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
            ),
          ),

          // --- PHẦN 2: NỘI DUNG CHÍNH (Bento Grid) ---
          Expanded(
            // Lắng nghe dữ liệu từ SQLite (SpendingRepository)
            child: ValueListenableBuilder<List<Spending>>(
              valueListenable: SpendingRepository.spendingNotifier,
              builder: (context, fullList, _) {

                // 1. Lọc danh sách theo tháng đang chọn
                final selectedMonth = months[18 - _monthController.index];
                final monthList = fullList.where((element) {
                  return element.dateTime.month == selectedMonth.month &&
                      element.dateTime.year == selectedMonth.year;
                }).toList();

                // 2. Hiển thị Grid theo 2 tab (Chi tiêu / Thu nhập)
                return TabBarView(
                  controller: _typeController,
                  children: [
                    // Tab 1: Chi tiêu (isIncome = false)
                    AnalyticBentoView(list: monthList, isIncome: false),

                    // Tab 2: Thu nhập (isIncome = true)
                    AnalyticBentoView(list: monthList, isIncome: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}