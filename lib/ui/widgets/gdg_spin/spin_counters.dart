import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Ticket/spin counters and live status LCD inside the cabinet.
class SpinCounters extends StatelessWidget {
  final int tickets;
  final int spins;
  final SpinMessage message;
  final SpinPhase phase;
  final SpinOutcome? lastOutcome;
  final SpinSymbol? lastWinSymbol;
  final String? customStatusMessage;

  const SpinCounters({
    super.key,
    required this.tickets,
    required this.spins,
    required this.message,
    required this.phase,
    this.lastOutcome,
    this.lastWinSymbol,
    this.customStatusMessage,
  });

  String? _custom() {
    final trimmed = customStatusMessage?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _resolveMessage() => switch (message) {
    SpinMessage.pullHint => AppStrings.spinPullHint,
    SpinMessage.connecting => AppStrings.spinConnecting,
    SpinMessage.spinning => AppStrings.spinSpinning,
    SpinMessage.tease => AppStrings.spinTease,
    SpinMessage.win => AppStrings.spinWinMessage(_prizeName()),
    SpinMessage.bonus => AppStrings.spinBonusMessage(_bonusTickets()),
    SpinMessage.lose => AppStrings.spinLose(tickets),
    SpinMessage.outOfTickets => AppStrings.spinOutOfTickets,
    SpinMessage.noTickets => AppStrings.spinNoTickets,
    SpinMessage.paused => _custom() ?? AppStrings.spinPaused,
    SpinMessage.closed => AppStrings.spinClosed,
    SpinMessage.soldOut => AppStrings.spinSoldOutMessage,
    SpinMessage.cooldown => AppStrings.spinCooldown,
    SpinMessage.prizeCapReached => AppStrings.spinPrizeCapReached,
    SpinMessage.networkError => AppStrings.spinNetworkError,
    SpinMessage.noActiveEvent => AppStrings.spinNoActiveEvent,
    SpinMessage.trayHint => AppStrings.spinTrayHint,
    SpinMessage.coinsCollected => AppStrings.spinCoinsCollected,
    SpinMessage.missionDone => AppStrings.spinMissionDone(tickets),
    SpinMessage.triviaRight => _custom() ?? AppStrings.spinTriviaRight,
    SpinMessage.triviaWrong => _custom() ?? AppStrings.spinTriviaWrong,
    SpinMessage.codeRedeemed =>
      _custom() ?? AppStrings.spinCodeRedeemed('', tickets),
    SpinMessage.codeError => AppStrings.spinCodeError,
    SpinMessage.requirementNotMet => AppStrings.spinMissionRequirementNotMet,
    SpinMessage.ticketCapReached => AppStrings.spinTicketCapReached,
    SpinMessage.triviaClosed => AppStrings.spinTriviaClosed,
    SpinMessage.missionInactive => AppStrings.spinMissionInactive,
  };

  String _prizeName() {
    final outcome = lastOutcome;
    if (outcome is SpinPrizeOutcome) return outcome.prize.name;
    return '';
  }

  int _bonusTickets() {
    final outcome = lastOutcome;
    if (outcome is SpinBonusOutcome) return outcome.tickets;
    return 1;
  }

  Color _lcdColor() {
    if (message == SpinMessage.outOfTickets ||
        message == SpinMessage.noTickets ||
        message == SpinMessage.triviaWrong ||
        message == SpinMessage.paused ||
        message == SpinMessage.closed ||
        message == SpinMessage.soldOut ||
        message == SpinMessage.cooldown ||
        message == SpinMessage.prizeCapReached ||
        message == SpinMessage.networkError ||
        message == SpinMessage.noActiveEvent ||
        message == SpinMessage.codeError ||
        message == SpinMessage.requirementNotMet ||
        message == SpinMessage.ticketCapReached ||
        message == SpinMessage.triviaClosed ||
        message == SpinMessage.missionInactive) {
      return AppStyles.spinWarnColor;
    }
    if (phase == SpinPhase.win || phase == SpinPhase.bonus) {
      final accent = lastWinSymbol?.accentColor ?? AppStyles.gdgBrandPalette[1];
      return Color.alphaBlend(
        accent.withValues(alpha: 0.4),
        AppStyles.cardColor,
      );
    }
    return AppStyles.cardColor;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CounterBox(label: AppStrings.spinTicketsLabel, value: tickets),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: HardShadowBox(
              color: _lcdColor(),
              shadowColor: AppStyles.spinCabinetInnerShadowColor,
              radius: 14,
              shadowOffset: 3,
              borderWidth: 2.5,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Center(
                  child: Text(
                    _resolveMessage(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CounterBox(label: AppStrings.spinSpinsLabel, value: spins),
      ],
    );
  }
}

class _CounterBox extends StatelessWidget {
  final String label;
  final int value;

  const _CounterBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: HardShadowBox(
        color: AppStyles.cardColor,
        shadowColor: AppStyles.spinCabinetInnerShadowColor,
        radius: 14,
        shadowOffset: 3,
        borderWidth: 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
