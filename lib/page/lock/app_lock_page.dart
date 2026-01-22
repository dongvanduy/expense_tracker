import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/function/on_will_pop.dart';
import '../../setting/localization/app_localizations.dart';

class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key, this.setup = false});
  final bool setup;

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _prefsLoaded = false;
  String? _storedPassword;

  @override
  void initState() {
    super.initState();
    _loadStoredPassword();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _storedPassword = prefs.getString('app_password');
      _prefsLoaded = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('app_password');
    setState(() {
      _storedPassword = stored;
      _prefsLoaded = true;
    });

    // --- SỬA Ở ĐÂY: CƠ CHẾ TỰ ĐỘNG SỬA LỖI ---
    // Nếu đang ở màn hình Đăng nhập (!widget.setup) mà không tìm thấy mật khẩu (stored == null)
    if (!widget.setup && stored == null) {
      // Tự động tắt tính năng khóa để người dùng vào được app
      await prefs.setBool('app_lock_enabled', false);

      if (!mounted) return;
      // Chuyển thẳng vào màn hình chính
      Navigator.pushReplacementNamed(context, '/main');
      return;
    }
    // ----------------------------------------

    // Logic tạo mật khẩu mới (chỉ chạy khi widget.setup = true)
    if (widget.setup) {
      if (_passwordController.text != _confirmController.text) {
        setState(() => _error = AppLocalizations.of(context)
            .translate('passwords_do_not_match'));
        return;
      }
      await prefs.setString('app_password', _passwordController.text);
      await prefs.setBool('app_lock_enabled', true);
      await prefs.setBool('firstStart', false);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    }
    // Logic đăng nhập (chỉ chạy khi có mật khẩu stored)
    else {
      if (_passwordController.text == stored) {
        await prefs.setBool('firstStart', false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() => _error =
            AppLocalizations.of(context).translate('incorrect_password'));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WillPopScope(
        onWillPop: () => onWillPop(
          action: (_) {},
          currentBackPressTime: null,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.setup
                              ? AppLocalizations.of(context)
                                  .translate('create_app_password')
                              : AppLocalizations.of(context)
                                  .translate('enter_app_password'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)
                                .translate('password'),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please_enter_valid_amount');
                            }
                            if (value.length < 4) {
                              return AppLocalizations.of(context)
                                  .translate('password_too_short');
                            }
                            return null;
                          },
                        ),
                        if (widget.setup || _confirmController.text.isNotEmpty)
                          const SizedBox(height: 20),
                        if (widget.setup)
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .translate('confirm_password'),
                            ),
                            validator: (value) {
                              if (widget.setup &&
                                  (value == null || value.isEmpty)) {
                                return AppLocalizations.of(context)
                                    .translate('please_enter_valid_amount');
                              }
                              return null;
                            },
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          )
                        ],
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('continue'),
                            ),
                          ),
                        ),
                        if (!widget.setup)
                          if (_prefsLoaded && _storedPassword == null)
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/setup-lock');
                              },
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('create_app_password'),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
