import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../models/public_guide_profile.dart';
import '../providers/communication_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../widgets/guide_badge_widget.dart';

class GuidesDirectoryScreen extends ConsumerStatefulWidget {
  const GuidesDirectoryScreen({super.key});

  @override
  ConsumerState<GuidesDirectoryScreen> createState() =>
      _GuidesDirectoryScreenState();
}

class _GuidesDirectoryScreenState extends ConsumerState<GuidesDirectoryScreen> {
  String? _languageFilter;

  @override
  Widget build(BuildContext context) {
    final guidesAsync = ref.watch(guidesDirectoryProvider(_languageFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppTheme.gray600),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _languageFilter,
                    decoration: InputDecoration(
                      hintText: 'Filter by language',
                      filled: true,
                      fillColor: AppTheme.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All languages'),
                      ),
                      ...CommunicationConstants.supportedLanguages.map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _languageFilter = value);
                      ref.invalidate(guidesDirectoryProvider(_languageFilter));
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: guidesAsync.when(
              loading: () => const ListSkeletonLoader(itemCount: 5),
              error: (e, _) => AsyncErrorView(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(guidesDirectoryProvider(_languageFilter)),
              ),
              data: (guides) {
                if (guides.isEmpty) {
                  return AsyncEmptyView(
                    icon: Icons.school_outlined,
                    title: 'No guides available yet',
                    subtitle:
                        'Guides are verified students who help others.\nEnable guide mode in your profile to appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(guidesDirectoryProvider(_languageFilter));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: guides.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _GuideListTile(guide: guides[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideListTile extends StatelessWidget {
  final PublicGuideProfile guide;

  const _GuideListTile({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(RouteNames.guideProfilePath(guide.uid)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                    backgroundImage: guide.photoURL != null
                        ? NetworkImage(guide.photoURL!)
                        : null,
                    child: guide.photoURL == null
                        ? Text(
                            guide.displayName.isNotEmpty
                                ? guide.displayName[0].toUpperCase()
                                : 'G',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                guide.displayName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            VerificationBadgeWidget(
                              badge: guide.verificationBadge,
                            ),
                          ],
                        ),
                        if (guide.collegeName != null)
                          Text(
                            guide.collegeName!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.gray600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  GuideBadgeWidget(badgeTier: guide.stats.badgeTier),
                  if (guide.stats.totalRatings > 0)
                    _MiniChip(
                      icon: Icons.star,
                      label: guide.stats.overallRating.toStringAsFixed(1),
                    ),
                ],
              ),
              if (guide.languagesKnown.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  guide.languagesKnown.join(' · '),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.warningColor),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11)),
        ],
      ),
    );
  }
}
