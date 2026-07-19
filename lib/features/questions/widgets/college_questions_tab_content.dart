import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import '../providers/question_provider.dart';
import 'ask_question_sheet.dart';
import 'ask_student_button.dart';
import 'question_card_widget.dart';

class CollegeQuestionsTabContent extends ConsumerStatefulWidget {
  final CollegeModel college;

  const CollegeQuestionsTabContent({required this.college, super.key});

  @override
  ConsumerState<CollegeQuestionsTabContent> createState() =>
      _CollegeQuestionsTabContentState();
}

class _CollegeQuestionsTabContentState
    extends ConsumerState<CollegeQuestionsTabContent> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collegeId = widget.college.id;
    final questionsAsync = ref.watch(displayedCollegeQuestionsProvider(collegeId));
    final filterState = ref.watch(questionListFilterProvider(collegeId));
    final isWide = MediaQuery.of(context).size.width >= 600;

    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading questions: $e')),
      data: (questions) {
        return ListView(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask a Student',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get honest answers from verified students and alumni of ${widget.college.name}.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.gray600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AskStudentButton(
                    collegeId: collegeId,
                    collegeName: widget.college.name,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            QuestionFilterBar(
              searchController: _searchController,
              selectedFilter: filterState.filter,
              onFilterChanged: (filter) {
                ref
                    .read(questionListFilterProvider(collegeId).notifier)
                    .setFilter(filter);
              },
              onSearchChanged: (query) {
                ref
                    .read(questionListFilterProvider(collegeId).notifier)
                    .setSearchQuery(query);
              },
            ),
            const SizedBox(height: 16),
            if (questions.isEmpty)
              _EmptyState(
                hasSearch: filterState.searchQuery.isNotEmpty ||
                    filterState.filter != 'latest',
                onAsk: () => showAskQuestionSheet(
                  context: context,
                  ref: ref,
                  collegeId: collegeId,
                  collegeName: widget.college.name,
                ),
              )
            else
              ...questions.map(
                (question) => QuestionCardWidget(
                  question: question,
                  onTap: () => context.push(
                    RouteNames.collegeQuestionPath(collegeId, question.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAsk;

  const _EmptyState({
    required this.hasSearch,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 56, color: AppTheme.gray300),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No matching questions' : 'No questions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search or filter'
                : 'Be the first to ask a verified student',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAsk,
              icon: const Icon(Icons.question_answer_outlined),
              label: const Text('Ask a Student'),
            ),
          ],
        ],
      ),
    );
  }
}
