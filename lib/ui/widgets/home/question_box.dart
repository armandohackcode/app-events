import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_ticket_popup.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Validates and submits a speaker question, showing feedback SnackBars and the
/// ticket popup if an `ask_speaker` mission was rewarded.
Future<bool> submitTalkQuestionWithFeedback(
  BuildContext context, {
  required String eventId,
  required String speakerUuid,
  required String rawText,
  VoidCallback? onSuccess,
}) async {
  final text = rawText.trim();
  if (text.length < 10) {
    customSnackbar(
      context,
      AppStrings.talkQuestionMinLength,
      color: AppStyles.colorBaseRed,
    );
    return false;
  }

  final talkProvider = maybeProvider<TalkInteractionProvider>(
    context,
    listen: false,
  );
  if (talkProvider == null) return false;
  final spinProvider = maybeProvider<GdgSpinProvider>(context, listen: false);

  try {
    final result = await talkProvider.submitQuestion(
      eventId: eventId,
      speakerUuid: speakerUuid,
      text: text,
    );
    if (result.missionRewarded) {
      spinProvider?.syncTicketsFromExternalAward(
        eventId: eventId,
        ticketsAfter: result.ticketsAfter,
      );
    }
    onSuccess?.call();
    if (!context.mounted) return true;
    customSnackbar(
      context,
      AppStrings.talkQuestionSent,
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
    return true;
  } on SpinException catch (e) {
    if (!context.mounted) return false;
    final errorText = switch (e.reason) {
      SpinErrorReason.rateLimited => AppStrings.talkQuestionRateLimited,
      SpinErrorReason.questionLimitReached =>
        AppStrings.talkQuestionLimitReached,
      SpinErrorReason.network => AppStrings.spinNetworkError,
      _ => AppStrings.talkQuestionError,
    };
    customSnackbar(context, errorText, color: AppStyles.colorBaseRed);
    return false;
  } catch (_) {
    if (!context.mounted) return false;
    customSnackbar(
      context,
      AppStrings.talkQuestionError,
      color: AppStyles.colorBaseRed,
    );
    return false;
  }
}

/// Question box of the live talk card, preserving the main visual layout while
/// forwarding questions to [TalkInteractionProvider] when live context exists.
class QuestionBox extends StatefulWidget {
  /// First name of the speaker the question is for.
  final String speakerName;
  final String? eventId;
  final String? speakerUuid;

  const QuestionBox({
    super.key,
    required this.speakerName,
    this.eventId,
    this.speakerUuid,
  });

  @override
  State<QuestionBox> createState() => _QuestionBoxState();
}

class _QuestionBoxState extends State<QuestionBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final eventId = widget.eventId?.trim();
    final speakerUuid = widget.speakerUuid?.trim();
    if (eventId == null ||
        eventId.isEmpty ||
        speakerUuid == null ||
        speakerUuid.isEmpty) {
      return;
    }

    final talkProvider = maybeProvider<TalkInteractionProvider>(
      context,
      listen: false,
    );
    if (talkProvider == null || talkProvider.submittingQuestion) return;

    await submitTalkQuestionWithFeedback(
      context,
      eventId: eventId,
      speakerUuid: speakerUuid,
      rawText: _controller.text,
      onSuccess: () {
        if (mounted) {
          _controller.clear();
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final talkProvider = maybeProvider<TalkInteractionProvider>(context);
    final submitting = talkProvider?.submittingQuestion ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.question_mark_rounded,
            size: 14,
            color: AppStyles.fontSecondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !submitting,
              maxLength: 300,
              textInputAction: TextInputAction.send,
              onSubmitted: !submitting ? (_) => unawaited(_submit()) : null,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppStyles.fontColor,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText:
                    '${AppStrings.homeLiveQuestionHintPrefix}${widget.speakerName}...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (submitting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppStyles.colorBaseBlue,
              ),
            )
          else
            Semantics(
              button: true,
              enabled: !submitting,
              label: AppStrings.talkAskSpeakerSend,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(_submit()),
                child: const Icon(
                  Icons.send_outlined,
                  size: 16,
                  color: AppStyles.colorBaseBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
