import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/events/events_screen.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_screen.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_cabinet.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_context_binder.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_missions_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_my_prizes_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_pay_table_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_redeem_qr_dialog.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_ticket_popup.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/profile/edit_profile.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Full GDG SPIN slot-machine screen with cabinet, prizes, pay table, and missions.
class GdgSpinScreen extends StatefulWidget {
  final String? eventIdOverride;
  final String? uidOverride;

  const GdgSpinScreen({super.key, this.eventIdOverride, this.uidOverride});

  @override
  State<GdgSpinScreen> createState() => _GdgSpinScreenState();
}

class _GdgSpinScreenState extends State<GdgSpinScreen>
    with WidgetsBindingObserver {
  final GlobalKey _payTableKey = GlobalKey();
  bool _requestedEvents = false;
  GdgSpinProvider? _spinProvider;
  Timer? _spinWatchdogTimer;
  int? _watchedSpinId;
  int? _pausedSpinId;
  DateTime? _pausedSpinAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to optional context providers so late-loading events/auth bind automatically.
    resolveSpinContextIds(
      context,
      eventIdOverride: widget.eventIdOverride,
      uidOverride: widget.uidOverride,
      listen: true,
    );
    final spinProvider = Provider.of<GdgSpinProvider>(context, listen: false);
    if (!identical(_spinProvider, spinProvider)) {
      _spinProvider?.removeListener(_onSpinProviderChanged);
      _spinProvider?.detachView();
      _spinProvider = spinProvider;
      spinProvider.attachView();
      spinProvider.addListener(_onSpinProviderChanged);
      _onSpinProviderChanged();
    }
    _requestedEvents = scheduleSpinContextBinding(
      context,
      spinProvider: spinProvider,
      alreadyRequestedEvents: _requestedEvents,
      eventIdOverride: widget.eventIdOverride,
      uidOverride: widget.uidOverride,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final provider = _spinProvider;
    if (provider == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (provider.phase == SpinPhase.spinning) {
        _pausedSpinId = provider.spinId;
        _pausedSpinAt = DateTime.now();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final pausedSpinId = _pausedSpinId;
      final pausedAt = _pausedSpinAt;
      _pausedSpinId = null;
      _pausedSpinAt = null;
      if (provider.phase == SpinPhase.spinning &&
          pausedSpinId == provider.spinId) {
        final reduced = mounted && MediaQuery.disableAnimationsOf(context);
        final maxExpected = Duration(milliseconds: reduced ? 800 : 4500);
        final elapsed = pausedAt == null
            ? Duration.zero
            : DateTime.now().difference(pausedAt);
        if (elapsed >= maxExpected) {
          provider.settleInterruptedSpin();
        } else {
          final remaining = maxExpected - elapsed;
          _armSpinWatchdog(
            provider.spinId,
            delay: remaining + const Duration(milliseconds: 300),
          );
        }
      }
    }
  }

  void _onSpinProviderChanged() {
    final provider = _spinProvider;
    if (provider == null || !mounted) return;
    if (provider.phase == SpinPhase.spinning) {
      if (_watchedSpinId != provider.spinId || _spinWatchdogTimer == null) {
        final reduced = MediaQuery.disableAnimationsOf(context);
        _armSpinWatchdog(
          provider.spinId,
          delay: Duration(milliseconds: reduced ? 1500 : 5500),
        );
      }
    } else {
      _spinWatchdogTimer?.cancel();
      _spinWatchdogTimer = null;
      _watchedSpinId = null;
      _pausedSpinId = null;
      _pausedSpinAt = null;
    }
  }

  void _armSpinWatchdog(int targetSpinId, {required Duration delay}) {
    _spinWatchdogTimer?.cancel();
    _watchedSpinId = targetSpinId;
    _spinWatchdogTimer = Timer(delay, () {
      if (!mounted) return;
      final provider = _spinProvider;
      if (provider != null &&
          provider.phase == SpinPhase.spinning &&
          provider.spinId == targetSpinId) {
        provider.settleInterruptedSpin();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spinWatchdogTimer?.cancel();
    _spinWatchdogTimer = null;
    final spinProvider = _spinProvider;
    _spinProvider = null;
    if (spinProvider != null) {
      spinProvider.removeListener(_onSpinProviderChanged);
      final hadActiveSpinOrCelebration =
          spinProvider.phase == SpinPhase.spinning ||
          spinProvider.phase == SpinPhase.win ||
          spinProvider.phase == SpinPhase.bonus ||
          spinProvider.phase == SpinPhase.nearMiss;
      spinProvider.detachView();
      if (hadActiveSpinOrCelebration) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          spinProvider.notifyViewSettled();
        });
      }
    }
    super.dispose();
  }

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
    if (mission.isTrivia) {
      provider.toggleTrivia(mission.id);
      return;
    }

    try {
      final result = await provider.claimMission(mission.id);
      if (result != null && result.granted && context.mounted) {
        await SpinTicketPopup.showWon(
          context,
          tickets: result.ticketsAfter,
          serial: result.ticketSerial,
        );
      }
    } on SpinException catch (e) {
      if (!context.mounted) return;
      if (e.reason == SpinErrorReason.requirementNotMet) {
        await _handleRequirementNotMet(context, provider, mission);
        return;
      }
      customSnackbar(
        context,
        _mapMissionErrorMessage(e.reason),
        color: AppStyles.colorBaseRed,
      );
    } catch (_) {
      if (!context.mounted) return;
      customSnackbar(
        context,
        AppStrings.spinNetworkError,
        color: AppStyles.colorBaseRed,
      );
    }
  }

  Future<void> _handleRequirementNotMet(
    BuildContext context,
    GdgSpinProvider provider,
    SpinMission mission,
  ) async {
    switch (mission.type) {
      case SpinMissionType.profileComplete:
        final userProvider = maybeProvider<UserProvider>(
          context,
          listen: false,
        );
        if (userProvider?.userCompetitor == null) {
          customSnackbar(
            context,
            AppStrings.spinMissionRequirementNotMet,
            color: AppStyles.colorBaseRed,
          );
          return;
        }
        await Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (_) => const EditProfile()));
        if (!context.mounted) return;
        try {
          final retryResult = await provider.claimMission(mission.id);
          if (retryResult != null && retryResult.granted && context.mounted) {
            await SpinTicketPopup.showWon(
              context,
              tickets: retryResult.ticketsAfter,
              serial: retryResult.ticketSerial,
            );
          }
        } on SpinException catch (retryError) {
          if (!context.mounted) return;
          customSnackbar(
            context,
            _mapMissionErrorMessage(retryError.reason),
            color: AppStyles.colorBaseRed,
          );
        }
      case SpinMissionType.workshopRegister:
      case SpinMissionType.askSpeaker:
      case SpinMissionType.rateTalk:
        final eventProvider = maybeProvider<EventProvider>(
          context,
          listen: false,
        );
        if (eventProvider != null) {
          await Navigator.of(
            context,
          ).push(CupertinoPageRoute(builder: (_) => const EventsScreen()));
        } else {
          customSnackbar(
            context,
            AppStrings.spinMissionRequirementNotMet,
            color: AppStyles.colorBaseRed,
          );
        }
      case SpinMissionType.trivia:
        break;
    }
  }

  Future<void> _handleTriviaAnswer(
    BuildContext context,
    GdgSpinProvider provider,
    String missionId,
    int optionIndex,
  ) async {
    try {
      final result = await provider.submitTrivia(missionId, optionIndex);
      if (result == null || !context.mounted) return;
      if (result.correct && result.ticketsAwarded > 0) {
        await SpinTicketPopup.showWon(
          context,
          tickets: result.ticketsAfter,
          serial: result.ticketSerial ?? '',
        );
      }
    } on SpinException catch (e) {
      if (!context.mounted) return;
      customSnackbar(
        context,
        _mapMissionErrorMessage(e.reason),
        color: AppStyles.colorBaseRed,
      );
    } catch (_) {
      if (!context.mounted) return;
      customSnackbar(
        context,
        AppStrings.spinNetworkError,
        color: AppStyles.colorBaseRed,
      );
    }
  }

  Future<void> _showStandCodeDialog(
    BuildContext context,
    GdgSpinProvider provider,
  ) async {
    final result = await showDialog<SpinRedeemTicketCodeResult>(
      context: context,
      builder: (_) => _StandCodeDialog(provider: provider),
    );
    if (result == null || !context.mounted) return;
    await SpinTicketPopup.showWon(
      context,
      tickets: result.ticketsAfter,
      serial: result.ticketSerial,
    );
  }

  String _mapMissionErrorMessage(SpinErrorReason reason) => switch (reason) {
    SpinErrorReason.requirementNotMet =>
      AppStrings.spinMissionRequirementNotMet,
    SpinErrorReason.ticketCapReached => AppStrings.spinTicketCapReached,
    SpinErrorReason.triviaClosed => AppStrings.spinTriviaClosed,
    SpinErrorReason.missionInactive => AppStrings.spinMissionInactive,
    SpinErrorReason.alreadyExists => AppStrings.spinMissionAlreadyClaimed,
    _ => AppStrings.spinNetworkError,
  };

  Widget? _buildStatusBanner(BuildContext context, GdgSpinProvider provider) {
    if (provider.isLoading) return null;

    if (provider.bindError != null) {
      final ids = resolveSpinContextIds(
        context,
        eventIdOverride: widget.eventIdOverride,
        uidOverride: widget.uidOverride,
        listen: false,
      );
      return _SpinStatusBanner(
        color: AppStyles.spinWarnColor,
        icon: Icons.wifi_off_rounded,
        title: AppStrings.spinBannerRetryTitle,
        body: AppStrings.spinBannerRetryHint,
        actionLabel: (ids.eventId != null && ids.uid != null)
            ? AppStrings.spinRetryAction
            : null,
        onAction: (ids.eventId != null && ids.uid != null)
            ? () =>
                  unawaited(provider.bind(eventId: ids.eventId!, uid: ids.uid!))
            : null,
      );
    }

    if (!provider.isBound) {
      return const _SpinStatusBanner(
        color: AppStyles.spinBannerClosedColor,
        icon: Icons.event_busy_rounded,
        title: AppStrings.spinBannerNoEventTitle,
        body: AppStrings.spinBannerNoEventBody,
      );
    }

    if (provider.isSoldOut) {
      return const _SpinStatusBanner(
        color: AppStyles.spinBannerClosedColor,
        icon: Icons.inventory_2_outlined,
        title: AppStrings.spinBannerSoldOutTitle,
        body: AppStrings.spinBannerSoldOutBody,
      );
    }

    if (provider.isClosed) {
      return const _SpinStatusBanner(
        color: AppStyles.spinBannerClosedColor,
        icon: Icons.lock_clock_rounded,
        title: AppStrings.spinBannerClosedTitle,
        body: AppStrings.spinBannerClosedBody,
      );
    }

    if (provider.isPaused) {
      final pauseText = provider.config?.pauseMessage.trim() ?? '';
      return _SpinStatusBanner(
        color: AppStyles.spinBannerPausedColor,
        icon: Icons.pause_circle_outline_rounded,
        title: AppStrings.spinBannerPausedTitle,
        body: pauseText.isNotEmpty ? pauseText : AppStrings.spinPaused,
      );
    }

    if (provider.isBlockedByPrizeCap) {
      return const _SpinStatusBanner(
        color: AppStyles.spinBannerCapColor,
        icon: Icons.emoji_events_outlined,
        title: AppStrings.spinBannerPrizeCapTitle,
        body: AppStrings.spinBannerPrizeCapBody,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GdgSpinProvider>();
    final userProvider = maybeProvider<UserProvider>(context);
    final ids = resolveSpinContextIds(
      context,
      eventIdOverride: widget.eventIdOverride,
      uidOverride: widget.uidOverride,
      listen: true,
    );
    final adminEventId = ids.eventId ?? provider.boundEventId;
    final showAdminButton =
        (userProvider?.isAdmin ?? false) &&
        adminEventId != null &&
        adminEventId.isNotEmpty;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final banner = _buildStatusBanner(context, provider);
    final canPop =
        provider.phase != SpinPhase.requesting &&
        provider.phase != SpinPhase.spinning;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        customSnackbar(context, AppStrings.spinWaitSpinFinish);
      },
      child: HomeBackdrop(
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
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.spinTitle,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
            actions: [
              if (showAdminButton)
                IconButton(
                  tooltip: AppStrings.spinAdminTitle,
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppStyles.fontColor,
                  ),
                  onPressed: () {
                    final eventTitle = maybeProvider<EventProvider>(
                      context,
                      listen: false,
                    )?.activeEvent?.title;
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => SpinAdminScreen(
                          eventId: adminEventId,
                          eventTitle: eventTitle,
                        ),
                      ),
                    );
                  },
                ),
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
          body: SafeArea(
            top: false,
            child: TickerMode(
              enabled: isCurrentRoute,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (banner != null) ...[
                          banner,
                          const SizedBox(height: 14),
                        ],
                        SpinCabinet(
                          provider: provider,
                          onScrollToPayTable: _scrollToPayTable,
                        ),
                        const SizedBox(height: 18),
                        TaggedCard(
                          tag: AppStrings.spinMyPrizes,
                          tagColor: AppStyles.spinMyPrizesTagColor,
                          angleDegrees: -1,
                          child: SpinMyPrizesCard(
                            prizes: provider.myWins,
                            onPrizeTap: (win) =>
                                SpinRedeemQrDialog.show(context, win: win),
                          ),
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
                            openTriviaMissionId: provider.openTriviaMissionId,
                            busy: provider.isMissionBusy,
                            onMissionTap: (m) =>
                                _handleMissionTap(context, provider, m),
                            onAnswerTrivia: (missionId, optionIndex) =>
                                _handleTriviaAnswer(
                                  context,
                                  provider,
                                  missionId,
                                  optionIndex,
                                ),
                            onRedeemCodeTap: provider.isBound
                                ? () => _showStandCodeDialog(context, provider)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinStatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SpinStatusBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: color,
      radius: 18,
      shadowOffset: 4,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppStyles.cardColor,
              border: Border.all(color: AppStyles.borderColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppStyles.fontColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.fontColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.fontColor,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  ChunkyButton(
                    label: actionLabel!,
                    color: AppStyles.colorBaseYellow,
                    minHeight: 38,
                    fontSize: 12,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandCodeDialog extends StatefulWidget {
  final GdgSpinProvider provider;

  const _StandCodeDialog({required this.provider});

  @override
  State<_StandCodeDialog> createState() => _StandCodeDialogState();
}

class _StandCodeDialogState extends State<_StandCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit([String? overrideCode]) async {
    final code = (overrideCode ?? _controller.text).trim();
    if (code.isEmpty) {
      setState(() => _errorText = AppStrings.spinCodeInvalidFormat);
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final res = await widget.provider.redeemTicketCode(code);
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } on SpinException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _mapCodeError(e.reason));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = AppStrings.spinCodeError);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _scanQr() async {
    final barcode = await Navigator.of(context).push<Barcode?>(
      CupertinoPageRoute(
        builder: (_) =>
            const QRScanContent(msg: AppStrings.spinStandCodeScanMsg),
      ),
    );
    final scanned = barcode?.code?.trim();
    if (!mounted || scanned == null || scanned.isEmpty) return;
    _controller.text = scanned;
    await _submit(scanned);
  }

  String _mapCodeError(SpinErrorReason reason) => switch (reason) {
    SpinErrorReason.codeDepleted => AppStrings.spinCodeDepleted,
    SpinErrorReason.codeExpired => AppStrings.spinCodeExpired,
    SpinErrorReason.codeAlreadyExists ||
    SpinErrorReason.alreadyExists => AppStrings.spinCodeAlreadyClaimed,
    SpinErrorReason.notFound => AppStrings.spinCodeNotFound,
    SpinErrorReason.invalidCodeFormat => AppStrings.spinCodeInvalidFormat,
    SpinErrorReason.ticketCapReached => AppStrings.spinTicketCapReached,
    SpinErrorReason.network => AppStrings.spinNetworkError,
    _ => AppStrings.spinCodeError,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: HardShadowBox(
                  color: AppStyles.cardColor,
                  radius: 22,
                  shadowOffset: 5,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        enabled: !_submitting,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => unawaited(_submit()),
                        decoration: InputDecoration(
                          hintText: AppStrings.spinStandCodeHint,
                          filled: true,
                          fillColor: AppStyles.gamesBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.colorBaseRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ChunkyButton(
                        label: AppStrings.spinStandCodeScan,
                        color: AppStyles.activitiesRankingTagColor,
                        expand: true,
                        minHeight: 44,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                          color: AppStyles.fontColor,
                        ),
                        onPressed: _submitting ? null : _scanQr,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChunkyButton(
                              label: AppStrings.commonWordCancel,
                              color: AppStyles.cardColor,
                              minHeight: 44,
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChunkyButton(
                              label: AppStrings.spinStandCodeSubmit,
                              color: AppStyles.colorBaseYellow,
                              minHeight: 44,
                              onPressed: _submitting
                                  ? null
                                  : () => unawaited(_submit()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: TiltedTag(
                    text: AppStrings.spinStandCodeTitle,
                    color: AppStyles.colorBaseYellow,
                    angleDegrees: -1.5,
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
