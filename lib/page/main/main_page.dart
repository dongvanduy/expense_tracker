import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // Import thư viện mới
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/constants/function/on_will_pop.dart';
import 'package:expense_tracker/constants/function/route_function.dart';
import 'package:expense_tracker/page/add_spending/add_spending.dart';
import 'package:expense_tracker/page/main/analytic/analytic_page.dart';
import 'package:expense_tracker/page/main/calendar/calendar_page.dart';
import 'package:expense_tracker/page/main/chatbot/gemini_chat_page.dart';
import 'package:expense_tracker/page/main/home/home_page.dart';
import 'package:expense_tracker/page/main/profile/setting_page.dart';

import '../../setting/localization/app_localizations.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentTab = 0;

  // Danh sách màn hình giữ nguyên như code của bạn
  List<Widget> screens = [
    const HomePage(),
    const CalendarPage(),
    const AnalyticPage(),
    const SettingPage()
  ];

  DateTime? currentBackPressTime;
  final PageStorageBucket bucket = PageStorageBucket();
  XFile? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền xám nhẹ để làm nổi bật thanh menu trắng
      backgroundColor: const Color(0xFFF5F7FA),

      body: Stack(
        children: [
          WillPopScope(
            onWillPop: () => onWillPop(
              action: (now) => currentBackPressTime = now,
              currentBackPressTime: currentBackPressTime,
            ),
            child: PageStorage(
              bucket: bucket,
              child: screens[currentTab],
            ),
          ),

          // Nút Gemini Chat (Vẫn giữ vị trí cũ hoặc chỉnh bottom cao hơn xíu để tránh menu)
          Positioned(
            right: 16,
            bottom: 30, // Nâng lên một chút để không bị che bởi menu mới
            child: _buildGeminiChatButton(context),
          ),
        ],
      ),

      // Nút Thêm Chi Tiêu (Floating Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            createRoute(screen: const AddSpendingPage()),
          );
        },
        backgroundColor: const Color(0xFF4A00E0), // Màu tím hiện đại (hoặc màu primary của bạn)
        elevation: 8,
        shape: const CircleBorder(), // Bo tròn hoàn toàn
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      // Đặt nút Add ở giữa dock
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- PHẦN MENU HIỆN ĐẠI MỚI ---
      bottomNavigationBar: Container(
        color: Colors.transparent, // Nền trong suốt
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Cách lề dưới và 2 bên
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // Bo góc "viên thuốc"
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Bóng mờ nhẹ
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: GNav(
              gap: 8, // Khoảng cách giữa icon và chữ
              activeColor: Colors.white, // Màu icon khi được chọn
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              duration: const Duration(milliseconds: 400), // Thời gian hiệu ứng trượt
              tabBackgroundColor: const Color(0xFF4A00E0), // Màu nền tím khi chọn tab
              color: Colors.grey[500], // Màu icon khi chưa chọn

              tabs: [
                GButton(
                  icon: FontAwesomeIcons.house,
                  text: AppLocalizations.of(context).translate('home'),
                ),
                GButton(
                  icon: Icons.calendar_month_outlined,
                  text: AppLocalizations.of(context).translate('calendar'),
                ),
                GButton(
                  icon: FontAwesomeIcons.chartPie,
                  text: AppLocalizations.of(context).translate('analytic'),
                ),
                GButton(
                  // Logic icon Setting/User giữ nguyên như ý bạn
                  icon: currentTab == 3 ? FontAwesomeIcons.solidCircleUser : FontAwesomeIcons.gear,
                  text: AppLocalizations.of(context).translate('setting'),
                ),
              ],
              selectedIndex: currentTab,
              onTabChange: (index) {
                setState(() {
                  currentTab = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget Gemini giữ nguyên (chỉ sửa lại style một chút cho đồng bộ nếu cần)
  Widget _buildGeminiChatButton(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context).translate('gemini_assistant'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.of(context).push(
              createRoute(screen: const GeminiChatPage()),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const SizedBox(
              height: 52,
              width: 52,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => this.image = image);
      }
    } on PlatformException catch (_) {}
  }
}