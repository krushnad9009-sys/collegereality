import 'dart:convert';
// Web-only by design: this screen lives under lib/admin/ (the dedicated
// Super Admin Web panel, lib/admin/main_admin.dart), never the shared
// lib/features/admin/ tree the main mobile/web consumer app's own
// /admin/* routes also render -- so dart:html here is safe. Putting a
// browser file-download screen in the shared tree instead would break
// compilation for the mobile app, which has no such API.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../config/theme/app_spacing.dart';
import '../../core/constants/college_constants.dart';
import '../../core/widgets/premium_components.dart';
import '../../features/admin/models/admin_models.dart';
import '../../features/admin/providers/admin_dashboard_provider.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';

class SuperAdminLeadAnalyticsScreen extends ConsumerStatefulWidget {
  const SuperAdminLeadAnalyticsScreen({super.key});

  @override
  ConsumerState<SuperAdminLeadAnalyticsScreen> createState() =>
      _SuperAdminLeadAnalyticsScreenState();
}

class _SuperAdminLeadAnalyticsScreenState
    extends ConsumerState<SuperAdminLeadAnalyticsScreen> {
  List<LeadSummary> _leads = [];
  bool _loading = false;
  String? _error;

  String _state = '';
  String _city = '';
  String _faculty = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leads = await ref.read(adminWeeklyLeadsProvider.future);
      if (!mounted) return;
      setState(() => _leads = leads);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<LeadSummary> get _filtered {
    return _leads.where((l) {
      if (_state.isNotEmpty && l.state != _state) return false;
      if (_city.isNotEmpty && l.city != _city) return false;
      if (_faculty.isNotEmpty && l.topFaculty != _faculty) return false;
      return true;
    }).toList();
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _copyToClipboard() {
    final rows = _filtered;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows to copy')),
      );
      return;
    }
    // Tab-separated so pasting into a Google Sheets/Excel cell lands each
    // value in its own column rather than one long string.
    final buffer = StringBuffer('Mobile\tEmail\tFaculty\n');
    for (final l in rows) {
      buffer.writeln('${l.phone}\t${l.email}\t${l.topFaculty ?? ''}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${rows.length} rows to clipboard')),
    );
  }

  void _downloadCsv() {
    final rows = _filtered;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows to export')),
      );
      return;
    }
    String esc(String v) =>
        v.contains(',') || v.contains('"') || v.contains('\n')
            ? '"${v.replaceAll('"', '""')}"'
            : v;

    final buffer = StringBuffer('Mobile Number,Email,Interested Faculty,City,State,Student Name\r\n');
    for (final l in rows) {
      buffer.writeln(
        '${esc(l.phone)},${esc(l.email)},${esc(l.topFaculty ?? '')},${esc(l.city)},${esc(l.state)},${esc(l.name)}',
      );
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final stamp = DateTime.now().toIso8601String().split('T').first;
    html.AnchorElement(href: url)
      ..setAttribute('download', 'weekly_leads_$stamp.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final filtered = _filtered;

    return AdminShellLayout(
      title: 'Weekly Lead Analytics',
      showBack: false,
      isAdminUser: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students active in the last 7 days',
                  style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Search-by-faculty, college views, and calls to a college -- rolled up per student.',
                  style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StateDropdown(
                      value: _state,
                      onChanged: (v) => setState(() {
                        _state = v;
                        _city = ''; // city belongs to the previous state
                      }),
                    ),
                    _CityDropdown(
                      state: _state,
                      value: _city,
                      onChanged: (v) => setState(() => _city = v),
                    ),
                    DropdownButton<String>(
                      value: _faculty,
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All Faculties')),
                        ...CollegeConstants.collegeCategories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _faculty = v ?? ''),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _downloadCsv,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${filtered.length} of ${_leads.length} active this week',
                  style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _leads.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Failed to load leads: $_error',
                          style: AppFonts.plusJakarta(color: tokens.textSecondary),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matching students active this week',
                              style: AppFonts.plusJakarta(color: tokens.textSecondary),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: PremiumCard(
                              radius: tokens.cardRadius,
                              padding: EdgeInsets.zero,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Student Name')),
                                      DataColumn(label: Text('Mobile Number')),
                                      DataColumn(label: Text('Email ID')),
                                      DataColumn(label: Text('City & State')),
                                      DataColumn(label: Text('Interested Faculty')),
                                      DataColumn(label: Text('Last Active')),
                                    ],
                                    rows: [
                                      for (final l in filtered)
                                        DataRow(
                                          cells: [
                                            DataCell(Text(l.name.isEmpty ? '—' : l.name)),
                                            DataCell(Text(l.phone.isEmpty ? '—' : l.phone)),
                                            DataCell(Text(l.email.isEmpty ? '—' : l.email)),
                                            DataCell(Text(
                                              [l.city, l.state].where((s) => s.isNotEmpty).join(', ').isEmpty
                                                  ? '—'
                                                  : [l.city, l.state].where((s) => s.isNotEmpty).join(', '),
                                            )),
                                            DataCell(Text(l.topFaculty ?? '—')),
                                            DataCell(Text(_dateLabel(l.lastActiveAt))),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StateDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StateDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      hint: const Text('All States'),
      items: [
        const DropdownMenuItem(value: '', child: Text('All States')),
        ...CollegeConstants.indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

/// Reuses AdminUserModerationService.getCitiesForState (built for the User
/// Management region-analytics panel) -- the distinct city values
/// students in [state] have actually registered with, not a static list.
class _CityDropdown extends ConsumerWidget {
  final String state;
  final String value;
  final ValueChanged<String> onChanged;

  const _CityDropdown({required this.state, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isEmpty) {
      return DropdownButton<String>(
        value: '',
        underline: const SizedBox.shrink(),
        items: const [DropdownMenuItem(value: '', child: Text('All Cities'))],
        onChanged: null,
      );
    }
    final citiesAsync = ref.watch(adminCitiesForStateProvider(state));
    return citiesAsync.when(
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (cities) => DropdownButton<String>(
        value: cities.contains(value) ? value : '',
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: '', child: Text('All Cities')),
          ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }
}
