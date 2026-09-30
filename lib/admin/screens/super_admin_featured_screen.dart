import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../core/widgets/index.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';
import '../../features/colleges/widgets/college_autocomplete_field.dart';
import '../../features/communication/models/public_guide_profile.dart';
import '../../features/communication/providers/communication_provider.dart';
import '../../features/communication/utils/guide_search_matcher.dart';
import '../../features/home/featured/home_featured.dart';
import '../../features/home/featured/home_featured_provider.dart';

/// Super Admin → "Featured / Top List": choose which colleges and guides
/// appear in Home's "Top Picks", and in what order (position 1, 2, 3...).
/// Edits stay local until "Save", which writes the whole ordered list in
/// one go (homepage_featured/current; Super Admin-only in firestore.rules).
class SuperAdminFeaturedScreen extends ConsumerStatefulWidget {
  const SuperAdminFeaturedScreen({super.key});

  @override
  ConsumerState<SuperAdminFeaturedScreen> createState() =>
      _SuperAdminFeaturedScreenState();
}

class _SuperAdminFeaturedScreenState
    extends ConsumerState<SuperAdminFeaturedScreen> {
  List<String>? _collegeIds; // null until hydrated from the saved config
  List<String>? _guideIds;
  HomeFeaturedConfig? _saved;
  final Map<String, String> _collegeNames = {};
  final Map<String, String> _guideNames = {};
  final Set<String> _unavailable = {};
  bool _saving = false;

  bool get _dirty =>
      _saved != null &&
      (!_listEquals(_collegeIds!, _saved!.collegeIds) ||
          !_listEquals(_guideIds!, _saved!.guideIds));

  static bool _listEquals(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  Future<void> _hydrate(HomeFeaturedConfig config) async {
    setState(() {
      _saved = config;
      _collegeIds = [...config.collegeIds];
      _guideIds = [...config.guideIds];
    });
    final service = ref.read(homeFeaturedServiceProvider);
    final colleges =
        await service.loadColleges(config.collegeIds, activeOnly: false);
    final guides =
        await service.loadGuides(config.guideIds, availableOnly: false);
    if (!mounted) return;
    setState(() {
      for (final c in colleges) {
        _collegeNames[c.id] = c.name;
        if (!c.isActive) _unavailable.add(c.id);
      }
      for (final g in guides) {
        _guideNames[g.uid] = g.displayName;
      }
      // Pinned guides that no longer resolve (left guide mode) are flagged.
      for (final id in config.guideIds) {
        if (!guides.any((g) => g.uid == id)) _unavailable.add(id);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(homeFeaturedServiceProvider).save(
            collegeIds: _collegeIds!,
            guideIds: _guideIds!,
          );
      ref.invalidate(homeTopCollegesProvider);
      ref.invalidate(homeTopGuidesProvider);
      if (mounted) {
        setState(() => _saved = HomeFeaturedConfig(
              collegeIds: [..._collegeIds!],
              guideIds: [..._guideIds!],
            ));
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Homepage Top Picks updated.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not save: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(homeFeaturedConfigProvider);
    final config = configAsync.valueOrNull;
    if (config != null && _saved == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate(config));
    }
    final ready = _collegeIds != null && _guideIds != null;

    return AdminShellLayout(
      title: 'Featured / Top List',
      showBack: false,
      isAdminUser: true,
      child: !ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Pinned items appear in "Top Picks" near the top of the '
                  'Home screen, in this order. Drag or use the arrows to '
                  'reorder. With nothing pinned, Home shows top-rated '
                  'colleges and top guides automatically. Max '
                  '${HomeFeaturedConfig.maxItems} of each.',
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _FeaturedListCard(
                  title: 'Colleges',
                  icon: Icons.school_outlined,
                  ids: _collegeIds!,
                  names: _collegeNames,
                  unavailable: _unavailable,
                  onChanged: (ids) => setState(() => _collegeIds = ids),
                  addField: CollegeAutocompleteField(
                    onChanged: (college) {
                      if (college == null) return;
                      setState(() {
                        _collegeNames[college.id] = college.name;
                        _collegeIds = addFeaturedId(_collegeIds!, college.id);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _FeaturedListCard(
                  title: 'Guides',
                  icon: Icons.record_voice_over_outlined,
                  ids: _guideIds!,
                  names: _guideNames,
                  unavailable: _unavailable,
                  onChanged: (ids) => setState(() => _guideIds = ids),
                  addField: _GuidePicker(
                    onSelected: (guide) => setState(() {
                      _guideNames[guide.uid] = guide.displayName;
                      _guideIds = addFeaturedId(_guideIds!, guide.uid);
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _dirty ? 'Save changes' : 'Saved',
                        isLoading: _saving,
                        onPressed: _dirty ? _save : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _dirty && !_saving
                          ? () => setState(() {
                                _collegeIds = [..._saved!.collegeIds];
                                _guideIds = [..._saved!.guideIds];
                              })
                          : null,
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _FeaturedListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> ids;
  final Map<String, String> names;
  final Set<String> unavailable;
  final ValueChanged<List<String>> onChanged;
  final Widget addField;

  const _FeaturedListCard({
    required this.title,
    required this.icon,
    required this.ids,
    required this.names,
    required this.unavailable,
    required this.onChanged,
    required this.addField,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final full = ids.length >= HomeFeaturedConfig.maxItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$title  (${ids.length}/${HomeFeaturedConfig.maxItems})',
                  style: AppFonts.plusJakarta(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ids.isEmpty)
              Text(
                'Nothing pinned — Home shows top-rated ${title.toLowerCase()}.',
                style: AppFonts.plusJakarta(
                    fontSize: 13, color: tokens.textTertiary),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                onReorderItem: (from, to) =>
                    onChanged(moveFeaturedId(ids, from, to)),
                children: [
                  for (var i = 0; i < ids.length; i++)
                    ListTile(
                      key: ValueKey(ids[i]),
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                      title: Text(names[ids[i]] ?? ids[i]),
                      subtitle: unavailable.contains(ids[i])
                          ? const Text(
                              'Not shown on Home (inactive / not available)',
                              style: TextStyle(color: Colors.orange),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Move up',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0
                                ? null
                                : () => onChanged(moveFeaturedId(ids, i, i - 1)),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: i == ids.length - 1
                                ? null
                                : () => onChanged(moveFeaturedId(ids, i, i + 1)),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.close),
                            onPressed: () => onChanged(
                                [...ids]..removeAt(i)),
                          ),
                          const SizedBox(width: 32), // drag handle space
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            if (full)
              Text(
                'List is full — remove one to add another.',
                style: AppFonts.plusJakarta(
                    fontSize: 12, color: tokens.textTertiary),
              )
            else
              addField,
          ],
        ),
      ),
    );
  }
}

/// Search available guides (guide mode on) by name / college / course.
class _GuidePicker extends ConsumerWidget {
  final ValueChanged<PublicGuideProfile> onSelected;

  const _GuidePicker({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides =
        ref.watch(guidesDirectoryProvider(null)).valueOrNull ?? const [];
    return Autocomplete<PublicGuideProfile>(
      displayStringForOption: (g) => g.displayName,
      optionsBuilder: (value) {
        final q = value.text.trim();
        if (q.isEmpty) return const Iterable<PublicGuideProfile>.empty();
        final byName = guides.where(
          (g) => g.displayName.toLowerCase().contains(q.toLowerCase()),
        );
        return {...byName, ...GuideSearchMatcher.filter(guides, q)}.take(10);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
          TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Add a guide — search by name, college or stream',
          border: OutlineInputBorder(),
        ),
      ),
      optionsViewBuilder: (context, onPick, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final g in options)
                  ListTile(
                    title: Text(g.displayName),
                    subtitle: Text(g.collegeName ?? ''),
                    onTap: () => onPick(g),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
