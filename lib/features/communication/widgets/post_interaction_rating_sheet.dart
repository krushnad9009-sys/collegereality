import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
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
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: tokens.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'Rate your experience',
            style: AppFonts.plusJakarta(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How was your session with ${widget.peerAlias}?',
            style: AppFonts.plusJakarta(
              color: tokens.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _stars = star),
                icon: Icon(
                  star <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 36,
                ),
              );
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: primary,
            title: Text(
              'Was this guide helpful?',
              style: AppFonts.plusJakarta(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            value: _helpful,
            onChanged: (v) => setState(() => _helpful = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: primary,
            title: Text(
              'Was the interaction respectful?',
              style: AppFonts.plusJakarta(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            value: _respectful,
            onChanged: (v) => setState(() => _respectful = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: primary,
            title: Text(
              'Would you recommend this guide?',
              style: AppFonts.plusJakarta(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            value: _recommend,
            onChanged: (v) => setState(() => _recommend = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                ),
                elevation: 0,
              ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Rating',
                      style: AppFonts.plusJakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
