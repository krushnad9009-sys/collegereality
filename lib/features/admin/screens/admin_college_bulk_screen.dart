import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';
import '../services/admin_college_bulk_service.dart';

class AdminCollegeBulkScreen extends ConsumerStatefulWidget {
  const AdminCollegeBulkScreen({super.key});

  @override
  ConsumerState<AdminCollegeBulkScreen> createState() => _AdminCollegeBulkScreenState();
}

class _AdminCollegeBulkScreenState extends ConsumerState<AdminCollegeBulkScreen> {
  final _csvController = TextEditingController();
  final _photosController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _bulkService = AdminCollegeBulkService();
  bool _isImporting = false;

  @override
  void dispose() {
    _csvController.dispose();
    _photosController.dispose();
    _collegeIdController.dispose();
    super.dispose();
  }

  Future<void> _importCsv() async {
    setState(() => _isImporting = true);
    try {
      final rows = _bulkService.parseCsv(_csvController.text);
      final count = await ref.read(adminAnalyticsServiceProvider).importCollegesFromCsvRows(rows);
      ref.invalidate(adminDashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count colleges')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _uploadPhotos() async {
    final collegeId = _collegeIdController.text.trim();
    if (collegeId.isEmpty) return;
    final urls = _bulkService.parseImageUrls(_photosController.text);
    await ref.read(adminUserModerationServiceProvider).attachCollegePhotos(collegeId, urls);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attached ${urls.length} photos')),
      );
    }
  }

  Future<void> _approveCollege(bool approved) async {
    final collegeId = _collegeIdController.text.trim();
    if (collegeId.isEmpty) return;
    await ref.read(adminUserModerationServiceProvider).setCollegeApproval(
          collegeId,
          approved: approved,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'College approved' : 'College marked pending')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Bulk Operations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'CSV Import',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Headers: name,city,state,type,courses (semicolon-separated)',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _csvController,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'name,city,state,type\nABC College,Mumbai,Maharashtra,private',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isImporting ? null : _importCsv,
            icon: _isImporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: const Text('Import CSV'),
          ),
          const SizedBox(height: 32),
          Text(
            'Bulk Image Upload & Approval',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _collegeIdController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'College ID',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _photosController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'One photo URL per line',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadPhotos,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Upload Photos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approveCollege(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _approveCollege(false),
            icon: const Icon(Icons.pending_outlined),
            label: const Text('Mark Pending Review'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.adminColleges),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Open College Management'),
          ),
        ],
      ),
    );
  }
}
