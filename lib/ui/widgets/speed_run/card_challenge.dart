import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CardChallenge extends StatelessWidget {
  final SpeedRunChallenge challenge;
  final VoidCallback onTap;

  const CardChallenge({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = challenge.state == ChallengeState.inactive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isInactive ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: isInactive ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppStyles.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppStyles.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Hero(
                    tag: 'challenge_image_${challenge.id}',
                    child: CachedNetworkImage(
                      imageUrl: challenge.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        height: 160,
                        color: AppStyles.borderColor,
                        child: Center(
                          child: LoadingAnimationWidget.twistingDots(
                            leftDotColor: AppStyles.colorBaseBlue,
                            rightDotColor: AppStyles.colorBaseYellow,
                            size: 32,
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        height: 160,
                        color: AppStyles.borderColor,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
