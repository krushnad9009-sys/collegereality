import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/premium_components.dart';
import '../models/college_model.dart';
import '../providers/college_name_suggestion_provider.dart';
import '../utils/college_name_matcher.dart';
import '../utils/college_suggestion_utils.dart';

/// The search dropdown shown under the search field while the user types.
///
///  * College NAMES that match come first, each with its "City, State" in
///    smaller text underneath:
///
///        Jawaharlal Nehru Engineering College
///        Aurangabad, Maharashtra
///
///  * Only when NO college name matches does it fall back to matching states
///    and cities (and, as a last resort, broader topics like "MBA").
///
/// It feeds the query to [collegeNameSuggestionsProvider]; the parent owns
/// debouncing (it calls `setQuery` with the debounced text) and reacts to
/// taps. Must stay mounted while the screen is, so the auto-disposed provider
/// lives as long as the screen does.
class CollegeSuggestionsPanel extends ConsumerWidget {
  /// The (debounced) text in the search field.
  final String query;
  final ValueChanged<CollegeModel> onCollegeTap;
  final ValueChanged<PlaceSuggestion> onPlaceTap;

  const CollegeSuggestionsPanel({
    required this.query,
    required this.onCollegeTap,
    required this.onPlaceTap,
    super.key,
  });

  /// Where [query] literally sits inside [name] (case-insensitive), so it can
  /// be shown bold; null when the match isn't a plain substring (initials,
  /// words typed out of order).
  static ({int start, int end})? highlightRange(String name, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    final at = name.toLowerCase().indexOf(q);
    if (at < 0) return null;
    return (start: at, end: at + q.length);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched unconditionally: keeps the auto-disposed provider alive while
    // the panel is on screen, even when it is currently drawing nothing.
    final state = ref.watch(collegeNameSuggestionsProvider);
    final q = query.trim();
    if (q.isEmpty) return const SizedBox.shrink();

    // Re-rank/narrow locally: instant as the user types more letters, and a
    // guarantee that only NAME matches, best first, are ever listed as
    // colleges no matter what the data layer returned.
    final names = CollegeNameMatcher.rank(q, state.colleges);

    final rows = <Widget>[];
    if (names.isNotEmpty) {
      for (final college in names) {
        rows.add(
          _CollegeRow(
            key: ValueKey('college-suggestion-${college.id}'),
            college: college,
            query: q,
            onTap: () => onCollegeTap(college),
          ),
        );
      }
    } else if (state.query == q && !state.isLoading) {
      // The lookup for exactly this text finished and no college name
      // matched: fall back to places. (While it is still loading we draw
      // nothing rather than flash places that names might replace.)
      for (final place in CollegeSuggestionUtils.placeSuggestions(q)) {
        rows.add(
          _PlaceRow(
            key: ValueKey('place-suggestion-${place.label}'),
            place: place,
            onTap: () => onPlaceTap(place),
          ),
        );
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: PremiumCard(
        radius: tokens.buttonRadius,
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          // About four rows, then it scrolls: keeps the results area below
          // from being squeezed on short phones.
          constraints: const BoxConstraints(maxHeight: 244),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rows.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, indent: 62, color: tokens.borderSubtle),
            itemBuilder: (_, index) => rows[index],
          ),
        ),
      ),
    );
  }
}

class _CollegeRow extends StatelessWidget {
  final CollegeModel college;
  final String query;
  final VoidCallback onTap;

  const _CollegeRow({
    required this.college,
    required this.query,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final location = CollegeNameMatcher.locationLabel(college);
    final range = CollegeSuggestionsPanel.highlightRange(college.name, query);
    final base = AppFonts.plusJakarta(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: tokens.textPrimary,
    );

    return _SuggestionRow(
      icon: Icons.school_rounded,
      semanticLabel: location.isEmpty
          ? college.name
          : '${college.name}, $location',
      onTap: onTap,
      title: Text.rich(
        range == null
            ? TextSpan(text: college.name, style: base)
            : TextSpan(
                style: base,
                children: [
                  TextSpan(text: college.name.substring(0, range.start)),
                  TextSpan(
                    text: college.name.substring(range.start, range.end),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: college.name.substring(range.end)),
                ],
              ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: location.isEmpty ? null : location,
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final PlaceSuggestion place;
  final VoidCallback onTap;

  const _PlaceRow({required this.place, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (icon, caption) = switch (place.kind) {
      SuggestionKind.state => (Icons.map_outlined, 'State'),
      SuggestionKind.city => (Icons.location_city_rounded, 'City'),
      SuggestionKind.topic => (Icons.search_rounded, null),
    };

    return _SuggestionRow(
      icon: icon,
      semanticLabel: caption == null ? place.label : '${place.label}, $caption',
      onTap: onTap,
      title: Text(
        place.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.plusJakarta(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: tokens.textPrimary,
        ),
      ),
      subtitle: caption,
    );
  }
}

/// Shared row chrome: tinted icon, a title, an optional smaller line beneath
/// it, and the "fill the search box" arrow.
class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final Widget title;
  final String? subtitle;
  final String semanticLabel;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.plusJakarta(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.north_west_rounded,
                  size: 16,
                  color: tokens.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
