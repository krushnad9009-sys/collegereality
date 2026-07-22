import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/ai_assistant_constants.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI College Assistant',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          if (state.contextCollegeIds.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '${state.contextCollegeIds.length} in compare',
                    style: GoogleFonts.poppins(fontSize: 11),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asking about ${widget.anchorCollegeName}',
                      style: GoogleFonts.poppins(fontSize: 12),
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
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.mode == AiAssistantMode.compare
                        ? 'Comparing colleges from verified data...'
                        : 'Searching verified database...',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.error!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.errorColor,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.secondaryColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'India\'s Smartest AI College Assistant',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get answers from verified profiles, reviews, student Q&A, '
                'and community posts — no guesses, only College Reality data.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Try asking',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...AiAssistantConstants.exampleQueries.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(q, style: GoogleFonts.poppins(fontSize: 12)),
              onPressed: () => onExampleTap(q),
              avatar: const Icon(Icons.auto_awesome, size: 16),
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryColor
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.gray800
                        : AppTheme.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isUser ? AppTheme.white : null,
                ),
              ),
            ),
            if (!isUser && message.dataGrounded)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  message.sources.isNotEmpty
                      ? '✓ ${message.sources.length} verified source${message.sources.length == 1 ? '' : 's'}'
                      : '✓ Verified college data',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.accentColor,
                  ),
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray700
                  : AppTheme.gray200,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: 'Ask anything about colleges...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.gray800
                      : AppTheme.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: enabled ? onSend : null,
              child: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
