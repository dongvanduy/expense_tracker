import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ModernBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double income;
  final double expense;

  const ModernBalanceCard({
    Key? key,
    required this.totalBalance,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Định dạng tiền tệ (Ví dụ: 10,000,000 đ)
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      width: double.infinity,
      height: 220, // Chiều cao thẻ
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25), // Bo góc mềm mại
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A00E0), // Tím đậm
            Color(0xFF8E2DE2), // Tím hồng sáng
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withOpacity(0.5), // Bóng màu tím
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Họa tiết trang trí mờ ảo (Circle Decor)
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Phần Header: Text và Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tổng số dư",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currencyFormat.format(totalBalance),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 30, // Số to, rõ ràng
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Icon Chip thẻ (giả lập)
                    const Icon(Icons.nfc, color: Colors.white54, size: 40),
                  ],
                ),

                const Spacer(),

                // Phần Thu - Chi ở dưới
                Row(
                  children: [
                    // Thu nhập (Income)
                    _buildInfoItem(
                      icon: Icons.arrow_downward,
                      iconColor: Colors.greenAccent,
                      label: "Thu nhập",
                      value: currencyFormat.format(income),
                    ),
                    const SizedBox(width: 30),
                    // Chi tiêu (Expense)
                    _buildInfoItem(
                      icon: Icons.arrow_upward,
                      iconColor: Colors.redAccent,
                      label: "Chi tiêu",
                      value: currencyFormat.format(expense),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con để hiển thị Thu/Chi
  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}