import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../community/services/community_firestore_service.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';

class AlumniDirectoryScreen extends ConsumerWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alumniAsync = ref.watch(filteredAlumniProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Alumni Network'),
      ),
      body: alumniAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alumni) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search alumni by name, company...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) => ref.read(alumniSearchProvider.notifier).set(q),
            ),
            const SizedBox(height: 16),
            if (alumni.isEmpty)
              const Center(child: Text('No alumni profiles found'))
            else
              ...alumni.map(
                (a) => _AlumniCard(
                  alumni: a,
                  onTap: () => context.push(RouteNames.careersAlumniDetailPath(a.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AlumniProfileScreen extends ConsumerStatefulWidget {
  final String alumniId;

  const AlumniProfileScreen({required this.alumniId, super.key});

  @override
  ConsumerState<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends ConsumerState<AlumniProfileScreen> {
  bool _isStartingChat = false;

  @override
  Widget build(BuildContext context) {
    final alumniAsync = ref.watch(alumniByIdProvider(widget.alumniId));
    final followedIds = ref.watch(followedAlumniIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Alumni Profile'),
      ),
      body: alumniAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alumni) {
          if (alumni == null) return const Center(child: Text('Profile not found'));

          final isFollowing = followedIds.contains(alumni.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    child: Icon(Icons.school, color: AppTheme.primaryColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alumni.displayName,
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        if (alumni.isVerifiedAlumni)
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: AppTheme.secondaryColor),
                              Text(' Verified Alumni',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: AppTheme.secondaryColor)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _info(Icons.business_outlined, alumni.company),
              _info(Icons.work_outline, alumni.jobTitle),
              _info(Icons.location_on_outlined, alumni.location),
              _info(Icons.school_outlined, '${alumni.collegeName} · Batch ${alumni.batchYear}'),
              if (alumni.successStory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Success Story',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(alumni.successStory,
                    style: GoogleFonts.poppins(height: 1.5, color: AppTheme.gray700)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isStartingChat ? null : () => _askGuidance(alumni),
                      icon: _isStartingChat
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_outlined),
                      label: const Text('Ask for Guidance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _toggleFollow(alumni.id, isFollowing),
                    child: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
                ],
              ),
              if (alumni.linkedInUrl != null && alumni.linkedInUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(alumni.linkedInUrl!)),
                  icon: const Icon(Icons.link),
                  label: const Text('LinkedIn Profile'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gray500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _toggleFollow(String alumniId, bool isFollowing) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final repo = ref.read(careersRepositoryProvider);
      if (isFollowing) {
        await repo.unfollowAlumni(user.uid, alumniId);
      } else {
        await repo.followAlumni(user.uid, alumniId);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  Future<void> _askGuidance(AlumniProfileModel alumni) async {
    if (alumni.userId == null || alumni.userId!.isEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Direct messaging is not available for this alumni profile yet.',
      );
      return;
    }

    final authUser = ref.read(authStateProvider).valueOrNull;
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null || userDetail == null) return;

    setState(() => _isStartingChat = true);
    try {
      final conversation = await ref.read(communityServiceProvider).getOrCreatePrivateChat(
            currentUser: userDetail,
            peerId: alumni.userId!,
            peerName: alumni.displayName,
          );
      if (mounted) context.push(RouteNames.communityChatPath(conversation.id));
    } on CommunityException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }
}

class _AlumniCard extends StatelessWidget {
  final AlumniProfileModel alumni;
  final VoidCallback onTap;

  const _AlumniCard({required this.alumni, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        title: Text(alumni.displayName,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${alumni.jobTitle} at ${alumni.company}\nBatch ${alumni.batchYear} · ${alumni.collegeName}',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: alumni.isVerifiedAlumni
            ? Icon(Icons.verified, color: AppTheme.secondaryColor, size: 18)
            : null,
        onTap: onTap,
      ),
    );
  }
}
