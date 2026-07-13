import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/ecosystem_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/ecosystem_provider.dart';

class OfficialCollegeDashboardScreen extends ConsumerStatefulWidget {
  const OfficialCollegeDashboardScreen({super.key});

  @override
  ConsumerState<OfficialCollegeDashboardScreen> createState() =>
      _OfficialCollegeDashboardScreenState();
}

class _OfficialCollegeDashboardScreenState
    extends ConsumerState<OfficialCollegeDashboardScreen> {
  String _section = EcosystemConstants.sectionNotice;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish(String collegeId, String collegeName, String userId) async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isPublishing = true);
    try {
      await ref.read(ecosystemServiceProvider).publishOfficialContent(
            authorId: userId,
            collegeId: collegeId,
            collegeName: collegeName,
            section: _section,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          );
      _titleController.clear();
      _bodyController.clear();
      ref.invalidate(collegeOfficialContentProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Published successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(collegeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official College Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (account) {
          if (account == null || !account.isVerified) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 48, color: AppTheme.gray400),
                    const SizedBox(height: 16),
                    Text(
                      'Verified official account required',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go(RouteNames.collegeSearch),
                      child: const Text('Find College to Claim'),
                    ),
                  ],
                ),
              ),
            );
          }

          final contentAsync = ref.watch(
            collegeOfficialContentProvider((
              collegeId: account.collegeId,
              section: _section,
            )),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.collegeName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              Text('Official Badge Active',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accentColor, fontSize: 12)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EcosystemConstants.officialSections.map((s) {
                  final selected = _section == s['id'];
                  return FilterChip(
                    label: Text(s['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() => _section = s['id']!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title — ${EcosystemConstants.sectionLabel(_section)}',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isPublishing
                    ? null
                    : () => _publish(
                          account.collegeId,
                          account.collegeName,
                          account.userId,
                        ),
                child: _isPublishing
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Publish'),
              ),
              const SizedBox(height: 24),
              Text('Published',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              contentAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No content in this section yet.');
                  }
                  return Column(
                    children: items
                        .map((item) => Card(
                              child: ListTile(
                                title: Text(item.title),
                                subtitle: Text(item.body,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class AlumniMentorshipScreen extends ConsumerStatefulWidget {
  const AlumniMentorshipScreen({super.key});

  @override
  ConsumerState<AlumniMentorshipScreen> createState() =>
      _AlumniMentorshipScreenState();
}

class _AlumniMentorshipScreenState extends ConsumerState<AlumniMentorshipScreen> {
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    if (user.verificationBadge != VerificationConstants.badgeVerifiedAlumni) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verified alumni only.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).createMentorshipOffer(
            user: user,
            topic: _topicController.text.trim(),
            description: _descController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentorship offer published.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumni Mentorship')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(labelText: 'Topic *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Offer Mentorship'),
            ),
          ],
        ),
      ),
    );
  }
}

class FacultyHubScreen extends ConsumerStatefulWidget {
  const FacultyHubScreen({super.key});

  @override
  ConsumerState<FacultyHubScreen> createState() => _FacultyHubScreenState();
}

class _FacultyHubScreenState extends ConsumerState<FacultyHubScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isWorkshop = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null || user.collegeId == null) return;
    if (user.verificationBadge != VerificationConstants.badgeVerifiedFaculty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verified faculty only.')),
      );
      return;
    }
    final service = ref.read(ecosystemServiceProvider);
    if (_isWorkshop) {
      await service.publishWorkshop(
        facultyId: user.uid,
        collegeId: user.collegeId!,
        title: _titleController.text.trim(),
        description: _bodyController.text.trim(),
      );
    } else {
      await service.publishResearch(
        facultyId: user.uid,
        collegeId: user.collegeId!,
        title: _titleController.text.trim(),
        abstract: _bodyController.text.trim(),
      );
    }
    _titleController.clear();
    _bodyController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Hub')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Workshop')),
                ButtonSegment(value: false, label: Text('Research')),
              ],
              selected: {_isWorkshop},
              onSelectionChanged: (s) => setState(() => _isWorkshop = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: _isWorkshop ? 'Description' : 'Abstract',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _publish, child: const Text('Publish')),
          ],
        ),
      ),
    );
  }
}
