import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:expense_tracker/models/spending.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:expense_tracker/constants/list.dart'; // Import file chứa listType

class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const BentoCard({
    Key? key,
    required this.child,
    this.color,
    this.gradient,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class AnalyticBentoView extends StatelessWidget {
  final List<Spending> list;
  final bool isIncome;

  const AnalyticBentoView({Key? key, required this.list, required this.isIncome}) : super(key: key);

  // SỬA LỖI 1: Kiểm tra index hợp lệ trong List thay vì containsKey
  String getIconPath(int typeId) {
    if (typeId >= 0 && typeId < listType.length) {
      return listType[typeId]['image'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    Map<int, double> categoryMap = {};

    for (var item in list) {
      // 41 là quy ước code cũ cho Thu nhập, hoặc bạn có thể thay đổi logic này tùy database
      bool itemIsIncome = item.type == 41;

      if (itemIsIncome == isIncome) {
        total += item.money;
        categoryMap[item.type] = (categoryMap[item.type] ?? 0) + item.money;
      }
    }

    String topCategoryName = "Không có";
    double topAmount = 0;
    int topTypeId = -1;

    if (categoryMap.isNotEmpty) {
      var sortedEntries = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topTypeId = sortedEntries.first.key;
      topAmount = sortedEntries.first.value;

      if (topTypeId == 41) {
        topCategoryName = "Thu nhập";
      } else if (topTypeId >= 0 && topTypeId < listType.length) {
        // SỬA LỖI 2: Truy cập list bằng index
        topCategoryName = listType[topTypeId]['title'] ?? 'Khác';
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Ô 1: Tổng tiền
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: BentoCard(
                gradient: isIncome
                    ? const LinearGradient(colors: [Color(0xFF43cea2), Color(0xFF185a9d)])
                    : const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isIncome ? "Tổng Thu Nhập" : "Tổng Chi Tiêu",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(total),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ô 2: Top Danh mục
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: BentoCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      // SỬA LỖI 3: Logic hiển thị icon
                      child: (topTypeId >= 0 && topTypeId < listType.length && listType[topTypeId]['image'] != null)
                          ? Image.asset(listType[topTypeId]['image']!, width: 24, height: 24)
                          : const Icon(Icons.star, color: Colors.orange, size: 24),
                    ),
                    const Spacer(),
                    Text("Nổi bật nhất", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                        topCategoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                    Text(currencyFormat.format(topAmount), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),

          // Ô 3: Số giao dịch
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: BentoCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.blue, size: 24),
                    ),
                    const Spacer(),
                    Text("Số giao dịch", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      "${list.where((e) => (e.type == 41) == isIncome).length}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ô 4: Biểu đồ
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1.6,
            child: FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: BentoCard(
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.pie_chart, color: Colors.purple, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text("Phân bổ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: categoryMap.isEmpty
                          ? const Center(child: Text("Chưa có dữ liệu", style: TextStyle(color: Colors.grey)))
                          : PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          borderData: FlBorderData(show: false),
                          sections: categoryMap.entries.map((e) {
                            final index = categoryMap.keys.toList().indexOf(e.key);
                            final color = Colors.primaries[index % Colors.primaries.length];
                            final iconPath = getIconPath(e.key);

                            return PieChartSectionData(
                              value: e.value,
                              title: "",
                              color: color,
                              radius: 30,
                              badgeWidget: _Badge(
                                iconPath: iconPath,
                                size: 30,
                                borderColor: color,
                              ),
                              badgePositionPercentageOffset: 1.3,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String iconPath;
  final double size;
  final Color borderColor;

  const _Badge({required this.iconPath, required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: iconPath.isNotEmpty
            ? Image.asset(iconPath, fit: BoxFit.contain)
            : const Text("?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}