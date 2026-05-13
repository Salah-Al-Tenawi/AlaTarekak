import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

class ChatApiTestScreen extends StatefulWidget {
  const ChatApiTestScreen({super.key});

  @override
  State<ChatApiTestScreen> createState() => _ChatApiTestScreenState();
}

class _ChatApiTestScreenState extends State<ChatApiTestScreen> {
  final _api = getit.get<DioConSumer>();

  // Controllers
  final _convIdCtrl = TextEditingController(text: '1');
  final _userIdCtrl = TextEditingController(text: '2');
  final _titleCtrl = TextEditingController(text: 'محادثة جديدة');
  final _typeCtrl = TextEditingController(text: 'direct');
  final _contentCtrl = TextEditingController(text: 'مرحباً!');
  final _msgIdCtrl = TextEditingController(text: '1');
  final _pageCtrl = TextEditingController(text: '1');

  // Results per endpoint
  final Map<String, _TestResult?> _results = {
    'getConversations': null,
    'startConversation': null,
    'getMessages': null,
    'sendText': null,
    'deleteMessage': null,
  };

  @override
  void dispose() {
    _convIdCtrl.dispose();
    _userIdCtrl.dispose();
    _titleCtrl.dispose();
    _typeCtrl.dispose();
    _contentCtrl.dispose();
    _msgIdCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(String key, Future<dynamic> Function() call) async {
    setState(() => _results[key] = _TestResult(loading: true));
    try {
      final data = await call();
      setState(() => _results[key] = _TestResult(
            loading: false,
            success: true,
            json: _pretty(data),
          ));
    } catch (e) {
      setState(() => _results[key] = _TestResult(
            loading: false,
            success: false,
            json: e.toString(),
          ));
    }
  }

  String _pretty(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.primary,
        title: Text('اختبار Chat API',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── مدخلات مشتركة ──
          _SharedInputs(
            convIdCtrl: _convIdCtrl,
            userIdCtrl: _userIdCtrl,
            titleCtrl: _titleCtrl,
            typeCtrl: _typeCtrl,
            contentCtrl: _contentCtrl,
            msgIdCtrl: _msgIdCtrl,
            pageCtrl: _pageCtrl,
          ),

          SizedBox(height: 16.h),

          // ── 1. GET conversations ──
          _ApiCard(
            method: 'GET',
            name: 'قائمة المحادثات',
            endpoint: ApiEndPoint.conversation,
            result: _results['getConversations'],
            onTest: () => _run('getConversations',
                () => _api.get(ApiEndPoint.conversation)),
          ),

          // ── 2. POST start conversation ──
          _ApiCard(
            method: 'POST',
            name: 'بدء محادثة جديدة',
            endpoint: ApiEndPoint.conversation,
            result: _results['startConversation'],
            body: () => {
              'other_participant': int.tryParse(_userIdCtrl.text) ?? 2,
              'type': _typeCtrl.text,
              'title': _titleCtrl.text,
            },
            onTest: () => _run(
              'startConversation',
              () => _api.post(ApiEndPoint.conversation, data: {
                'other_participant': int.tryParse(_userIdCtrl.text) ?? 2,
                'type': _typeCtrl.text,
                'title': _titleCtrl.text,
              }),
            ),
          ),

          // ── 3. GET messages ──
          _ApiCard(
            method: 'GET',
            name: 'رسائل المحادثة',
            endpoint:
                '${ApiEndPoint.conversation}/{conversation_id}/messages?page={page}',
            result: _results['getMessages'],
            onTest: () => _run(
              'getMessages',
              () => _api.get(
                '${ApiEndPoint.conversation}/${_convIdCtrl.text}/messages',
                queryParameters: {
                  'page': int.tryParse(_pageCtrl.text) ?? 1,
                },
              ),
            ),
          ),

          // ── 4. POST send text ──
          _ApiCard(
            method: 'POST',
            name: 'إرسال رسالة نصية',
            endpoint:
                '${ApiEndPoint.conversation}/{conversation_id}/messages',
            result: _results['sendText'],
            body: () => {
              'type': 'text',
              'content': _contentCtrl.text,
            },
            onTest: () => _run(
              'sendText',
              () => _api.post(
                '${ApiEndPoint.conversation}/${_convIdCtrl.text}/messages',
                data: {
                  'type': 'text',
                  'content': _contentCtrl.text,
                },
              ),
            ),
          ),

          // ── 5. DELETE message ──
          _ApiCard(
            method: 'DELETE',
            name: 'حذف رسالة',
            endpoint: '${ApiEndPoint.deletmessage}/{message_id}',
            result: _results['deleteMessage'],
            onTest: () => _run(
              'deleteMessage',
              () => _api.delete(
                  '${ApiEndPoint.deletmessage}/${_msgIdCtrl.text}'),
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Shared Inputs
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SharedInputs extends StatelessWidget {
  final TextEditingController convIdCtrl, userIdCtrl, titleCtrl, typeCtrl,
      contentCtrl, msgIdCtrl, pageCtrl;

  const _SharedInputs({
    required this.convIdCtrl,
    required this.userIdCtrl,
    required this.titleCtrl,
    required this.typeCtrl,
    required this.contentCtrl,
    required this.msgIdCtrl,
    required this.pageCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(color: MyColors.shadowLight, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المدخلات المشتركة', style: AppTextStyles.labelLarge),
          SizedBox(height: 12.h),
          Row(children: [
            Expanded(child: _Input(label: 'Conversation ID', ctrl: convIdCtrl, type: TextInputType.number)),
            SizedBox(width: 8.w),
            Expanded(child: _Input(label: 'User ID', ctrl: userIdCtrl, type: TextInputType.number)),
            SizedBox(width: 8.w),
            Expanded(child: _Input(label: 'Page', ctrl: pageCtrl, type: TextInputType.number)),
          ]),
          SizedBox(height: 8.h),
          Row(children: [
            Expanded(child: _Input(label: 'Type', ctrl: typeCtrl)),
            SizedBox(width: 8.w),
            Expanded(child: _Input(label: 'Title', ctrl: titleCtrl)),
          ]),
          SizedBox(height: 8.h),
          Row(children: [
            Expanded(child: _Input(label: 'Content', ctrl: contentCtrl)),
            SizedBox(width: 8.w),
            Expanded(child: _Input(label: 'Message ID', ctrl: msgIdCtrl, type: TextInputType.number)),
          ]),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType type;

  const _Input({
    required this.label,
    required this.ctrl,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textDirection: TextDirection.ltr,
      style: AppTextStyles.labelSmall,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelSmall
            .copyWith(color: MyColors.textSecondary),
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: MyColors.primary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
              BorderSide(color: MyColors.primary.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// API Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ApiCard extends StatefulWidget {
  final String method;
  final String name;
  final String endpoint;
  final _TestResult? result;
  final Map<String, dynamic> Function()? body;
  final VoidCallback onTest;

  const _ApiCard({
    required this.method,
    required this.name,
    required this.endpoint,
    required this.result,
    required this.onTest,
    this.body,
  });

  @override
  State<_ApiCard> createState() => _ApiCardState();
}

class _ApiCardState extends State<_ApiCard> {
  bool _expanded = false;

  Color get _methodColor {
    switch (widget.method) {
      case 'POST':
        return const Color(0xFF4CAF50);
      case 'DELETE':
        return const Color(0xFFF44336);
      default:
        return MyColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _methodColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.method,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _methodColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: AppTextStyles.bodyMedium),
                        Text(
                          widget.endpoint,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: MyColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  if (result != null && !result.loading)
                    Icon(
                      result.success
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: result.success
                          ? const Color(0xFF4CAF50)
                          : MyColors.error,
                      size: 18,
                    ),
                  if (result?.loading == true)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MyColors.accent,
                      ),
                    ),
                  SizedBox(width: 8.w),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: MyColors.textHint,
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          if (_expanded)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  SizedBox(height: 10.h),

                  // Request body preview
                  if (widget.body != null) ...[
                    Text('Request Body:',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: MyColors.textSecondary)),
                    SizedBox(height: 4.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: MyColors.background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ')
                            .convert(widget.body!()),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontFamily: 'monospace',
                          color: MyColors.textPrimary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],

                  // Test button
                  SizedBox(
                    width: double.infinity,
                    height: 40.h,
                    child: ElevatedButton.icon(
                      onPressed:
                          result?.loading == true ? null : widget.onTest,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('تجربة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  // Response
                  if (result != null && !result.loading) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          result.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: result.success
                              ? const Color(0xFF4CAF50)
                              : MyColors.error,
                          size: 14,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          result.success ? 'نجح الطلب ✅' : 'فشل الطلب ❌',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: result.success
                                ? const Color(0xFF4CAF50)
                                : MyColors.error,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxHeight: 300.h),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: result.success
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: result.success
                              ? const Color(0xFF4CAF50)
                              : MyColors.error,
                          width: 0.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          result.json,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontFamily: 'monospace',
                            color: MyColors.textPrimary,
                            fontSize: 11.sp,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TestResult {
  final bool loading;
  final bool success;
  final String json;

  _TestResult({
    required this.loading,
    this.success = false,
    this.json = '',
  });
}
