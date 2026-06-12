/// نتيجة POST /api/contact — المغلف 200 و201 يعاملان بنفس الطريقة:
/// افتح شاشة الشات بـ conversationId
class SupportChatEntity {
  final int conversationId;
  final String? agentName;

  const SupportChatEntity({
    required this.conversationId,
    this.agentName,
  });
}
