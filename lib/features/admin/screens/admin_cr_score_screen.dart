import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../../ranking/services/cr_score_service.dart';
import '../utils/admin_permissions.dart';

class AdminCrScoreScreen extends ConsumerStatefulWidget {
  const AdminCrScoreScreen({super.key});

  @override
  ConsumerState<AdminCrScoreScreen> createState() => _AdminCrScoreScreenState();
}

class _AdminCrScoreScreenState extends ConsumerState<AdminCrScoreScreen> {
  bool _running = false;
  int _processed = 0;
  int _total = 0;
  String? _resultMessage;

  Future<void> _recalculateAll() async {
    setState(() {
      _running = true;
      _processed = 0;
      _total = 0;
      _resultMessage = null;
    });

    try {
      final result = await ref.read(crScoreServiceProvider).recalculateAllColleges(
            onProgress: (processed, total) {
              if (mounted) {
                setState(() {
                  _processed = processed;
                  _total = total;
                });
              }
            },
          );
      if (mounted) {
        setState(() {
          _resultMessage =
              'Recalculated ${result.collegesProcessed} colleges using ${result.eligibleReviewsProcessed} verified reviews.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Recalculation failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = ref.watch(currentUserModelProvider).maybeWhen(
          data: (u) => u?.userType,
          orElse: () => null,
        );
    final canManage = AdminPermissions.canManageColleges(userType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CR Score Engine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'College Reality Score',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Recalculate CR Score from verified review aggregates. '
            'Rejected, fake, spam, and hidden reviews are excluded automatically.',
            style: GoogleFonts.poppins(color: AppTheme.gray600, height: 1.45),
          ),
          const SizedBox(height: 24),
          if (_running) ...[
            LinearProgressIndicator(
              value: _total > 0 ? _processed / _total : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Processing $_processed of $_total colleges...',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 24),
          ],
          if (_resultMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_resultMessage!, style: GoogleFonts.poppins()),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: !canManage || _running ? null : _recalculateAll,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Recalculate All CR Scores'),
          ),
        ],
      ),
    );
  }
}
