import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import '../providers/question_provider.dart';
import 'ask_question_sheet.dart';
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
            FilledButton.icon(
              onPressed: () => showAskQuestionSheet(
                context: context,
                ref: ref,
                collegeId: collegeId,
                collegeName: widget.college.name,
              ),
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(
                'Ask a Question',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  const _EmptyState({required this.hasSearch});

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
                : 'Be the first to ask about this college',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
