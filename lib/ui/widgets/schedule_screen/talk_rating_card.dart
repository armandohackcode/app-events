import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_ticket_popup.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Pop-brutalist 5-star talk rating and optional feedback card.
class TalkRatingCard extends StatefulWidget {
  final String eventId;
  final String speakerUuid;
  final String? uid;

  const TalkRatingCard({
    super.key,
    required this.eventId,
    required this.speakerUuid,
    this.uid,
  });

  @override
  State<TalkRatingCard> createState() => _TalkRatingCardState();
}

class _TalkRatingCardState extends State<TalkRatingCard> {
  final TextEditingController _commentController = TextEditingController();
  StreamSubscription<TalkRating?>? _ratingSub;
  String? _subscribedKey;
  int _selectedStars = 0;
  bool _hasExistingRating = false;
  bool _initializedFromStream = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRatingStream();
  }

  @override
  void didUpdateWidget(covariant TalkRatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId ||
        oldWidget.speakerUuid != widget.speakerUuid ||
        oldWidget.uid != widget.uid) {
      _initializedFromStream = false;
      _subscribedKey = null;
      _syncRatingStream();
    }
  }

  void _syncRatingStream() {
    final uid = widget.uid?.trim();
    final talkProvider = maybeProvider<TalkInteractionProvider>(
      context,
      listen: false,
    );
    if (uid == null || uid.isEmpty || talkProvider == null) {
      unawaited(_ratingSub?.cancel());
      _ratingSub = null;
      _subscribedKey = null;
      return;
    }

    final nextKey = '${widget.eventId}:${widget.speakerUuid}:$uid';
    if (_subscribedKey == nextKey && _ratingSub != null) return;

    unawaited(_ratingSub?.cancel());
    _subscribedKey = nextKey;
    _ratingSub = talkProvider
        .watchMyRating(widget.eventId, widget.speakerUuid, uid)
        .listen(
          (rating) {
            if (!mounted || rating == null) return;
            setState(() {
              _hasExistingRating = true;
              if (!_initializedFromStream) {
                _initializedFromStream = true;
                _selectedStars = rating.stars.clamp(0, 5);
                _commentController.text = rating.comment;
              }
            });
          },
          onError: (_) {
            // Silently ignore stream read errors; user can still submit a rating.
          },
        );
  }

  @override
  void dispose() {
    unawaited(_ratingSub?.cancel());
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStars < 1 || _selectedStars > 5) {
      customSnackbar(
        context,
        AppStrings.talkRatingSelectStars,
        color: AppStyles.colorBaseRed,
      );
      return;
    }

    final talkProvider = maybeProvider<TalkInteractionProvider>(
      context,
      listen: false,
    );
    if (talkProvider == null || talkProvider.submittingRating) return;

    try {
      final result = await talkProvider.submitRating(
        eventId: widget.eventId,
        speakerUuid: widget.speakerUuid,
        stars: _selectedStars,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _hasExistingRating = true);
      customSnackbar(
        context,
        AppStrings.talkRatingSaved,
        color: AppStyles.colorBaseGreen,
      );
      final serial = result.ticketSerial;
      if (result.missionRewarded && serial != null && serial.isNotEmpty) {
        await SpinTicketPopup.showWon(
          context,
          tickets: result.ticketsAfter,
          serial: serial,
        );
      }
    } catch (_) {
      if (!mounted) return;
      customSnackbar(
        context,
        AppStrings.talkRatingError,
        color: AppStyles.colorBaseRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final talkProvider = maybeProvider<TalkInteractionProvider>(context);
    final submitting = talkProvider?.submittingRating ?? false;

    return TaggedCard(
      tag: AppStrings.talkRatingTag,
      tagColor: AppStyles.colorBaseYellow,
      angleDegrees: -1.5,
      compact: true,
      child: HardShadowBox(
        color: AppStyles.cardColor,
        radius: 16,
        shadowOffset: 4,
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.talkRatingPrompt,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: submitting
                        ? null
                        : () => setState(() {
                            _initializedFromStream = true;
                            _selectedStars = star;
                          }),
                    icon: Icon(
                      star <= _selectedStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: star <= _selectedStars
                          ? AppStyles.talkRatingStarColor
                          : AppStyles.talkRatingStarInactiveColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              enabled: !submitting,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.talkRatingCommentHint,
                counterText: '',
                filled: true,
                fillColor: AppStyles.gamesBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppStyles.borderColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppStyles.borderColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ChunkyButton(
              label: _hasExistingRating
                  ? AppStrings.talkRatingUpdate
                  : AppStrings.talkRatingSubmit,
              color: AppStyles.spinBezelColor,
              expand: true,
              minHeight: 44,
              onPressed: submitting ? null : () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
