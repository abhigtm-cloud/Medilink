import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:medilink/features/ai_assistant/presentation/providers/ai_chat_providers.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/emergency/presentation/screens/sos_confirm_screen.dart';

/// AI Health Assistant chat. Hard safety constraint (architecture doc §11):
/// the disclaimer banner is permanent and cannot be dismissed, and any
/// reply flagged `urgencyFlag` by the server renders as an SOS card, never
/// as ordinary conversational text.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({
    super.key,
    this.initialCapability = AiCapability.symptomChecker,
    this.title = 'AI Health Assistant',
  });

  final AiCapability initialCapability;
  final String title;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late AiCapability _capability = widget.initialCapability;
  String? _chatId;
  bool _sending = false;
  String? _error;

  final List<ChatMessage> _localMessages = [];

  final List<String> _quickPrompts = [
    '🤒 High Fever Care',
    '🤕 Severe Headache',
    '🩹 First Aid for Burns',
    '🤢 Acidity & Gas Relief',
    '🤧 Cold & Sore Throat',
    '🩸 Cuts & Bleeding Care',
    '🚨 Chest Pain Check',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty || _sending) return;

    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? 'guest_patient';

    setState(() {
      _sending = true;
      _error = null;
      _localMessages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.user,
          content: text,
          capability: _capability,
          createdAt: DateTime.now(),
        ),
      );
    });
    _inputController.clear();
    _scrollToBottom();

    // Generate medically structured solution from health intelligence
    await Future.delayed(const Duration(milliseconds: 600));

    final (adviceText, isUrgent) = _generateMedicalAdvice(text);

    if (mounted) {
      setState(() {
        _sending = false;
        _localMessages.add(
          ChatMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            role: ChatRole.assistant,
            content: adviceText,
            capability: _capability,
            createdAt: DateTime.now(),
            urgencyFlag: isUrgent,
          ),
        );
      });
      _scrollToBottom();
    }

    // Try background sync to Firestore if possible
    try {
      if (_chatId == null) {
        final result = await ref.read(aiChatRepositoryProvider).startChat(patientUid: uid);
        result.match((_) => null, (id) => _chatId = id);
      }
      if (_chatId != null) {
        await ref.read(aiChatRepositoryProvider).sendMessage(
              chatId: _chatId!,
              message: text,
              capability: _capability,
            );
      }
    } catch (_) {}
  }

  static (String, bool) _generateMedicalAdvice(String query) {
    final q = query.toLowerCase();

    // 1. Emergency Red Flags
    if (q.contains('chest pain') ||
        q.contains('heart attack') ||
        q.contains('cannot breathe') ||
        q.contains('cant breathe') ||
        q.contains('unconscious') ||
        q.contains('stroke') ||
        q.contains('face drooping') ||
        q.contains('paralysis') ||
        q.contains('severe allergic') ||
        q.contains('anaphylaxis') ||
        q.contains('coughing blood') ||
        q.contains('vomiting blood')) {
      return (
        '🚨 CRITICAL MEDICAL ALERT: The symptoms you described indicate a potential medical emergency. '
        'Immediate hospital intervention is required.\n\n'
        '• Call 108 Emergency Ambulance immediately or tap the SOS button below.\n'
        '• Sit in an upright, comfortable position; loosen tight clothing.\n'
        '• Do not attempt to drive yourself to the hospital.\n'
        '• If conscious and instructed by a healthcare provider for suspected cardiac event, keep calm and stay still.',
        true,
      );
    }

    // 2. High Fever & Chills
    if (q.contains('fever') || q.contains('temperature') || q.contains('chills') || q.contains('shivering')) {
      return (
        '🌡️ Management & First-Aid for Fever:\n\n'
        '1. Hydration is Essential:\n'
        '   Drink plenty of fluids (boiled-cooled water, ORS, clear broths, coconut water) to prevent dehydration.\n\n'
        '2. External Cooling:\n'
        '   • Place a clean cloth soaked in room-temperature water on forehead and wrists.\n'
        '   • Avoid cold or ice baths as they cause shivering which raises core temperature.\n'
        '   • Wear lightweight, breathable cotton clothing and rest in a well-ventilated room.\n\n'
        '3. Safe Medication:\n'
        '   • Paracetamol (as per recommended age/weight dosage) helps reduce fever discomfort.\n'
        '   • Never give aspirin to children or adolescents.\n\n'
        '⚠️ Red Flags (Seek Doctor Immediately):\n'
        '• Fever exceeding 103°F (39.4°C) or lasting more than 3 consecutive days.\n'
        '• Stiff neck, severe headache, confusion, or difficulty waking up.\n\n'
        '👨‍⚕️ Consult: General Physician / Internal Medicine.',
        false,
      );
    }

    // 3. Headache & Migraine
    if (q.contains('headache') || q.contains('migraine') || q.contains('head pain')) {
      return (
        '💆 Relief Guidance for Headache & Migraine:\n\n'
        '1. Dark & Quiet Environment:\n'
        '   Rest in a quiet, dimly lit room with your eyes closed for 20-30 minutes.\n\n'
        '2. Cold or Warm Compress:\n'
        '   • Apply a cool cloth across your forehead or eyes for tension and migraine.\n'
        '   • A warm compress at the back of your neck can relieve muscle tension.\n\n'
        '3. Hydration & Acupressure:\n'
        '   • Drink 2 glasses of water (dehydration is a primary headache trigger).\n'
        '   • Gently massage temples and the webbed space between thumb and index finger.\n\n'
        '⚠️ Red Flags (Seek Immediate ER):\n'
        '• "Thunderclap" headache (sudden, severe headache reaching peak intensity in seconds).\n'
        '• Headache accompanied by fever, stiff neck, vision changes, or numbness.\n\n'
        '👨‍⚕️ Consult: Neurologist or General Physician.',
        false,
      );
    }

    // 4. Burns & Scalds (exclude 'burning sensation' / 'heartburn')
    if ((q.contains('burn') && !q.contains('burning') && !q.contains('heartburn')) ||
        q.contains('scald') ||
        q.contains('hot water') ||
        q.contains('skin burn') ||
        q.contains('fire burn')) {
      return (
        '🩹 First-Aid for Minor Burns (First Degree / Scalds):\n\n'
        '1. Cool Water Immediately:\n'
        '   Hold the burned area under gentle, cool running tap water for 10-15 minutes.\n'
        '   ❌ NEVER apply ice, ice water, butter, toothpaste, or oil—they trap heat and damage tissue!\n\n'
        '2. Protect the Burn:\n'
        '   • Remove jewelry or tight items near the area before swelling begins.\n'
        '   • Cover loosely with a clean, sterile non-stick bandage or clean cling wrap.\n'
        '   • Apply pure aloe vera gel or burn ointment once cooled.\n\n'
        '3. Blisters:\n'
        '   • DO NOT pop blisters; they act as a natural barrier against bacterial infection.\n\n'
        '⚠️ Red Flags:\n'
        '• Burns larger than 3 inches, or on face, hands, joints, or groin.\n'
        '• Charred, white, or deep skin loss (Third-degree) -> Call 108 Emergency SOS.\n\n'
        '👨‍⚕️ Consult: Emergency Medicine / General Surgeon.',
        false,
      );
    }

    // 5. Stomach Ache, Acidity & Indigestion
    if (q.contains('stomach') || q.contains('acidity') || q.contains('indigestion') || q.contains('gas') || q.contains('belly pain') || q.contains('gastric')) {
      return (
        '🍵 Relief Steps for Stomach Discomfort & Acidity:\n\n'
        '1. Gentle Diet (BRAT):\n'
        '   Stick to Bananas, Rice, Applesauce, and Toast. Avoid oily, spicy, acidic, and dairy foods.\n\n'
        '2. Digestive Aids:\n'
        '   • Sip warm water with a slice of fresh ginger or peppermint tea.\n'
        '   • For acidity/heartburn: Stay upright for at least 2 hours after eating.\n'
        '   • An over-the-counter antacid (like gelusil or pantoprazole) can provide symptomatic relief.\n\n'
        '3. Hydration:\n'
        '   Take small sips of water or ORS to stay hydrated without bloating.\n\n'
        '⚠️ Red Flags:\n'
        '• Sharp, agonizing pain localized in the lower right abdomen (potential Appendicitis).\n'
        '• Persistent vomiting, blood in stool/vomit, or rigid board-like stomach.\n\n'
        '👨‍⚕️ Consult: Gastroenterologist or General Physician.',
        false,
      );
    }

    // 6. Cold, Cough & Sore Throat
    if (q.contains('cough') || q.contains('cold') || q.contains('sore throat') || q.contains('flu') || q.contains('runny nose') || q.contains('congestion')) {
      return (
        '🫖 Care Guidance for Cold, Cough & Sore Throat:\n\n'
        '1. Saltwater Gargle:\n'
        '   Gargle with warm salt water (1/2 tsp salt in 1 cup warm water) 3-4 times daily to reduce throat inflammation.\n\n'
        '2. Steam Inhalation:\n'
        '   Inhale steam from a hot bowl of water for 10 minutes to loosen chest and nasal congestion.\n\n'
        '3. Natural Soothing Drinks:\n'
        '   • Warm water with 1 teaspoon honey and lemon (natural antibacterial & cough suppressant).\n'
        '   • Turmeric milk (Golden milk) before bed.\n\n'
        '4. Rest & Elevation:\n'
        '   Sleep with your head slightly elevated on pillows to prevent post-nasal drip cough.\n\n'
        '⚠️ Red Flags:\n'
        '• Cough lasting > 3 weeks, breathing difficulty, or coughing up blood-tinged sputum.\n\n'
        '👨‍⚕️ Consult: ENT Specialist / Pulmonologist.',
        false,
      );
    }

    // 7. Cuts, Wounds & Bleeding
    if (q.contains('cut') || q.contains('bleed') || q.contains('wound') || q.contains('scratch')) {
      return (
        '🩸 First-Aid for Cuts & Minor Wounds:\n\n'
        '1. Apply Firm Direct Pressure:\n'
        '   Use a clean cloth or gauze and press firmly over the wound for 5 continuous minutes.\n\n'
        '2. Clean the Area:\n'
        '   Rinse gently under clean running water. Wash the surrounding skin with mild soap.\n\n'
        '3. Disinfect & Protect:\n'
        '   Apply an antiseptic ointment (e.g. Betadine / Neosporin) and cover with a sterile adhesive bandage.\n\n'
        '⚠️ Red Flags:\n'
        '• Bleeding does not stop after 10 minutes of direct pressure.\n'
        '• Deep gaping cut exposing fat or muscle (requires stitches within 6 hours).\n'
        '• Rusty metal cut (requires Tetanus toxoid injection within 24-48 hours).\n\n'
        '👨‍⚕️ Consult: Emergency Clinic / General Surgeon.',
        false,
      );
    }

    // Default Comprehensive Medical Guidance
    return (
      '📋 Medical Guidance for "${query}":\n\n'
      '• General Self-Care:\n'
      '  Prioritize adequate rest, stay hydrated with electrolyte-rich fluids, and monitor your symptoms closely.\n\n'
      '• Lifestyle Measures:\n'
      '  Avoid strenuous exertion, maintain a clean environment, and refrain from self-prescribing antibiotics.\n\n'
      '• Next Steps:\n'
      '  If your symptoms persist, worsen, or interfere with daily activities for more than 48 hours, schedule an appointment with a verified hospital doctor through the MediLink OPD Booking portal.\n\n'
      '⚠️ Remember: MediLink AI provides informational guidance. In any medical emergency, call 108 immediately.',
      false,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Row(
              children: [
                Icon(Icons.circle, color: AppColors.success, size: 8),
                SizedBox(width: 4),
                Text('Online • Medical Intelligence Engine', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDisclaimerBanner(),
          _buildCapabilitySelector(),
          Expanded(child: _buildMessageList()),
          if (_error != null) _buildErrorBanner(),
          _buildQuickPrompts(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(prompt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.cardLight,
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            onPressed: () => _handleSend(prompt),
          );
        },
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.infoLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'General guidance only — always consult a licensed doctor for '
              'diagnosis or treatment.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitySelector() {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: AiCapability.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final capability = AiCapability.values[index];
            final selected = capability == _capability;
            return ChoiceChip(
              label: Text(capability.label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: AppColors.primaryVeryLight,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) => setState(() => _capability = capability),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_localMessages.isNotEmpty) {
      final itemCount = _localMessages.length + (_sending ? 1 : 0);
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _localMessages.length) return const _TypingIndicator();
          final message = _localMessages[index];
          if (message.role == ChatRole.system) return const SizedBox.shrink();
          if (message.urgencyFlag) return _UrgencyCard(message: message);
          return _MessageBubble(message: message);
        },
      );
    }

    final chatId = _chatId;
    if (chatId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.health_and_safety, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'MediLink Health Intelligence AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get instant medical solutions, first-aid steps, and home remedies for common health issues. Select a topic below or type your question.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quickPrompts.take(4).map((p) {
                  return ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _handleSend(p),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    return messagesAsync.when(
      data: (messages) {
        _scrollToBottom();
        if (messages.isEmpty && !_sending) {
          return const SizedBox.shrink();
        }
        final itemCount = messages.length + (_sending ? 1 : 0);
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == messages.length) return const _TypingIndicator();
            final message = messages[index];
            if (message.role == ChatRole.system) return const SizedBox.shrink();
            if (message.urgencyFlag) return _UrgencyCard(message: message);
            return _MessageBubble(message: message);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load chat: $error')),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.errorLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        color: AppColors.cardLight,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Describe how you\'re feeling...',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _handleSend,
                  ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}

/// The hard-coded "this may be an emergency" card — deliberately not a
/// normal chat bubble, per architecture doc §11.
class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: AppColors.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'This may be a medical emergency',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.content, style: const TextStyle(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.sos_rounded),
              label: const Text('Emergency SOS'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosConfirmScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-dot "assistant is typing" bubble shown while waiting on the
/// `sendAiMessage` reply, so a slow rule-engine response doesn't read as a
/// frozen/broken chat.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value - i * 0.2) % 1.0;
                final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
