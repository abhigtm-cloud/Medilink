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

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });
    _inputController.clear();

    try {
      final String chatId;
      if (_chatId == null) {
        final result = await ref.read(aiChatRepositoryProvider).startChat(patientUid: uid);
        chatId = result.match((f) => throw f, (id) => id);
        if (!mounted) return;
        setState(() => _chatId = chatId);
      } else {
        chatId = _chatId!;
      }

      final result = await ref.read(aiChatRepositoryProvider).sendMessage(
            chatId: chatId,
            message: text,
            capability: _capability,
          );
      result.match(
        (f) => setState(() => _error = f.message),
        (_) => null,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to send. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          _buildDisclaimerBanner(),
          _buildCapabilitySelector(),
          Expanded(child: _buildMessageList()),
          if (_error != null) _buildErrorBanner(),
          _buildInputBar(),
        ],
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
    final chatId = _chatId;
    if (chatId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy_outlined, size: 56, color: AppColors.textTertiaryLight),
              const SizedBox(height: 16),
              Text(
                'Ask about symptoms, get general health tips, or find the '
                'right specialist to see.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight),
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
        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
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
