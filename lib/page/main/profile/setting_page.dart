import 'dart:io' show Directory, File, Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/function/route_function.dart';
import '../../../constants/list.dart';
import '../../../controls/spending_repository.dart';
import '../../../models/spending.dart';
import '../../../models/user.dart' as myuser;
import '../../../setting/bloc/setting_cubit.dart';
import '../../../setting/localization/app_localizations.dart';
import '../profile/about_page.dart';
import '../profile/currency_exchange_rate.dart';
import '../profile/edit_profile_page.dart';
import '../profile/history_page.dart';
import '../chatbot/gemini_chat_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  int language = 0;
  bool darkMode = false;
  bool lockEnabled = false;
  bool driveConnected = false;
  bool driveConnecting = false;
  bool driveUploading = false;
  bool notificationsEnabled = true;
  bool backupInProgress = false;
  DateTime? lastBackup;
  String? lastBackupPath;

  final numberFormat = NumberFormat.currency(locale: "vi_VI");

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      language = prefs.getInt('language') ??
          (Platform.localeName.split('_')[0] == "vi" ? 0 : 1);
      darkMode = prefs.getBool("isDark") ?? false;
      lockEnabled = prefs.getBool("app_lock_enabled") ?? false;
      driveConnected = prefs.getBool("drive_connected") ?? false;
      notificationsEnabled = prefs.getBool("push_notifications") ?? true;
      final backupRaw = prefs.getString('drive_last_backup');
      lastBackupPath = prefs.getString('drive_last_backup_path');
      if (backupRaw != null) {
        lastBackup = DateTime.tryParse(backupRaw);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('setting')),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<myuser.User?>(
          valueListenable: SpendingRepository.userNotifier,
          builder: (_, user, __) {
            return RefreshIndicator(
              onRefresh: _loadPreferences,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildAccountSection(localization, user),
                  const SizedBox(height: 12),
                  _buildBackupSection(localization),
                  const SizedBox(height: 12),
                  _buildSecuritySection(localization),
                  const SizedBox(height: 12),
                  _buildAppearanceSection(localization),
                  const SizedBox(height: 12),
                  _buildLanguageSection(localization),
                  const SizedBox(height: 12),
                  _buildNotificationSection(localization),
                  const SizedBox(height: 12),
                  _buildMoreSection(localization),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    AppLocalizations localization,
    myuser.User? user,
  ) {
    return _buildSection(
      title: localization.translate('account'),
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1,
                ),
            backgroundImage: _buildAvatar(user),
            child: _buildAvatar(user) == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            user?.name ?? localization.translate('account'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            user != null
                ? "${localization.translate('monthly_money')}: ${numberFormat.format(user.money)}"
                : localization.translate('edit_personal_information_and_other_settings'),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(context).push(
              createRoute(
                screen: const EditProfilePage(),
                begin: const Offset(1, 0),
              ),
            );
          },
        ),
      ],
    );
  }

  ImageProvider? _buildAvatar(myuser.User? user) {
    if (user == null || user.avatar.isEmpty) return null;
    if (user.avatar.startsWith('http')) {
      return CachedNetworkImageProvider(user.avatar);
    }
    if (user.avatar.startsWith('assets/')) {
      return AssetImage(user.avatar);
    }
    final file = File(user.avatar);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  Widget _buildBackupSection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('cloud_backup'),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            FontAwesomeIcons.googleDrive,
            color: Color.fromRGBO(66, 133, 244, 1),
          ),
          title: Text(
            localization.translate(
              driveConnected ? 'drive_connected' : 'connect_google_drive',
            ),
          ),
          subtitle: Text(
            localization.translate('drive_sync_description'),
          ),
          trailing: driveConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch.adaptive(
                  value: driveConnected,
                  onChanged: (_) => _toggleDriveConnection(localization),
                ),
        ),
        if (backupInProgress) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            lastBackup == null
                ? localization.translate('no_backup_yet')
                : "${localization.translate('last_backup')}: ${_formatBackupTime(lastBackup!)}",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (lastBackupPath != null) ...[
            const SizedBox(height: 6),
            Text(
              p.basename(lastBackupPath!),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(localization.translate('backup_now')),
            onPressed: backupInProgress
                ? null
                : () => _startBackup(localization),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: driveUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.drive_folder_upload_outlined),
            label: Text(localization.translate('upload_backup_drive')),
            onPressed: driveUploading || backupInProgress
                ? null
                : () => _uploadBackupToDrive(localization),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('security'),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: lockEnabled,
          title: Text(localization.translate('pin_lock')),
          subtitle: Text(localization.translate('require_pin_to_open')),
          onChanged: (value) => _toggleLock(localization, value),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('appearance'),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: darkMode,
          title: Text(localization.translate('dark_mode')),
          subtitle: Text(localization.translate('light_mode')),
          onChanged: _toggleTheme,
        ),
      ],
    );
  }

  Widget _buildLanguageSection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('language'),
      children: [
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: Text(localization.translate('language_vietnamese')),
              selected: language == 0,
              onSelected: (_) => _changeLanguage(localization, 0),
            ),
            ChoiceChip(
              label: Text(localization.translate('language_english')),
              selected: language == 1,
              onSelected: (_) => _changeLanguage(localization, 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('push_notifications'),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: notificationsEnabled,
          title: Text(localization.translate('push_notifications')),
          subtitle: Text(localization.translate('stay_informed')),
          onChanged: (value) => _toggleNotifications(localization, value),
        ),
      ],
    );
  }

  Widget _buildMoreSection(AppLocalizations localization) {
    return _buildSection(
      title: localization.translate('more'),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded),
          title: Text(localization.translate('history')),
          onTap: () {
            Navigator.of(context).push(
              createRoute(
                screen: const HistoryPage(),
                begin: const Offset(1, 0),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.attach_money_rounded),
          title: Text(localization.translate('currency_exchange_rate')),
          onTap: () {
            Navigator.of(context).push(
              createRoute(
                screen: const CurrencyExchangeRate(),
                begin: const Offset(1, 0),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(FontAwesomeIcons.circleInfo),
          title: Text(localization.translate('about')),
          onTap: () {
            Navigator.of(context).push(
              createRoute(
                screen: const AboutPage(),
                begin: const Offset(1, 0),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.smart_toy_outlined),
          title: Text(localization.translate('gemini_assistant')),
          subtitle: Text(localization.translate('gemini_assistant_description')),
          onTap: () {
            Navigator.of(context).push(
              createRoute(
                screen: const GeminiChatPage(),
                begin: const Offset(1, 0),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleDriveConnection(AppLocalizations localization) async {
    if (driveConnecting) return;
    setState(() => driveConnecting = true);
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(milliseconds: 600));
    final newValue = !driveConnected;
    await prefs.setBool('drive_connected', newValue);

    if (!mounted) return;
    setState(() {
      driveConnected = newValue;
      driveConnecting = false;
    });

    Fluttertoast.showToast(
      msg: localization.translate(
        newValue ? 'drive_connected' : 'drive_disconnected',
      ),
    );
  }

  Future<void> _startBackup(AppLocalizations localization) async {
    if (!driveConnected) {
      Fluttertoast.showToast(
        msg: localization.translate('connect_drive_first'),
      );
      return;
    }

    setState(() => backupInProgress = true);
    try {
      final path = await _exportCSV(localization);
      if (path == null) {
        Fluttertoast.showToast(
          msg: localization.translate('backup_failed'),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('drive_last_backup', now.toIso8601String());
      await prefs.setString('drive_last_backup_path', path);
      if (!mounted) return;
      setState(() {
        lastBackup = now;
        lastBackupPath = path;
      });
      Fluttertoast.showToast(
        msg:
            "${localization.translate('backup_ready_for_drive')}\n$path",
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => backupInProgress = false);
      }
    }
  }

  Future<void> _uploadBackupToDrive(AppLocalizations localization) async {
    if (!driveConnected) {
      Fluttertoast.showToast(
        msg: localization.translate('connect_drive_first'),
      );
      return;
    }
    if (lastBackupPath == null) {
      Fluttertoast.showToast(
        msg: localization.translate('no_backup_yet'),
      );
      return;
    }
    final file = File(lastBackupPath!);
    if (!file.existsSync()) {
      Fluttertoast.showToast(
        msg: localization.translate('backup_missing'),
      );
      return;
    }

    setState(() => driveUploading = true);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: localization.translate('backup_ready_for_drive'),
      );
    } finally {
      if (mounted) {
        setState(() => driveUploading = false);
      }
    }
  }

  Future<void> _toggleLock(
    AppLocalizations localization,
    bool enabled,
  ) async {
    if (enabled) {
      await Navigator.pushNamed(context, '/setup-lock');
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => lockEnabled = prefs.getBool('app_lock_enabled') ?? false);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', false);
      if (!mounted) return;
      setState(() => lockEnabled = false);
      Fluttertoast.showToast(
        msg: localization.translate('pin_lock_disabled'),
      );
    }
  }

  Future<void> _toggleNotifications(
    AppLocalizations localization,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    if (!mounted) return;
    setState(() => notificationsEnabled = value);
    Fluttertoast.showToast(
      msg: localization.translate(
        value ? 'notifications_enabled' : 'notifications_disabled',
      ),
    );
  }

  Future<void> _toggleTheme(bool value) async {
    BlocProvider.of<SettingCubit>(context).changeTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', value);
    if (!mounted) return;
    setState(() => darkMode = value);
  }

  Future<void> _changeLanguage(
    AppLocalizations localization,
    int lang,
  ) async {
    if (lang == language) return;
    if (lang == 0) {
      BlocProvider.of<SettingCubit>(context).toVietnamese();
    } else {
      BlocProvider.of<SettingCubit>(context).toEnglish();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language', lang);
    if (!mounted) return;
    setState(() => language = lang);
    Fluttertoast.showToast(
      msg: localization.translate(
        lang == 0 ? 'language_vietnamese' : 'language_english',
      ),
    );
  }

  Future<String?> _exportCSV(AppLocalizations localization) async {
    List<Spending> spendingList =
        List<Spending>.from(SpendingRepository.spendingNotifier.value);
    List<List<dynamic>> rows = [];

    rows.add([
      "money",
      "type",
      "note",
      "date",
      "image",
      "location",
      "friends",
    ]);
    for (var item in spendingList) {
      List<dynamic> row = [];
      row.add(item.money);
      row.add(item.type == 41
          ? item.typeName
          : localization.translate(listType[item.type]['title']!));
      row.add(item.note);
      row.add(DateFormat("dd/MM/yyyy - HH:mm:ss").format(item.dateTime));
      row.add(item.image);
      row.add(item.location);
      row.add(item.friends);
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      }
    } catch (_) {}

    if (directory == null) return null;

    String path =
        '${directory.path}/TNT_${DateFormat('dd_MM_yyyy_HH_mm_ss').format(DateTime.now())}.csv';
    File f = File(path);
    await f.writeAsString(csv);
    return path;
  }

  String _formatBackupTime(DateTime time) {
    return DateFormat("dd/MM/yyyy HH:mm").format(time);
  }
}
