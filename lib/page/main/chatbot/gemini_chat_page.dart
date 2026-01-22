import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/list.dart';
import '../../../controls/gemini_service.dart';
import '../../../controls/spending_repository.dart';
import '../../../models/spending.dart';
import '../../../setting/localization/app_localizations.dart';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _loading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedIntroMessage());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiKey = prefs.getString('gemini_api_key'));
  }

  Future<void> _saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    if (!mounted) return;
    setState(() => _apiKey = apiKey);
  }

  void _seedIntroMessage() {
    if (_messages.isNotEmpty) return;
    final localization = AppLocalizations.of(context);
    setState(() {
      _messages.add(
        _ChatMessage(
          text: localization.translate('chatbot_intro'),
          isUser: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('gemini_assistant')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_apiKey == null || _apiKey!.isEmpty)
              _buildApiKeyBanner(localization)
            else
              _buildApiKeyInfo(localization),
            Expanded(
              child: _buildChatList(),
            ),
            _buildSuggestions(localization),
            _buildInputBar(localization),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyBanner(AppLocalizations localization) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localization.translate('gemini_api_key_required'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _openApiKeyDialog,
            child: Text(localization.translate('enter_api_key')),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInfo(AppLocalizations localization) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localization.translate('gemini_api_key_saved'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _openApiKeyDialog,
            child: Text(localization.translate('update')),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final alignment =
            message.isUser ? Alignment.centerRight : Alignment.centerLeft;
        final color = message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant;
        final textColor = message.isUser
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface;
        return Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, height: 1.4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions(AppLocalizations localization) {
    final suggestions = [
      localization.translate('chatbot_example_spending'),
      localization.translate('chatbot_example_income'),
      localization.translate('chatbot_example_summary'),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(suggestions[index]),
            onPressed: _loading
                ? null
                : () {
                    _controller.text = suggestions[index];
                    _handleSend();
                  },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations localization) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: localization.translate('chatbot_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openApiKeyDialog() async {
    final localization = AppLocalizations.of(context);
    final controller = TextEditingController(text: _apiKey);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localization.translate('gemini_api_key')),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              hintText: localization.translate('enter_api_key'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localization.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: Text(localization.translate('save')),
            ),
          ],
        );
      },
    );
    if (saved != null && saved.isNotEmpty) {
      await _saveApiKey(saved);
    }
  }

  Future<void> _handleSend() async {
    final localization = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      _appendAssistantMessage(localization.translate('chatbot_missing_key'));
      return;
    }
    _controller.clear();
    _appendUserMessage(text);
    setState(() => _loading = true);
    try {
      final response = await _requestGemini(text);
      await _handleGeminiResponse(response, originalText: text);
    } catch (_) {
      _appendAssistantMessage(localization.translate('chatbot_error'));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String> _requestGemini(String text) async {
    final localization = AppLocalizations.of(context);
    final categories = _buildCategoryList(localization);
    final spendingData = _buildSpendingContext();

    final prompt = StringBuffer()
      ..writeln(
          'Bạn là trợ lý tài chính. Nhiệm vụ: thêm chi tiêu, thêm thu nhập, hoặc tóm tắt/đánh giá chi tiêu dựa trên dữ liệu.')
      ..writeln(
          'Luôn trả về JSON thuần, không code block, không markdown.')
      ..writeln(
          'Schema JSON: {"intent":"add_spending|add_income|summary|chat","amount":number|null,"category_key":string|null,"category_label":string|null,"note":string|null,"date":"YYYY-MM-DD"|null,"time":"HH:mm"|null,"summary_range":"this_week|this_month|custom|all"|null,"range_start":"YYYY-MM-DD"|null,"range_end":"YYYY-MM-DD"|null,"response":string}.')
      ..writeln('Nếu người dùng yêu cầu tóm tắt/đánh giá, đặt intent=summary.')
      ..writeln('Danh sách category_key hợp lệ:')
      ..writeln(categories)
      ..writeln(
          'Dữ liệu chi tiêu hiện có (danh sách, số âm là chi tiêu, số dương là thu nhập):')
      ..writeln(spendingData)
      ..writeln('Yêu cầu người dùng: "$text"');

    final service = GeminiService(apiKey: _apiKey!);
    return service.generateContent(prompt: prompt.toString());
  }

  Future<void> _handleGeminiResponse(String response,
      {required String originalText}) async {
    final localization = AppLocalizations.of(context);
    final parsed = _parseGeminiResponse(response);
    if (parsed == null) {
      _appendAssistantMessage(response);
      return;
    }

    final intent = parsed.intent;
    if (intent == 'add_spending' || intent == 'add_income') {
      final created = await _createSpendingFromIntent(parsed, intent);
      if (created) {
        _appendAssistantMessage(parsed.response.isNotEmpty
            ? parsed.response
            : localization.translate('chatbot_add_success'));
        return;
      }
    }

    if (intent == 'summary') {
      final reply = parsed.response.isNotEmpty
          ? parsed.response
          : localization.translate('chatbot_summary_ready');
      _appendAssistantMessage(reply);
      return;
    }

    _appendAssistantMessage(
        parsed.response.isNotEmpty ? parsed.response : response);
  }

  _GeminiResult? _parseGeminiResponse(String response) {
    try {
      final cleaned = response.trim();
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      final jsonText = cleaned.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      return _GeminiResult.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _createSpendingFromIntent(
    _GeminiResult result,
    String intent,
  ) async {
    if (result.amount == null || result.amount == 0) return false;
    final category = result.categoryKey;
    final foundIndex = _findCategoryIndex(category);
    final date = result.date ?? DateTime.now();
    final time = result.time ?? DateTime.now();
    final dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final isIncome = intent == 'add_income';
    final money = isIncome ? result.amount! : -result.amount!;
    final type = foundIndex ?? (isIncome ? 36 : 1);

    final spending = Spending(
      money: money,
      type: type,
      typeName: foundIndex == null ? result.categoryLabel : null,
      dateTime: dateTime,
      note: result.note,
    );

    await SpendingRepository.addSpending(spending);
    return true;
  }

  int? _findCategoryIndex(String? categoryKey) {
    if (categoryKey == null || categoryKey.isEmpty) return null;
    for (int i = 0; i < listType.length; i++) {
      if (listType[i]['title'] == categoryKey) {
        return i;
      }
    }
    return null;
  }

  String _buildCategoryList(AppLocalizations localization) {
    final buffer = StringBuffer();
    for (final item in listType) {
      final title = item['title'];
      final image = item['image'];
      if (title == null || image == null) continue;
      buffer.writeln('- $title: ${localization.translate(title)}');
    }
    return buffer.toString();
  }

  String _buildSpendingContext() {
    final list = SpendingRepository.spendingNotifier.value;
    final recent = list.take(120).toList();
    if (recent.isEmpty) return '[]';
    final data = recent
        .map(
          (item) => {
            'date': _dateFormat.format(item.dateTime),
            'time': _timeFormat.format(item.dateTime),
            'amount': item.money,
            'category_key': listType[item.type]['title'],
            'category_label': item.type == 41 ? item.typeName : null,
            'note': item.note,
          },
        )
        .toList();
    return jsonEncode(data);
  }

  void _appendUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _appendAssistantMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _GeminiResult {
  _GeminiResult({
    required this.intent,
    required this.response,
    this.amount,
    this.categoryKey,
    this.categoryLabel,
    this.note,
    this.date,
    this.time,
  });

  final String intent;
  final String response;
  final int? amount;
  final String? categoryKey;
  final String? categoryLabel;
  final String? note;
  final DateTime? date;
  final DateTime? time;

  factory _GeminiResult.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value, DateFormat format) {
      if (value == null || value.isEmpty) return null;
      try {
        return format.parseStrict(value);
      } catch (_) {
        return null;
      }
    }

    final amountValue = json['amount'];
    int? amount;
    if (amountValue is num) {
      amount = amountValue.round();
    }
    return _GeminiResult(
      intent: (json['intent'] as String? ?? '').trim(),
      response: (json['response'] as String? ?? '').trim(),
      amount: amount,
      categoryKey: (json['category_key'] as String?)?.trim(),
      categoryLabel: (json['category_label'] as String?)?.trim(),
      note: (json['note'] as String?)?.trim(),
      date: parseDate(json['date'] as String?, DateFormat('yyyy-MM-dd')),
      time: parseDate(json['time'] as String?, DateFormat('HH:mm')),
    );
  }
}
