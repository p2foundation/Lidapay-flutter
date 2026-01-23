import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your Lidapay AI assistant. I can help you with:\n\n"
            "• Buying airtime & data bundles\n"
            "• Checking your transaction history\n"
            "• Understanding your spending\n"
            "• Answering questions about services\n\n"
            "How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: _generateResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  String _generateResponse(String input) {
    final lowercaseInput = input.toLowerCase();
    
    if (lowercaseInput.contains('airtime') || lowercaseInput.contains('recharge')) {
      return "I can help you buy airtime! To get started:\n\n"
          "1. Tap 'Buy Airtime' below, or\n"
          "2. Go to Services → Airtime\n\n"
          "You can top up your own number or send to friends and family across 150+ countries.";
    }
    
    if (lowercaseInput.contains('data') || lowercaseInput.contains('internet') || lowercaseInput.contains('bundle')) {
      return "Looking to buy data bundles? Here's how:\n\n"
          "1. Tap 'Buy Data' below, or\n"
          "2. Go to Services → Internet Data\n\n"
          "We support data bundles for all major networks. Just enter the phone number and select your preferred bundle.";
    }
    
    if (lowercaseInput.contains('balance') || lowercaseInput.contains('wallet')) {
      return "To check your wallet balance:\n\n"
          "• Your balance is shown on the Dashboard\n"
          "• Go to Settings → Wallet for details\n\n"
          "Need to add funds? You can top up via mobile money or card.";
    }
    
    if (lowercaseInput.contains('transaction') || lowercaseInput.contains('history')) {
      return "To view your transaction history:\n\n"
          "1. Tap 'History' in the bottom navigation, or\n"
          "2. Go to Dashboard and scroll to 'Recent Transactions'\n\n"
          "You can filter by date, type, or status.";
    }
    
    if (lowercaseInput.contains('help') || lowercaseInput.contains('support')) {
      return "I'm here to help! Here are some things I can assist with:\n\n"
          "• Buying airtime & data\n"
          "• Checking transactions\n"
          "• Understanding fees\n"
          "• Account settings\n\n"
          "For urgent issues, visit Settings → Help Center.";
    }
    
    if (lowercaseInput.contains('fee') || lowercaseInput.contains('charge') || lowercaseInput.contains('cost')) {
      return "Lidapay offers transparent pricing:\n\n"
          "• No hidden fees on transactions\n"
          "• Competitive exchange rates\n"
          "• What you see is what you pay\n\n"
          "The exact fee is shown before you confirm any transaction.";
    }
    
    if (lowercaseInput.contains('hello') || lowercaseInput.contains('hi') || lowercaseInput.contains('hey')) {
      return "Hello! Great to hear from you. What can I help you with today?\n\n"
          "Feel free to ask about airtime, data bundles, transactions, or anything else!";
    }
    
    if (lowercaseInput.contains('thank')) {
      return "You're welcome! Is there anything else I can help you with?\n\n"
          "I'm always here to assist with your Lidapay needs.";
    }

    return "I understand you're asking about \"$input\". While I'm still learning, here's what I can help with:\n\n"
        "• Airtime & Data purchases\n"
        "• Transaction history\n"
        "• Wallet & balance inquiries\n"
        "• General support\n\n"
        "Could you rephrase your question, or try one of the quick actions below?";
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: _buildChatArea(context, isDark),
            ),
            _buildQuickActions(context, isDark),
            _buildInputArea(context, isDark),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            size: 40,
            iconSize: 20,
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBg,
            iconColor: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lidapay AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Clear chat
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: "Chat cleared. How can I help you?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildChatArea(BuildContext context, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator(isDark);
        }
        return _buildMessageBubble(_messages[index], isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : AppColors.lightBg),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.xs),
                  bottomRight: Radius.circular(isUser ? AppRadius.xs : AppRadius.lg),
                ),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      height: 1.4,
                    ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.xs),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Text(
                'U',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .fadeIn(delay: Duration(milliseconds: index * 200))
          .then()
          .fadeOut(delay: const Duration(milliseconds: 400)),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      _QuickAction(
        icon: Icons.phone_android_rounded,
        label: 'Buy Airtime',
        onTap: () => context.push('/airtime/select-country'),
      ),
      _QuickAction(
        icon: Icons.wifi_rounded,
        label: 'Buy Data',
        onTap: () => context.push('/data/select-country'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'History',
        onTap: () => context.push('/transactions'),
      ),
      _QuickAction(
        icon: Icons.help_outline_rounded,
        label: 'Help',
        onTap: () => context.push('/help-center'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: action.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action.icon,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        action.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
