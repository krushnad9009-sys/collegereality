import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';
import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../core/widgets/index.dart';
import '../auth/models/user_model.dart';
import '../auth/providers/user_provider.dart';
import '../colleges/widgets/college_autocomplete_field.dart';
import '../reviews/widgets/star_rating_widget.dart';
import '../verification/models/verification_request_model.dart';
import '../verification/providers/verification_provider.dart';
import '../verification/services/verification_firestore_service.dart';
import '../verification/widgets/guide_documents_picker.dart';
import 'guide_onboarding_provider.dart';
import 'guide_onboarding_rules.dart';

/// "Become a guide": a 3-step wizard, one step at a time --
///   1. college + 4 mandatory star ratings,
///   2. a detailed written review (unlocks after 1),
///   3. document verification upload (unlocks after 2).
/// Nothing is written until the final submit; guide mode can't be switched
/// on without it (firestore.rules guideModeRequiresCollegeReview).
class GuideOnboardingScreen extends ConsumerStatefulWidget {
  const GuideOnboardingScreen({super.key});

  @override
  ConsumerState<GuideOnboardingScreen> createState() =>
      _GuideOnboardingScreenState();
}

class _GuideOnboardingScreenState extends ConsumerState<GuideOnboardingScreen> {
  int _step = 0;
  String? _collegeId;
  String? _collegeName;
  final Map<String, double> _ratings = {};
  final _reviewController = TextEditingController();
  List<GuideVerificationDoc> _docs = const [];
  bool _submitting = false;
  bool? _completedNow; // null = not submitted yet
  bool _hydrated = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _hydrate(UserModel user) {
    if (_hydrated) return;
    _hydrated = true;
    _collegeId = user.collegeId;
    _collegeName = user.collegeName;
  }

  bool get _step1Done => GuideOnboardingRules.step1Complete(
        collegeId: _collegeId,
        collegeName: _collegeName,
        ratings: _ratings,
      );

  bool get _step2Done =>
      GuideOnboardingRules.step2Complete(_reviewController.text);

