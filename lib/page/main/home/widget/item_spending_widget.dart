import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constants/function/route_function.dart';
import '../../../../constants/list.dart';
import '../../../../models/spending.dart';
import '../../../../setting/localization/app_localizations.dart';
import '../view_list_spending_page.dart';

class ItemSpendingWidget extends StatelessWidget {
  final Spending spending;

  const ItemSpendingWidget({Key? key, required this.spending}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          // SỬA LỖI: Kiểm tra ID hợp lệ trong danh sách
          child: spending.type == 41
              ? const Icon(Icons.attach_money, color: Colors.green)
              : (spending.type >= 0 && spending.type < listType.length && listType[spending.type]['image'] != null
              ? Image.asset(
            listType[spending.type]['image']!,
            fit: BoxFit.contain,
          )
              : const Icon(Icons.help_outline)),
        ),
        title: Text(
          spending.type == 41
              ? (spending.typeName ?? AppLocalizations.of(context).translate('income'))
          // SỬA LỖI: Lấy title an toàn
              : (spending.type >= 0 && spending.type < listType.length
              ? AppLocalizations.of(context).translate(listType[spending.type]['title']!)
              : "Unknown"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SỬA LỖI: Kiểm tra null cho note
            if (spending.note != null && spending.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                spending.note!, // Dùng dấu ! vì đã check null ở trên
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat("dd/MM/yyyy - HH:mm").format(spending.dateTime),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(spending.money),
          style: TextStyle(
            color: spending.type == 41 ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
Widget loadingItemSpending() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(10),
    itemCount: 10,
    itemBuilder: (context, index) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  textLoading(Random().nextInt(50) + 50),
                  const Spacer(),
                  textLoading(Random().nextInt(50) + 70),
                  const SizedBox(width: 10),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: const Icon(Icons.arrow_forward_ios_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget textLoading(int width, {int height = 25}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: height.toDouble(),
      width: width.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    ),
  );
}
