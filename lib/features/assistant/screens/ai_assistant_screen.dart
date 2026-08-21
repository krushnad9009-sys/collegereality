import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/widgets/premium_components.dart';
import '../../compare/providers/compare_basket_provider.dart';
import '../models/ai_assistant_message.dart';
import '../models/ai_topic.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_comparison_table.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/ai_source_citations_panel.dart';
import '../widgets/ai_suggestion_section.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? anchorCollegeId;
  final String? anchorCollegeName;

  const AiAssistantScreen({
    this.initialQuery,
    this.anchorCollegeId,
    this.anchorCollegeName,
    super.key,
  });

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialQuerySent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.anchorCollegeId != null) {
        ref.read(aiAssistantProvider.notifier).setAnchorCollege(
              widget.anchorCollegeId,
            );
      }
      if (widget.initialQuery != null &&
          widget.initialQuery!.trim().isNotEmpty &&
          !_initialQuerySent) {
        _initialQuerySent = true;
        _controller.text = widget.initialQuery!.trim();
        ref.read(aiAssistantProvider.notifier).sendMessage(widget.initialQuery!);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final basket = ref.watch(compareBasketProvider);
    ref.listen(aiAssistantProvider, (_, _) => _scrollToBottom());

    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'AI College Assistant',
          style: AppTypography.title(
            'AI College Assistant',
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SegmentedButton<AiAssistantMode>(
              segments: const [
                ButtonSegment(
                  value: AiAssistantMode.chat,
                  label: Text('Chat', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.chat_outlined, size: 14),
                ),
                ButtonSegment(
                  value: AiAssistantMode.compare,
                  label: Text('Compare', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.compare_arrows, size: 14),
                ),
              ],
              selected: {state.mode},
              onSelectionChanged: (s) =>
                  ref.read(aiAssistantProvider.notifier).setMode(s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          if (basket.canCompare)
            TextButton.icon(
              onPressed: () => context.go(
                RouteNames.comparePath(ids: basket.collegeIds),
              ),
              icon: const Icon(Icons.compare, size: 18),
              label: Text(
                'Compare (${basket.collegeIds.length})',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (state.contextCollegeIds.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '${state.contextCollegeIds.length} in compare',
                    style: AppFonts.plusJakarta(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: () =>
                ref.read(aiAssistantProvider.notifier).clearConversation(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.anchorCollegeName != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    AppTheme.secondaryColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Asking about ${widget.anchorCollegeName}',
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(
                        message: state.messages[index],
                        onAddToCompare: (id) {
                          ref.read(aiAssistantProvider.notifier).addContextCollege(id);
                          ref.read(compareBasketProvider.notifier).add(id);
                        },
                      );
                    },
                  ),
          ),
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _ThinkingBubble(
                label: state.mode == AiAssistantMode.compare
                    ? 'Comparing colleges from verified data…'
                    : 'Searching verified database…',
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _InlineErrorBanner(
                message: state.error!,
                onRetry: state.isLoading
                    ? null
                    : () =>
                        ref.read(aiAssistantProvider.notifier).retryLastQuery(),
              ),
            ),
          _InputBar(
            controller: _controller,
            onSend: _send,
            enabled: !state.isLoading,
          ),
        ],
      ),
    );
  }
}

/// Shown when the conversation has no messages yet. Intentionally contains
/// no automatically generated or predefined "Try asking" suggestions --
/// only an intro card explaining what the assistant can do. The user
/// decides what to ask via the input bar below; nothing is pre-populated.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        FadeInSection(
          delayMs: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF312E81),
                        const Color(0xFF1E3A5F),
                        tokens.surfaceElevated,
                      ]
                    : [
                        AppTheme.primaryColor,
                        const Color(0xFF6366F1),
                        AppTheme.secondaryColor,
                      ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(
                    alpha: isDark ? 0.2 : 0.28,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'India\'s Smartest AI Assistant',
                        style: AppFonts.plusJakarta(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Get answers from verified profiles, reviews, student Q&A, '
                  'and community posts — no guesses, only College Reality data.',
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated "AI is thinking" bubble, styled like an assistant chat bubble
/// with three pulsing dots so the loading state reads as part of the
/// conversation rather than a generic spinner.
class _ThinkingBubble extends StatefulWidget {
  final String label;

  const _ThinkingBubble({required this.label});

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: tokens.borderSubtle.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 14,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (i) {
                      final phase = (_controller.value + (i * 0.2)) % 1.0;
                      final scale = 0.55 + 0.45 * (0.5 - (phase - 0.5).abs()) * 2;
                      return Opacity(
                        opacity: 0.4 + 0.6 * scale,
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * scale,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
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
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.label,
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight inline error banner for the chat flow — a compact,
/// non-modal equivalent of [AsyncErrorView] that fits between messages
/// and the composer instead of taking over the screen.
class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _InlineErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppFonts.plusJakarta(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiAssistantMessage message;
  final void Function(String collegeId) onAddToCompare;

  const _MessageBubble({
    required this.message,
    required this.onAddToCompare,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;
    final tokens = context.tokens;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryDark,
                        ],
                      )
                    : null,
                color: isUser ? null : tokens.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: tokens.borderSubtle.withValues(alpha: 0.8)),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: isUser ? Colors.white : tokens.textPrimary,
                ),
              ),
            ),
            if (!isUser && message.dataGrounded)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppTheme.accentColor.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.sources.isNotEmpty
                          ? '${message.sources.length} verified source${message.sources.length == 1 ? '' : 's'}'
                          : 'Verified college data',
                      style: AppFonts.plusJakarta(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isUser && message.sources.isNotEmpty)
              AiSourceCitationsPanel(sources: message.sources),
            if (message.comparison != null) ...[
              const SizedBox(height: 8),
              AiComparisonTable(comparison: message.comparison!),
            ],
            if (message.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...message.recommendations.map(
                (r) => AiRecommendationCard(
                  recommendation: r,
                  onAddToCompare: () => onAddToCompare(r.college.id),
                ),
              ),
            ],
            if (message.suggestions.isNotEmpty)
              AiSuggestionSection(
                suggestions: message.suggestions,
                onAddToCompare: onAddToCompare,
              ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          border: Border(
            top: BorderSide(color: tokens.borderSubtle.withValues(alpha: 0.7)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PremiumCard(
                radius: AppSpacing.radius2xl,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 3,
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: enabled ? (_) => onSend() : null,
                  decoration: InputDecoration(
                    hintText: 'Ask anything about colleges...',
                    hintStyle: AppTypography.searchHint(''),
                    filled: true,
                    fillColor: tokens.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: enabled ? colorScheme.primary : tokens.borderStrong,
              borderRadius: BorderRadius.circular(16),
              elevation: enabled ? 2 : 0,
              shadowColor: colorScheme.primary.withValues(alpha: 0.35),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.send_rounded,
                    color: enabled ? colorScheme.onPrimary : tokens.textTertiary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
