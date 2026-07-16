import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/interaction_rating_model.dart';

class PostInteractionRatingSheet extends StatefulWidget {
  final String peerAlias;
  final Future<void> Function(InteractionRatingModel rating) onSubmit;

  const PostInteractionRatingSheet({
    required this.peerAlias,
    required this.onSubmit,
    super.key,
  });

  @override
  State<PostInteractionRatingSheet> createState() =>
      _PostInteractionRatingSheetState();
}

class _PostInteractionRatingSheetState extends State<PostInteractionRatingSheet> {
  int _stars = 5;
  bool _helpful = true;
  bool _respectful = true;
  bool _recommend = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How was your session with ${widget.peerAlias}?',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _stars = star),
                icon: Icon(
                  star <= _stars ? Icons.star : Icons.star_border,
                  color: AppTheme.warningColor,
                  size: 36,
                ),
              );
            }),
          ),
          SwitchListTile(
            title: const Text('Was this guide helpful?'),
            value: _helpful,
            onChanged: (v) => setState(() => _helpful = v),
          ),
          SwitchListTile(
            title: const Text('Was the interaction respectful?'),
            value: _respectful,
            onChanged: (v) => setState(() => _respectful = v),
          ),
          SwitchListTile(
            title: const Text('Would you recommend this guide?'),
            value: _recommend,
            onChanged: (v) => setState(() => _recommend = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        await widget.onSubmit(
                          InteractionRatingModel(
                            id: '',
                            sessionId: '',
                            raterId: '',
                            rateeId: '',
                            stars: _stars,
                            helpful: _helpful,
                            respectful: _respectful,
                            wouldRecommend: _recommend,
                            interactionType: 'call',
                            createdAt: DateTime.now(),
                          ),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Rating'),
            ),
          ),
        ],
      ),
    );
  }
}
