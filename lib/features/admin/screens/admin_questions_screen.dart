import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/admin_route_resolver.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/widgets/index.dart';
import '../../questions/models/question_model.dart';
import '../../questions/providers/question_provider.dart';

class AdminQuestionsScreen extends ConsumerStatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  ConsumerState<AdminQuestionsScreen> createState() =>
      _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends ConsumerState<AdminQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _hideQuestion(QuestionModel question) async {
    try {
      await ref.read(questionRepositoryProvider).updateQuestionStatus(
            question.id,
            QuestionConstants.statusHidden,
          );
      ref.invalidate(allQuestionsAdminProvider(_statusFilter));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Question hidden');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _deleteQuestion(QuestionModel question) async {
    try {
      await ref.read(questionRepositoryProvider).deleteQuestion(question.id);
      ref.invalidate(allQuestionsAdminProvider(_statusFilter));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Question deleted');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _resolveQuestionReport(String reportId, {bool remove = false}) async {
    try {
      final reports = await ref.read(openQuestionReportsAdminProvider.future);
      final report = reports.firstWhere((r) => r['id'] == reportId);
      if (remove) {
        await ref.read(questionRepositoryProvider).deleteQuestion(
              report['questionId'] as String,
            );
      }
      await ref.read(questionRepositoryProvider).updateQuestionReportStatus(
            reportId,
            QuestionConstants.reportStatusActionTaken,
          );
      ref.invalidate(openQuestionReportsAdminProvider);
      ref.invalidate(allQuestionsAdminProvider(_statusFilter));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Report resolved');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _resolveAnswerReport(String reportId, {bool remove = false}) async {
    try {
      final reports = await ref.read(openAnswerReportsAdminProvider.future);
      final report = reports.firstWhere((r) => r['id'] == reportId);
      if (remove) {
        await ref.read(questionRepositoryProvider).deleteAnswer(
              report['questionId'] as String,
              report['answerId'] as String,
            );
      }
      await ref.read(questionRepositoryProvider).updateAnswerReportStatus(
            reportId,
            QuestionConstants.reportStatusActionTaken,
          );
      ref.invalidate(openAnswerReportsAdminProvider);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Report resolved');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(allQuestionsAdminProvider(_statusFilter));
    final questionReportsAsync = ref.watch(openQuestionReportsAdminProvider);
    final answerReportsAsync = ref.watch(openAnswerReportsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A Moderation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AdminRouteResolver.home(context)),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Questions'),
            Tab(text: 'Question Reports'),
            Tab(text: 'Answer Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                    _FilterChip(
                      label: 'Published',
                      selected:
                          _statusFilter == QuestionConstants.statusPublished,
                      onTap: () => setState(
                        () => _statusFilter = QuestionConstants.statusPublished,
                      ),
                    ),
                    _FilterChip(
                      label: 'Hidden',
                      selected: _statusFilter == QuestionConstants.statusHidden,
                      onTap: () => setState(
                        () => _statusFilter = QuestionConstants.statusHidden,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: questionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (questions) {
                    if (questions.isEmpty) {
                      final tokens = context.tokens;
                      return Center(
                        child: Text(
                          'No questions found',
                          style: AppFonts.plusJakarta(color: tokens.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return PremiumCard(
                          padding: EdgeInsets.zero,
                          child: PremiumListRow(
                            leadingIcon: Icons.quiz_outlined,
                            title: question.title,
                            subtitle:
                                '${question.collegeName} · ${question.answerCount} answers · ${question.status}',
                            showChevron: false,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'hide') {
                                  _hideQuestion(question);
                                } else if (value == 'delete') {
                                  _deleteQuestion(question);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'hide',
                                  child: Text('Hide'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          _ReportsList(
            reportsAsync: questionReportsAsync,
            onDismiss: (id) => ref
                .read(questionRepositoryProvider)
                .updateQuestionReportStatus(
                  id,
                  QuestionConstants.reportStatusReviewed,
                )
                .then((_) => ref.invalidate(openQuestionReportsAdminProvider)),
            onRemove: (id) => _resolveQuestionReport(id, remove: true),
            onResolve: (id) => _resolveQuestionReport(id),
          ),
          _ReportsList(
            reportsAsync: answerReportsAsync,
            onDismiss: (id) => ref
                .read(questionRepositoryProvider)
                .updateAnswerReportStatus(
                  id,
                  QuestionConstants.reportStatusReviewed,
                )
                .then((_) => ref.invalidate(openAnswerReportsAdminProvider)),
            onRemove: (id) => _resolveAnswerReport(id, remove: true),
            onResolve: (id) => _resolveAnswerReport(id),
          ),
        ],
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> reportsAsync;
  final Future<void> Function(String id) onDismiss;
  final Future<void> Function(String id) onRemove;
  final Future<void> Function(String id) onResolve;

  const _ReportsList({
    required this.reportsAsync,
    required this.onDismiss,
    required this.onRemove,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Text('No open reports'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['reason'] as String? ?? 'No reason provided',
                      style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reporter: ${report['reporterId']} · ${report['createdAt']}',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: context.tokens.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => onDismiss(report['id'] as String),
                          child: const Text('Dismiss'),
                        ),
                        OutlinedButton(
                          onPressed: () => onResolve(report['id'] as String),
                          child: const Text('Resolve'),
                        ),
                        FilledButton(
                          onPressed: () => onRemove(report['id'] as String),
                          child: const Text('Remove Content'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
