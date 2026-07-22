/// Which capability the assistant is being asked to act as — mirrors
/// `AiCapability` in functions/src/ai/sendAiMessage.ts exactly (a string
/// union server-side, an enum here). See architecture doc §11.
enum AiCapability {
  symptomChecker,
  healthTips,
  reportExplanation,
  diseaseRiskAnalysis,
  doctorRecommendation;

  /// The exact string sendAiMessage expects/returns in `metadata.capability`.
  String get value => name;

  static AiCapability fromValue(String? value) {
    return AiCapability.values.firstWhere(
      (c) => c.value == value,
      orElse: () => AiCapability.symptomChecker,
    );
  }

  String get label {
    switch (this) {
      case AiCapability.symptomChecker:
        return 'Symptom Checker';
      case AiCapability.healthTips:
        return 'Health Tips';
      case AiCapability.reportExplanation:
        return 'Report Explanation';
      case AiCapability.diseaseRiskAnalysis:
        return 'Disease Risk';
      case AiCapability.doctorRecommendation:
        return 'Find a Doctor';
    }
  }
}

enum ChatRole {
  user,
  assistant,
  system;

  static ChatRole fromValue(String? value) {
    return ChatRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ChatRole.system,
    );
  }
}

/// One turn in `ai_chats/{chatId}/messages`. See architecture doc §4.12/§11.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime? createdAt;

  /// True only on an assistant message whose reply was short-circuited by
  /// the emergency-keyword pre-filter (server-side, functions/src/ai/
  /// sendAiMessage.ts). The UI must render this as an "Emergency SOS" card
  /// instead of a normal chat bubble — never as ordinary conversational
  /// text. See architecture doc §11's hard safety constraint.
  final bool urgencyFlag;

  final AiCapability? capability;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.urgencyFlag = false,
    this.capability,
  });
}
