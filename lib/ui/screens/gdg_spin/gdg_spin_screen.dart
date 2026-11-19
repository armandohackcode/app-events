import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_cabinet.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_missions_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_my_prizes_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_pay_table_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_ticket_popup.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full GDG SPIN slot-machine screen with cabinet, prizes, pay table, and missions.
class GdgSpinScreen extends StatefulWidget {
  const GdgSpinScreen({super.key});

  @override
  State<GdgSpinScreen> createState() => _GdgSpinScreenState();
}

class _GdgSpinScreenState extends State<GdgSpinScreen> {
  final GlobalKey _payTableKey = GlobalKey();

  void _scrollToPayTable() {
    final target = _payTableKey.currentContext;
    if (target == null) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      target,
      duration: Duration(milliseconds: reduced ? 0 : 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleMissionTap(
    BuildContext context,
    GdgSpinProvider provider,
    SpinMission mission,
  ) async {
    final awarded = provider.completeMission(mission.id);
    if (!awarded || !context.mounted) return;
    await SpinTicketPopup.showWon(
      context,
      tickets: provider.tickets,
      serial: provider.generateTicketSerial(),
    );
  }

  Future<void> _handleTriviaAnswer(
    BuildContext context,
    GdgSpinProvider provider,
    bool correct,
  ) async {
    final awarded = provider.answerTrivia(correct);
    if (!awarded || !context.mounted) return;
    await SpinTicketPopup.showWon(
      context,
      tickets: provider.tickets,
      serial: provider.generateTicketSerial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GdgSpinProvider>();
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 52,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 4,
          leadingWidth: 44,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppStyles.fontColor,
            ),
          ),
          title: const Text(
            AppStrings.spinTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppStyles.fontColor,
            ),
          ),
          actions: [
            SpinTicketsPill(
              tickets: provider.tickets,
              onTap: () => SpinTicketPopup.showBalance(
                context,
                tickets: provider.tickets,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: TickerMode(
          enabled: isCurrentRoute,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SpinCabinet(
                      provider: provider,
                      onScrollToPayTable: _scrollToPayTable,
                    ),
                    const SizedBox(height: 18),
                    TaggedCard(
                      tag: AppStrings.spinMyPrizes,
                      tagColor: AppStyles.spinMyPrizesTagColor,
                      angleDegrees: -1,
                      child: SpinMyPrizesCard(prizes: provider.myPrizes),
                    ),
                    const SizedBox(height: 18),
                    TaggedCard(
                      key: _payTableKey,
                      tag: AppStrings.spinPayTable,
                      tagColor: AppStyles.spinPayTableTagColor,
                      angleDegrees: -2,
                      child: SpinPayTableCard(prizes: provider.prizes),
                    ),
                    const SizedBox(height: 18),
                    TaggedCard(
                      tag: AppStrings.spinEarnTickets,
                      tagColor: AppStyles.spinEarnTagColor,
                      angleDegrees: 2,
                      child: SpinMissionsCard(
                        missions: provider.missions,
                        triviaOpen: provider.triviaOpen,
                        onMissionTap: (m) =>
                            _handleMissionTap(context, provider, m),
                        onAnswerTrivia: (ok) =>
                            _handleTriviaAnswer(context, provider, ok),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
