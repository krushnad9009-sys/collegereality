import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

class AdminMergeCollegesScreen extends ConsumerStatefulWidget {
  const AdminMergeCollegesScreen({super.key});

  @override
  ConsumerState<AdminMergeCollegesScreen> createState() =>
      _AdminMergeCollegesScreenState();
}

class _AdminMergeCollegesScreenState extends ConsumerState<AdminMergeCollegesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  CollegeModel? _source;
  CollegeModel? _target;
  bool _merging = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _merge() async {
    if (_source == null || _target == null) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Select source and target colleges.');
      return;
    }
    if (_source!.id == _target!.id) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Source and target must differ.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm merge'),
        content: Text(
          'Merge "${_source!.name}" into "${_target!.name}"?\n\n'
          'Reviews and questions will move to the target. The source college will be deactivated.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Merge')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _merging = true);
    try {
      await ref.read(adminAnalyticsServiceProvider).mergeColleges(
            sourceCollegeId: _source!.id,
            targetCollegeId: _target!.id,
          );
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Colleges merged successfully.');
        setState(() {
          _source = null;
          _target = null;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Merge failed: $e');
      }
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);
    final userType = ref.watch(currentUserModelProvider).maybeWhen(data: (u) => u?.userType, orElse: () => null);
    final canMerge = AdminPermissions.canMergeColleges(userType);
    final searchAsync = ref.watch(adminCollegeSearchProvider(
      AdminCollegeSearchParams(query: _query.isEmpty ? null : _query),
    ));

    return AdminShellLayout(
      title: 'Merge Colleges',
      isAdminUser: isAdminUser,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!canMerge)
            Card(
              color: Colors.orange.shade50,
              child: const ListTile(
                leading: Icon(Icons.lock_outline, color: Colors.orange),
                title: Text('Super admin access required'),
                subtitle: Text('Only super admins can merge duplicate colleges.'),
              ),
            )
          else ...[
            Text(
              'Merge duplicate colleges',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a duplicate (source) and the canonical college (target). '
              'Reviews and Q&A move to the target; the source is deactivated.',
              style: GoogleFonts.poppins(color: AppTheme.gray600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Search colleges by name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(() => _query = _searchController.text.trim()),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_source != null || _target != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Source (duplicate): ${_source?.name ?? '—'}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text('Target (keep): ${_target?.name ?? '—'}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _merging || _source == null || _target == null ? null : _merge,
                        icon: _merging
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.merge_type),
                        label: Text(_merging ? 'Merging…' : 'Merge colleges'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            searchAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Search failed: $e'),
              data: (page) {
                if (page.colleges.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No colleges found')),
                  );
                }
                return Column(
                  children: page.colleges.map((college) {
                    final isSource = _source?.id == college.id;
                    final isTarget = _target?.id == college.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(college.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text('${college.city}, ${college.state}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            FilterChip(
                              label: const Text('Source'),
                              selected: isSource,
                              onSelected: (_) => setState(() => _source = college),
                            ),
                            FilterChip(
                              label: const Text('Target'),
                              selected: isTarget,
                              onSelected: (_) => setState(() => _target = college),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
