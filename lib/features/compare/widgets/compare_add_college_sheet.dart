import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/compare_constants.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/compare_basket_provider.dart';

Future<void> showCompareAddCollegeSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _CompareAddCollegeSheet(),
  );
}

class _CompareAddCollegeSheet extends ConsumerStatefulWidget {
  const _CompareAddCollegeSheet();

  @override
  ConsumerState<_CompareAddCollegeSheet> createState() =>
      _CompareAddCollegeSheetState();
}

class _CompareAddCollegeSheetState
    extends ConsumerState<_CompareAddCollegeSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(compareBasketProvider);
    final collegesAsync = ref.watch(collegeInstantSuggestProvider(_query));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add College',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${basket.collegeIds.length}/${CompareConstants.maxColleges} selected',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search colleges instantly...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: collegesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Search failed: $e')),
              data: (colleges) {
                if (_query.isEmpty) {
                  return Center(
                    child: Text(
                      'Start typing to search colleges',
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                  );
                }
                if (colleges.isEmpty) {
                  return Center(
                    child: Text(
                      'No colleges found',
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: colleges.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final college = colleges[index];
                    final selected = basket.contains(college.id);
                    return ListTile(
                      title: Text(
                        college.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${college.city}, ${college.state}'),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppTheme.accentColor)
                          : const Icon(Icons.add_circle_outline),
                      onTap: () {
                        final message = ref
                            .read(compareBasketProvider.notifier)
                            .toggle(college.id);
                        if (message != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
