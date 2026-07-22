import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/widgets/index.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

enum _BroadcastTarget { all, state, college }

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends ConsumerState<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _collegeSearchController = TextEditingController();
  _BroadcastTarget _target = _BroadcastTarget.all;
  String _selectedState = CollegeConstants.indianStates.first;
  String _collegeQuery = '';
  CollegeModel? _selectedCollege;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _collegeSearchController.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Title is required.');
      return;
    }
    if (_target == _BroadcastTarget.college && _selectedCollege == null) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Select a college.');
      return;
    }

    setState(() => _sending = true);
    try {
      final repo = ref.read(engagementRepositoryProvider);
      final int count;
      switch (_target) {
        case _BroadcastTarget.all:
          count = await repo.broadcastAdminAnnouncement(title: title, body: body);
        case _BroadcastTarget.state:
          count = await repo.broadcastAdminAnnouncementByState(
            state: _selectedState,
            title: title,
            body: body,
          );
        case _BroadcastTarget.college:
          count = await repo.broadcastAdminAnnouncementByCollege(
            collegeId: _selectedCollege!.id,
            title: title,
            body: body,
          );
      }
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Announcement sent to $count users.',
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);
    final userType = ref.watch(currentUserModelProvider).maybeWhen(data: (u) => u?.userType, orElse: () => null);
    final canBroadcast = AdminPermissions.canBroadcast(userType);
    final collegeSearchAsync = _target == _BroadcastTarget.college
        ? ref.watch(adminCollegeSearchProvider(
            AdminCollegeSearchParams(query: _collegeQuery.isEmpty ? null : _collegeQuery),
          ))
        : null;

    return AdminShellLayout(
      title: 'Broadcast Notifications',
      isAdminUser: isAdminUser,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!canBroadcast)
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline, color: Colors.orange),
                title: Text('Admin access required'),
                subtitle: Text('Only admins can send broadcast notifications.'),
              ),
            )
          else ...[
            Text(
              'Send push and in-app notifications to users.',
              style: GoogleFonts.poppins(color: AppTheme.gray600),
            ),
            const SizedBox(height: 20),
            SegmentedButton<_BroadcastTarget>(
              segments: const [
                ButtonSegment(value: _BroadcastTarget.all, label: Text('All users'), icon: Icon(Icons.public)),
                ButtonSegment(value: _BroadcastTarget.state, label: Text('By state'), icon: Icon(Icons.map_outlined)),
                ButtonSegment(value: _BroadcastTarget.college, label: Text('By college'), icon: Icon(Icons.school_outlined)),
              ],
              selected: {_target},
              onSelectionChanged: (s) => setState(() => _target = s.first),
            ),
            const SizedBox(height: 16),
            if (_target == _BroadcastTarget.state)
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                items: CollegeConstants.indianStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedState = v);
                },
              ),
            if (_target == _BroadcastTarget.college) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _collegeSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Search college',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (v) => setState(() => _collegeQuery = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => setState(() => _collegeQuery = _collegeSearchController.text.trim()),
                    child: const Text('Search'),
                  ),
                ],
              ),
              if (_selectedCollege != null)
                ListTile(
                  title: Text('Selected: ${_selectedCollege!.name}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedCollege = null),
                  ),
                ),
              if (collegeSearchAsync != null)
                collegeSearchAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Search failed: $e'),
                  data: (page) => Column(
                    children: page.colleges.take(8).map((c) {
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text('${c.city}, ${c.state}'),
                        selected: _selectedCollege?.id == c.id,
                        onTap: () => setState(() => _selectedCollege = c),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLength: 120,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _sending ? null : _broadcast,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.campaign_outlined),
              label: Text(_sending ? 'Sending…' : _sendLabel()),
            ),
          ],
        ],
      ),
    );
  }

  String _sendLabel() {
    switch (_target) {
      case _BroadcastTarget.all:
        return 'Send to all users';
      case _BroadcastTarget.state:
        return 'Send to $_selectedState';
      case _BroadcastTarget.college:
        return 'Send to college followers';
    }
  }
}
