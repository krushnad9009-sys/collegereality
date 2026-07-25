import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../../core/constants/college_constants.dart';
import '../../core/widgets/index.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';
import '../services/super_admin_settings_service.dart';

class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() => _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState extends ConsumerState<SuperAdminSettingsScreen> {
  final _announcementController = TextEditingController();
  final _bannerController = TextEditingController();
  final _aiPromptController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _announcementController.dispose();
    _bannerController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  void _applySettings(Map<String, dynamic> data) {
    if (_loaded) return;
    _announcementController.text = data['globalAnnouncement']?.toString() ?? '';
    _bannerController.text = data['homeBannerUrl']?.toString() ?? '';
    _aiPromptController.text = data['aiSystemPrompt']?.toString() ?? '';
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(superAdminSettingsServiceProvider).saveSettings({
        'globalAnnouncement': _announcementController.text.trim(),
        'homeBannerUrl': _bannerController.text.trim(),
        'aiSystemPrompt': _aiPromptController.text.trim(),
        'categories': CollegeConstants.collegeTypes,
        'courses': CollegeConstants.popularCourses,
        'states': CollegeConstants.indianStates,
      });
      ref.invalidate(superAdminSettingsProvider);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Settings saved.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Save failed: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(superAdminSettingsProvider);

    return AdminShellLayout(
      title: 'Platform Settings',
      isAdminUser: true,
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (data) {
          _applySettings(data);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Configure announcements, banners, AI behavior, and reference data.',
                style: GoogleFonts.inter(color: AppTheme.gray600),
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Global Announcement',
                child: TextField(
                  controller: _announcementController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Shown to all users on the home screen',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              _Section(
                title: 'Home Banner URL',
                child: TextField(
                  controller: _bannerController,
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
              ),
              _Section(
                title: 'AI Assistant Configuration',
                child: TextField(
                  controller: _aiPromptController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'System prompt override for AI assistant',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.smart_toy_outlined),
                  ),
                ),
              ),
              _Section(
                title: 'Reference Data',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories: ${CollegeConstants.collegeTypes.length}', style: GoogleFonts.inter()),
                    Text('Courses: ${CollegeConstants.popularCourses.length}', style: GoogleFonts.inter()),
                    Text('States: ${CollegeConstants.indianStates.length}', style: GoogleFonts.inter()),
                    const SizedBox(height: 8),
                    Text(
                      'Full taxonomy editing UI — TODO for production.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
