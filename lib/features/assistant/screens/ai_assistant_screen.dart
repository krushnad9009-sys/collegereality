import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/constants/ai_assistant_constants.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.gray900 : const Color(0xFFF3F5FA),
      appBar: AppBar(
        title: Text(
          'AI College Assistant',
          style: AppTypography.title('AI College Assistant'),
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
                style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
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
                ? _EmptyState(onExampleTap: (q) {
                    _controller.text = q;
                    _send();
                  })
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
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    state.mode == AiAssistantMode.compare
                        ? 'Comparing colleges from verified data...'
                        : 'Searching verified database...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(aiAssistantProvider.notifier)
                              .retryLastQuery(),
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

class _EmptyState extends StatelessWidget {
  final void Function(String query) onExampleTap;

  const _EmptyState({required this.onExampleTap});

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
                        AppTheme.gray800,
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
                        style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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
        const SizedBox(height: AppSpacing.section),
        FadeInSection(
          delayMs: 80,
          child: Text(
            'Try asking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...AiAssistantConstants.exampleQueries.asMap().entries.map(
              (entry) => FadeInSection(
                delayMs: 100 + (entry.key * 40),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PremiumChip(
                    label: entry.value,
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => onExampleTap(entry.value),
                  ),
                ),
              ),
            ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isUser
                    ? null
                    : (isDark ? AppTheme.gray800 : tokens.surfaceElevated),
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
                          color: AppTheme.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: isUser ? AppTheme.white : tokens.textPrimary,
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
                      style: GoogleFonts.plusJakartaSans(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray900 : const Color(0xFFF3F5FA),
          border: Border(
            top: BorderSide(color: tokens.borderSubtle.withValues(alpha: 0.7)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PremiumCard(
                radius: 28,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(
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
                      borderRadius: BorderRadius.circular(28),
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
              color: enabled ? AppTheme.primaryColor : AppTheme.gray300,
              borderRadius: BorderRadius.circular(16),
              elevation: enabled ? 2 : 0,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.35),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
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
