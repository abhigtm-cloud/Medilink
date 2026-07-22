import 'package:flutter/material.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:medilink/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';

/// Direct entry point into the AI assistant pre-set to the symptomChecker
/// capability — same chat UI as [AiAssistantScreen], just a distinct nav
/// target per architecture doc §20's screen list.
class SymptomCheckerScreen extends StatelessWidget {
  const SymptomCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiAssistantScreen(
      initialCapability: AiCapability.symptomChecker,
      title: 'Symptom Checker',
    );
  }
}