  Future<void> _submit(UserModel user, DocumentStepState docState) async {
    setState(() => _submitting = true);
    try {
      final completed = await ref.read(guideOnboardingServiceProvider).submit(
            user: user,
            collegeId: _collegeId!,
            collegeName: _collegeName!,
            ratings: _ratings,
            reviewText: _reviewController.text,
            documentState: docState,
            documents: _docs,
          );
      ref.invalidate(currentUserDetailProvider);
      ref.invalidate(userVerificationRequestProvider(user.uid));
      ref.invalidate(activeVerificationRequestProvider(user.uid));
      if (mounted) setState(() => _completedNow = completed);
    } on VerificationException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } catch (e) {
      debugPrint('[GuideOnboarding] submit failed: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not submit. Please try again — your answers are kept.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _hydrate(user);
    final activeRequest =
        ref.watch(activeVerificationRequestProvider(user.uid)).valueOrNull;
    final docState =
        GuideOnboardingRules.documentStepState(user, activeRequest);

    return Scaffold(
      appBar: AppBar(title: const Text('Become a Guide')),
      body: _completedNow != null
          ? _SubmittedView(completed: _completedNow!)
          : Stepper(
              currentStep: _step,
              // Only steps already reached can be revisited; later steps
              // stay locked until the current one is valid.
              onStepTapped: (i) {
                if (i <= _step) setState(() => _step = i);
              },
              controlsBuilder: (context, details) =>
                  const SizedBox.shrink(),
              steps: [
                Step(
                  title: const Text('Your college & ratings'),
                  subtitle: const Text('Rate 4 categories'),
                  isActive: _step >= 0,
                  state: _step > 0 ? StepState.complete : StepState.indexed,
                  content: _StepBody(
                    children: [
                      CollegeAutocompleteField(
                        selectedCollegeId: _collegeId,
                        selectedCollegeName: _collegeName,
                        onChanged: (c) => setState(() {
                          _collegeId = c?.id;
                          _collegeName = c?.name;
                        }),
                      ),
                      const SizedBox(height: 12),
                      for (final c in GuideOnboardingRules.ratingCategories)
                        RatingInputRow(
                          label: c.label,
                          value: _ratings[c.key] ?? 0,
                          onChanged: (v) =>
                              setState(() => _ratings[c.key] = v),
                        ),
                      _NextButton(
                        label: 'Continue',
                        enabled: _step1Done,
                        hint: 'Select your college and rate all 4 categories.',
                        onPressed: () => setState(() => _step = 1),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Write your review'),
                  subtitle: Text(
                    'At least ${GuideOnboardingRules.minReviewChars} characters',
                  ),
                  isActive: _step >= 1,
                  state: _step > 1
                      ? StepState.complete
                      : (_step1Done ? StepState.indexed : StepState.disabled),
                  content: _StepBody(
                    children: [
                      TextField(
                        controller: _reviewController,
                        maxLines: 7,
                        maxLength: GuideOnboardingRules.maxReviewChars,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText:
                              'What is studying here really like? Academics, '
                              'faculty, campus life, placements, what you '
                              'wish you had known…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Text(
                        '${_reviewController.text.trim().length}/'
                        '${GuideOnboardingRules.minReviewChars} minimum',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: _step2Done
                              ? Colors.green.shade700
                              : context.tokens.textTertiary,
                        ),
                      ),
                      _NextButton(
                        label: 'Continue',
                        enabled: _step2Done,
                        hint:
                            'Write at least ${GuideOnboardingRules.minReviewChars} characters.',
                        onPressed: () => setState(() => _step = 2),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Verify you study there'),
                  subtitle: const Text('Student ID, fee receipt or marksheet'),
                  isActive: _step >= 2,
                  state: _step2Done && _step1Done
                      ? StepState.indexed
                      : StepState.disabled,
                  content: _StepBody(
                    children: [
                      _DocumentStep(
                        state: docState,
                        activeRequest: activeRequest,
                        enabled: !_submitting,
                        onDocsChanged: (docs) => setState(() => _docs = docs),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Submit',
                        isLoading: _submitting,
                        onPressed: GuideOnboardingRules.step3Complete(
                                    docState, _docs.length) &&
                                _step1Done &&
                                _step2Done
                            ? () => _submit(user, docState)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final List<Widget> children;
  const _StepBody({required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
}

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final String hint;
  final VoidCallback onPressed;

  const _NextButton({
    required this.label,
    required this.enabled,
    required this.hint,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  hint,
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    color: context.tokens.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _DocumentStep extends StatelessWidget {
  final DocumentStepState state;
  final VerificationRequestModel? activeRequest;
  final bool enabled;
  final ValueChanged<List<GuideVerificationDoc>> onDocsChanged;

  const _DocumentStep({
    required this.state,
    required this.activeRequest,
    required this.enabled,
    required this.onDocsChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DocumentStepState.alreadyVerified:
        return const _Info(
          icon: Icons.verified_rounded,
          text: "You're already verified — your review will be published "
              'and guide mode switched on as soon as you submit.',
        );
      case DocumentStepState.underReview:
        return const _Info(
          icon: Icons.hourglass_top_rounded,
          text: 'Your documents are already being reviewed. Submit your '
              'review now — it goes live once they are approved.',
        );
      case DocumentStepState.needsUpload:
        return GuideDocumentsPicker(enabled: enabled, onChanged: onDocsChanged);
    }
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      );
}

class _SubmittedView extends StatelessWidget {
  final bool completed;
  const _SubmittedView({required this.completed});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            completed ? Icons.celebration_rounded : Icons.hourglass_top_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            completed ? "You're a guide now!" : 'Submitted for verification',
            style: AppFonts.plusJakarta(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed
                ? 'Your review is live and students can now find and call you.'
                : 'Your review is saved as pending verification. Once your '
                    'documents are approved it will be published and guide '
                    'mode switched on automatically.',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(RouteNames.profile),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
