import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _WaveDraft {
  final String id;
  final TextEditingController labelController;
  DateTime startAt;
  final TextEditingController releasePctController;
  final TextEditingController budgetPctController;

  _WaveDraft({
    required this.id,
    required String label,
    required this.startAt,
    required double releaseRatio,
    required double spinBudgetShare,
  }) : labelController = TextEditingController(text: label),
       releasePctController = TextEditingController(
         text: (releaseRatio * 100).round().toString(),
       ),
       budgetPctController = TextEditingController(
         text: (spinBudgetShare * 100).round().toString(),
       );

  void dispose() {
    labelController.dispose();
    releasePctController.dispose();
    budgetPctController.dispose();
  }
}

/// Tab 1: Live game status, Rush Final switch, KPIs, and pacing/rules editor.
class SpinAdminControlTab extends StatefulWidget {
  final String eventId;

  const SpinAdminControlTab({super.key, required this.eventId});

  @override
  State<SpinAdminControlTab> createState() => _SpinAdminControlTabState();
}

class _SpinAdminControlTabState extends State<SpinAdminControlTab> {
  final TextEditingController _pauseMessageController = TextEditingController();
  final TextEditingController _defaultInitialTicketsController =
      TextEditingController();
  final TextEditingController _registeredAttendeesController =
      TextEditingController();
  final TextEditingController _expectedSpinsController =
      TextEditingController();
  final TextEditingController _estimatedOverrideController =
      TextEditingController();
  final TextEditingController _maxPrizesPerUserController =
      TextEditingController();
  final TextEditingController _minSpinsBetweenWinsController =
      TextEditingController();
  final Map<PrizeRarity, TextEditingController> _rarityControllers = {
    for (final rarity in PrizeRarity.values) rarity: TextEditingController(),
  };
  final TextEditingController _bonusProbPctController = TextEditingController();
  final TextEditingController _bonusMinController = TextEditingController();
  final TextEditingController _bonusMaxController = TextEditingController();
  final TextEditingController _maxBonusWinsController = TextEditingController();
  final TextEditingController _maxWinProbPctController =
      TextEditingController();
  final TextEditingController _rushMaxWinProbPctController =
      TextEditingController();
  final TextEditingController _payoutMultiplierController =
      TextEditingController();
  final TextEditingController _cooldownMsController = TextEditingController();
  final TextEditingController _maxEarnedTicketsController =
      TextEditingController();

  SpinGameStatus _status = SpinGameStatus.paused;
  SpinPacingMode _pacingMode = SpinPacingMode.timePaced;
  bool _allowPlayAfterCap = false;
  DateTime? _pacingStartAt;
  DateTime? _pacingEndAt;
  final List<_WaveDraft> _waves = [];

  SpinConfig? _lastSyncedConfig;
  bool _isSyncingConfig = false;
  bool _isDirty = false;
  bool _hasRemoteConfigUpdate = false;

  @override
  void initState() {
    super.initState();
    _registeredAttendeesController.addListener(_onEstimateInputChanged);
    _expectedSpinsController.addListener(_onEstimateInputChanged);
    _estimatedOverrideController.addListener(_onEstimateInputChanged);
    for (final controller in [
      _pauseMessageController,
      _defaultInitialTicketsController,
      _maxPrizesPerUserController,
      _minSpinsBetweenWinsController,
      ..._rarityControllers.values,
      _bonusProbPctController,
      _bonusMinController,
      _bonusMaxController,
      _maxBonusWinsController,
      _maxWinProbPctController,
      _rushMaxWinProbPctController,
      _payoutMultiplierController,
      _cooldownMsController,
      _maxEarnedTicketsController,
    ]) {
      controller.addListener(_onFormInputChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = context.watch<SpinAdminProvider>().config;
    if (config != null && !identical(config, _lastSyncedConfig)) {
      if (_isDirty) {
        _hasRemoteConfigUpdate = true;
      } else {
        _hasRemoteConfigUpdate = false;
        _syncFromConfig(config);
      }
    }
  }

  @override
  void dispose() {
    _pauseMessageController.dispose();
    _defaultInitialTicketsController.dispose();
    _registeredAttendeesController.dispose();
    _expectedSpinsController.dispose();
    _estimatedOverrideController.dispose();
    _maxPrizesPerUserController.dispose();
    _minSpinsBetweenWinsController.dispose();
    for (final controller in _rarityControllers.values) {
      controller.dispose();
    }
    _bonusProbPctController.dispose();
    _bonusMinController.dispose();
    _bonusMaxController.dispose();
    _maxBonusWinsController.dispose();
    _maxWinProbPctController.dispose();
    _rushMaxWinProbPctController.dispose();
    _payoutMultiplierController.dispose();
    _cooldownMsController.dispose();
    _maxEarnedTicketsController.dispose();
    for (final wave in _waves) {
      wave.dispose();
    }
    super.dispose();
  }

  void _onEstimateInputChanged() {
    if (_isSyncingConfig) return;
    _isDirty = true;
    if (mounted) setState(() {});
  }

  void _onFormInputChanged() {
    if (_isSyncingConfig) return;
    if (!_isDirty) {
      if (mounted) {
        setState(() => _isDirty = true);
      } else {
        _isDirty = true;
      }
    }
  }

  void _attachWaveListeners(_WaveDraft wave) {
    wave.labelController.addListener(_onFormInputChanged);
    wave.releasePctController.addListener(_onFormInputChanged);
    wave.budgetPctController.addListener(_onFormInputChanged);
  }

  void _reloadRemoteConfig(SpinConfig config) {
    setState(() {
      _isDirty = false;
      _hasRemoteConfigUpdate = false;
      _syncFromConfig(config);
    });
  }

  void _syncFromConfig(SpinConfig config) {
    _isSyncingConfig = true;
    try {
      _lastSyncedConfig = config;
      _status = config.status;
      _pauseMessageController.text = config.pauseMessage;
      _defaultInitialTicketsController.text = config.defaultInitialTickets
          .toString();
      _registeredAttendeesController.text = config.registeredAttendeesCount
          .toString();
      _expectedSpinsController.text = config.expectedSpinsPerAttendee
          .toString();
      _estimatedOverrideController.text =
          config.estimatedTotalSpinsOverride?.toString() ?? '';
      _pacingMode = config.pacingMode;
      _pacingStartAt = config.pacingStartAt;
      _pacingEndAt = config.pacingEndAt;

      for (final wave in _waves) {
        wave.dispose();
      }
      _waves
        ..clear()
        ..addAll(
          config.pacingWaves.map((w) {
            final draft = _WaveDraft(
              id: w.id,
              label: w.label,
              startAt: w.startAt,
              releaseRatio: w.releaseRatio,
              spinBudgetShare: w.spinBudgetShare,
            );
            _attachWaveListeners(draft);
            return draft;
          }),
        );

      _maxPrizesPerUserController.text = config.maxPrizesPerUser.toString();
      _allowPlayAfterCap = config.allowPlayAfterCap;
      _minSpinsBetweenWinsController.text = config.minSpinsBetweenWins
          .toString();
      for (final rarity in PrizeRarity.values) {
        _rarityControllers[rarity]!.text = (config.maxWinsByRarity[rarity] ?? 0)
            .toString();
      }

      _bonusProbPctController.text = (config.bonusProbability * 100)
          .toStringAsFixed(1);
      _bonusMinController.text = config.bonusMinTickets.toString();
      _bonusMaxController.text = config.bonusMaxTickets.toString();
      _maxBonusWinsController.text = config.maxBonusWinsPerUser.toString();
      _maxWinProbPctController.text = (config.maxWinProbabilityPerSpin * 100)
          .toStringAsFixed(0);
      _rushMaxWinProbPctController.text =
          (config.rushMaxWinProbabilityPerSpin * 100).toStringAsFixed(0);
      _payoutMultiplierController.text = config.payoutMultiplier.toString();
      _cooldownMsController.text = config.spinCooldownMs.toString();
      _maxEarnedTicketsController.text = config.maxTotalEarnedTicketsPerUser
          .toString();
    } finally {
      _isSyncingConfig = false;
    }
  }

  int _computePreviewEstimatedSpins() {
    final overrideVal = int.tryParse(_estimatedOverrideController.text.trim());
    if (overrideVal != null && overrideVal >= 1) {
      return overrideVal;
    }
    final attendees =
        int.tryParse(_registeredAttendeesController.text.trim()) ?? 0;
    final perPerson =
        double.tryParse(_expectedSpinsController.text.trim()) ?? 0;
    final product = (attendees * perPerson).round();
    return product < 1 ? 1 : product;
  }

  Future<void> _saveStatus(SpinAdminProvider provider) async {
    try {
      final updated = await provider.setGameStatus(
        _status,
        pauseMessage: _pauseMessageController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _hasRemoteConfigUpdate = false;
        _syncFromConfig(updated);
      });
      showSpinAdminFeedback(context, AppStrings.spinAdminStatusSaved);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _confirmAndToggleRush(
    SpinAdminProvider provider,
    bool enable,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          enable
              ? AppStrings.spinAdminRushConfirmTitle
              : AppStrings.spinAdminRushDisableTitle,
        ),
        content: Text(
          enable
              ? AppStrings.spinAdminRushConfirmBody
              : AppStrings.spinAdminRushDisableBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.commonWordCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enable
                  ? AppStyles.spinAdminRushColor
                  : AppStyles.colorBaseYellow,
              foregroundColor: enable
                  ? AppStyles.onAccentColor
                  : AppStyles.fontColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              enable
                  ? AppStrings.spinAdminRushConfirmAction
                  : AppStrings.spinAdminRushDisableAction,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await provider.setRushMode(enable);
      if (!mounted) return;
      showSpinAdminFeedback(context, AppStrings.spinAdminConfigSaved);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  void _addWave() {
    final baseTime = _waves.isNotEmpty
        ? _waves.last.startAt.add(const Duration(hours: 2))
        : (_pacingStartAt ?? DateTime.now());
    final draft = _WaveDraft(
      id: 'wave_${DateTime.now().millisecondsSinceEpoch}',
      label: AppStrings.spinAdminWaveDefaultLabel,
      startAt: baseTime,
      releaseRatio: 1.0,
      spinBudgetShare: 0.0,
    );
    _attachWaveListeners(draft);
    setState(() {
      _isDirty = true;
      _waves.add(draft);
    });
  }

  void _removeWave(int index) {
    setState(() {
      _isDirty = true;
      final removed = _waves.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveRules(SpinAdminProvider provider) async {
    final defaultInitial = int.tryParse(
      _defaultInitialTicketsController.text.trim(),
    );
    final registeredCount = int.tryParse(
      _registeredAttendeesController.text.trim(),
    );
    final expectedSpins = double.tryParse(_expectedSpinsController.text.trim());
    final overrideRaw = _estimatedOverrideController.text.trim();
    final estimatedOverride = overrideRaw.isEmpty
        ? null
        : int.tryParse(overrideRaw);

    final maxPrizes = int.tryParse(_maxPrizesPerUserController.text.trim());
    final minSpinsBetween = int.tryParse(
      _minSpinsBetweenWinsController.text.trim(),
    );
    final rarityCaps = <String, int>{};
    for (final rarity in PrizeRarity.values) {
      final parsed = int.tryParse(_rarityControllers[rarity]!.text.trim());
      if (parsed == null || parsed < 0 || parsed > 100) {
        showSpinAdminFeedback(
          context,
          AppStrings.spinAdminInvalidRulesInput,
          isError: true,
        );
        return;
      }
      rarityCaps[rarity.value] = parsed;
    }

    final bonusProbPct = double.tryParse(_bonusProbPctController.text.trim());
    final bonusMin = int.tryParse(_bonusMinController.text.trim());
    final bonusMax = int.tryParse(_bonusMaxController.text.trim());
    final maxBonusWins = int.tryParse(_maxBonusWinsController.text.trim());
    final maxWinProbPct = double.tryParse(_maxWinProbPctController.text.trim());
    final rushMaxWinProbPct = double.tryParse(
      _rushMaxWinProbPctController.text.trim(),
    );
    final payoutMultiplier = double.tryParse(
      _payoutMultiplierController.text.trim(),
    );
    final cooldownMs = int.tryParse(_cooldownMsController.text.trim());
    final maxEarned = int.tryParse(_maxEarnedTicketsController.text.trim());

    final invalidNumbers =
        defaultInitial == null ||
        defaultInitial < 0 ||
        defaultInitial > 50 ||
        registeredCount == null ||
        registeredCount < 0 ||
        registeredCount > 100000 ||
        expectedSpins == null ||
        expectedSpins < 0.1 ||
        expectedSpins > 100 ||
        (overrideRaw.isNotEmpty &&
            (estimatedOverride == null ||
                estimatedOverride < 1 ||
                estimatedOverride > 1000000)) ||
        maxPrizes == null ||
        maxPrizes < 0 ||
        maxPrizes > 100 ||
        minSpinsBetween == null ||
        minSpinsBetween < 0 ||
        minSpinsBetween > 100 ||
        bonusProbPct == null ||
        bonusProbPct < 0 ||
        bonusProbPct > 50 ||
        bonusMin == null ||
        bonusMin < 1 ||
        bonusMin > 20 ||
        bonusMax == null ||
        bonusMax < 1 ||
        bonusMax > 20 ||
        bonusMin > bonusMax ||
        maxBonusWins == null ||
        maxBonusWins < 0 ||
        maxBonusWins > 50 ||
        maxWinProbPct == null ||
        maxWinProbPct <= 0 ||
        maxWinProbPct > 100 ||
        rushMaxWinProbPct == null ||
        rushMaxWinProbPct <= 0 ||
        rushMaxWinProbPct > 100 ||
        payoutMultiplier == null ||
        payoutMultiplier < 0.01 ||
        payoutMultiplier > 20 ||
        cooldownMs == null ||
        cooldownMs < 0 ||
        cooldownMs > 300000 ||
        maxEarned == null ||
        maxEarned < 0 ||
        maxEarned > 500;

    if (invalidNumbers) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminInvalidRulesInput,
        isError: true,
      );
      return;
    }

    if (_pacingStartAt != null &&
        _pacingEndAt != null &&
        !_pacingEndAt!.isAfter(_pacingStartAt!)) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminInvalidRulesInput,
        isError: true,
      );
      return;
    }

    final wavePayloads = <Map<String, dynamic>>[];
    double totalBudgetShare = 0;
    for (var i = 0; i < _waves.length; i++) {
      final wave = _waves[i];
      final label = wave.labelController.text.trim();
      final releasePct = double.tryParse(wave.releasePctController.text.trim());
      final budgetPct = double.tryParse(wave.budgetPctController.text.trim());
      if (label.isEmpty ||
          releasePct == null ||
          releasePct < 0 ||
          releasePct > 100 ||
          budgetPct == null ||
          budgetPct < 0 ||
          budgetPct > 100) {
        showSpinAdminFeedback(
          context,
          AppStrings.spinAdminInvalidWavesOrder,
          isError: true,
        );
        return;
      }

      final releaseRatio = releasePct / 100.0;
      final budgetShare = budgetPct / 100.0;
      totalBudgetShare += budgetShare;

      if (i > 0) {
        final prev = _waves[i - 1];
        final prevRelease =
            (double.tryParse(prev.releasePctController.text.trim()) ?? 0) /
            100.0;
        if (wave.startAt.isBefore(prev.startAt) || releaseRatio < prevRelease) {
          showSpinAdminFeedback(
            context,
            AppStrings.spinAdminInvalidWavesOrder,
            isError: true,
          );
          return;
        }
      }

      wavePayloads.add({
        'id': wave.id,
        'label': label,
        'startAt': wave.startAt.toUtc().toIso8601String(),
        'releaseRatio': releaseRatio,
        'spinBudgetShare': budgetShare,
      });
    }

    if (totalBudgetShare > 1.0001) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminInvalidWavesOrder,
        isError: true,
      );
      return;
    }

    final patch = <String, dynamic>{
      'defaultInitialTickets': defaultInitial,
      'registeredAttendeesCount': registeredCount,
      'expectedSpinsPerAttendee': expectedSpins,
      'estimatedTotalSpinsOverride': estimatedOverride,
      'pacingMode': _pacingMode.value,
      'pacingStartAt': _pacingStartAt?.toUtc().toIso8601String(),
      'pacingEndAt': _pacingEndAt?.toUtc().toIso8601String(),
      'pacingWaves': wavePayloads,
      'maxPrizesPerUser': maxPrizes,
      'allowPlayAfterCap': _allowPlayAfterCap,
      'maxWinsByRarity': rarityCaps,
      'minSpinsBetweenWins': minSpinsBetween,
      'bonusProbability': bonusProbPct / 100.0,
      'bonusMinTickets': bonusMin,
      'bonusMaxTickets': bonusMax,
      'maxBonusWinsPerUser': maxBonusWins,
      'maxWinProbabilityPerSpin': maxWinProbPct / 100.0,
      'rushMaxWinProbabilityPerSpin': rushMaxWinProbPct / 100.0,
      'payoutMultiplier': payoutMultiplier,
      'spinCooldownMs': cooldownMs,
      'maxTotalEarnedTicketsPerUser': maxEarned,
    };

    try {
      final updated = await provider.updateConfig(patch);
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _hasRemoteConfigUpdate = false;
        _syncFromConfig(updated);
      });
      showSpinAdminFeedback(context, AppStrings.spinAdminConfigSaved);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpinAdminProvider>();
    final dashboard = provider.dashboard;
    final config = provider.config;
    final prizes = provider.prizes.isNotEmpty
        ? provider.prizes
        : (dashboard?.prizes ?? const <SpinPrize>[]);

    final totalRemaining = prizes.fold<int>(
      0,
      (sum, p) => sum + p.remainingStock,
    );
    final totalInitial = prizes.fold<int>(0, (sum, p) => sum + p.initialStock);
    final rushEnabled = config?.rushMode ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasRemoteConfigUpdate && config != null) ...[
                SpinAdminRemoteConfigBanner(
                  onReload: () => _reloadRemoteConfig(config),
                ),
                const SizedBox(height: 12),
              ],
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminStatusTag,
                tagColor: AppStyles.colorBaseYellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusSelector(
                      selected: _status,
                      onChanged: (next) => setState(() {
                        _isDirty = true;
                        _status = next;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pauseMessageController,
                      maxLines: 2,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminPauseMessageLabel,
                        hintText: AppStrings.spinAdminPauseMessageHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ChunkyButton(
                      label: AppStrings.spinAdminSaveStatus,
                      color: AppStyles.colorBaseYellow,
                      expand: true,
                      minHeight: 44,
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _saveStatus(provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HardShadowBox(
                color: rushEnabled
                    ? AppStyles.spinAdminRushCardColor
                    : AppStyles.cardColor,
                radius: 18,
                shadowOffset: 4,
                borderWidth: 2.5,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  AppStrings.spinAdminRushLabel,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppStyles.fontColor,
                                  ),
                                ),
                              ),
                              if (rushEnabled) ...[
                                const SizedBox(width: 8),
                                const SpinAdminBadge(
                                  text: AppStrings.spinAdminRushActiveBadge,
                                  color: AppStyles.spinAdminRushColor,
                                  textColor: AppStyles.onAccentColor,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppStrings.spinAdminRushSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppStyles.fontSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: rushEnabled,
                      activeThumbColor: AppStyles.spinAdminRushColor,
                      onChanged: provider.isSubmitting
                          ? null
                          : (next) => _confirmAndToggleRush(provider, next),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminKpiTag,
                tagColor: AppStyles.spinAdminTagColor,
                angleDegrees: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiSpins,
                          value: '${dashboard?.stats.totalSpins ?? 0}',
                        ),
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiStock,
                          value: AppStrings.spinAdminStockRatio(
                            totalRemaining,
                            totalInitial,
                          ),
                        ),
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiRedeemed,
                          value:
                              '${dashboard?.winCounts.redeemed ?? 0} / ${dashboard?.winCounts.pending ?? 0}',
                        ),
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiPlayers,
                          value: '${dashboard?.activePlayersCount ?? 0}',
                        ),
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiRegistrations,
                          value: '${dashboard?.registrationsCount ?? 0}',
                        ),
                        _KpiTile(
                          width: cardWidth,
                          label: AppStrings.spinAdminKpiBonus,
                          value: '${dashboard?.stats.totalBonusSpins ?? 0}',
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminPacingTag,
                tagColor: AppStyles.activitiesTreasureTagColor,
                angleDegrees: -1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _defaultInitialTicketsController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText:
                                  AppStrings.spinAdminDefaultInitialTickets,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _registeredAttendeesController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText:
                                  AppStrings.spinAdminRegisteredCountLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expectedSpinsController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminExpectedSpinsLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _estimatedOverrideController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText:
                                  AppStrings.spinAdminEstimatedOverrideLabel,
                              hintText:
                                  AppStrings.spinAdminEstimatedOverrideHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.spinAdminAutoEstimate(
                        _computePreviewEstimatedSpins(),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.colorBaseBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      AppStrings.spinAdminPacingModeLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final mode in SpinPacingMode.values)
                          ChoiceChip(
                            label: Text(_pacingModeLabel(mode)),
                            selected: _pacingMode == mode,
                            selectedColor: AppStyles.colorBaseYellow,
                            onSelected: (_) => setState(() {
                              _isDirty = true;
                              _pacingMode = mode;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SpinAdminDateTimeTile(
                      label: AppStrings.spinAdminPacingStart,
                      value: _pacingStartAt,
                      onChanged: (val) => setState(() {
                        _isDirty = true;
                        _pacingStartAt = val;
                      }),
                    ),
                    const SizedBox(height: 8),
                    SpinAdminDateTimeTile(
                      label: AppStrings.spinAdminPacingEnd,
                      value: _pacingEndAt,
                      onChanged: (val) => setState(() {
                        _isDirty = true;
                        _pacingEndAt = val;
                      }),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          AppStrings.spinAdminWavesTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.fontColor,
                          ),
                        ),
                        ChunkyButton(
                          label: AppStrings.spinAdminAddWave,
                          color: AppStyles.spinAdminTagColor,
                          minHeight: 36,
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          onPressed: _addWave,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _waves.length; i++) ...[
                      _WaveEditorRow(
                        wave: _waves[i],
                        onStartChanged: (dt) {
                          if (dt != null) {
                            setState(() {
                              _isDirty = true;
                              _waves[i].startAt = dt;
                            });
                          }
                        },
                        onDelete: () => _removeWave(i),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(height: 20),
                    const Text(
                      AppStrings.spinAdminUserCapsTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _maxPrizesPerUserController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminMaxPrizesPerUser,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _minSpinsBetweenWinsController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText:
                                  AppStrings.spinAdminMinSpinsBetweenWins,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        AppStrings.spinAdminAllowPlayAfterCap,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      value: _allowPlayAfterCap,
                      onChanged: (val) => setState(() {
                        _isDirty = true;
                        _allowPlayAfterCap = val;
                      }),
                    ),
                    const Text(
                      AppStrings.spinAdminMaxWinsRarityTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        Widget fieldFor(PrizeRarity rarity) => Expanded(
                          child: TextField(
                            controller: _rarityControllers[rarity],
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: spinRarityLabel(rarity),
                            ),
                          ),
                        );

                        if (constraints.maxWidth < 420) {
                          const values = PrizeRarity.values;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  fieldFor(values[0]),
                                  const SizedBox(width: 8),
                                  fieldFor(values[1]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  fieldFor(values[2]),
                                  const SizedBox(width: 8),
                                  fieldFor(values[3]),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            for (final rarity in PrizeRarity.values) ...[
                              if (rarity.index > 0) const SizedBox(width: 6),
                              fieldFor(rarity),
                            ],
                          ],
                        );
                      },
                    ),
                    const Divider(height: 24),
                    const Text(
                      AppStrings.spinAdminBonusSecurityTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bonusProbPctController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminBonusProbPct,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxBonusWinsController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminMaxBonusWins,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bonusMinController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminBonusMinTickets,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _bonusMaxController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminBonusMaxTickets,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _maxWinProbPctController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminMaxWinProbPct,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _rushMaxWinProbPctController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminRushMaxWinProbPct,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _payoutMultiplierController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminPayoutMultiplier,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _cooldownMsController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminCooldownMs,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maxEarnedTicketsController,
                      keyboardType: TextInputType.number,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminMaxEarnedTickets,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ChunkyButton(
                      label: AppStrings.spinAdminSaveRules,
                      color: AppStyles.activitiesTreasureTagColor,
                      expand: true,
                      minHeight: 46,
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _saveRules(provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pacingModeLabel(SpinPacingMode mode) => switch (mode) {
    SpinPacingMode.timePaced => AppStrings.spinAdminPacingTimePaced,
    SpinPacingMode.dynamicSpins => AppStrings.spinAdminPacingDynamicSpins,
    SpinPacingMode.manualWaves => AppStrings.spinAdminPacingManualWaves,
  };
}

class _StatusSelector extends StatelessWidget {
  final SpinGameStatus selected;
  final ValueChanged<SpinGameStatus> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in SpinGameStatus.values) ...[
          if (status.index > 0) const SizedBox(width: 8),
          Expanded(
            child: _StatusChoiceTile(
              status: status,
              selected: selected == status,
              onTap: () => onChanged(status),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChoiceTile extends StatelessWidget {
  final SpinGameStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChoiceTile({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, activeColor) = switch (status) {
      SpinGameStatus.paused => (
        AppStrings.spinAdminStatusPaused,
        AppStyles.spinAdminPausedStatusColor,
      ),
      SpinGameStatus.active => (
        AppStrings.spinAdminStatusActive,
        AppStyles.spinAdminActiveStatusColor,
      ),
      SpinGameStatus.closed => (
        AppStrings.spinAdminStatusClosed,
        AppStyles.spinAdminClosedStatusColor,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: HardShadowBox(
        color: selected ? activeColor : AppStyles.gamesBackgroundColor,
        radius: 12,
        shadowOffset: selected ? 3 : 0,
        borderWidth: selected ? 2.5 : 1.5,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: AppStyles.fontColor,
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _KpiTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: HardShadowBox(
        color: AppStyles.spinAdminKpiCardColor,
        radius: 12,
        shadowOffset: 2,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppStyles.fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveEditorRow extends StatelessWidget {
  final _WaveDraft wave;
  final ValueChanged<DateTime?> onStartChanged;
  final VoidCallback onDelete;

  const _WaveEditorRow({
    required this.wave,
    required this.onStartChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.gamesBackgroundColor,
      radius: 12,
      shadowOffset: 2,
      borderWidth: 1.5,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: wave.labelController,
                  decoration: spinAdminInputDecoration(
                    labelText: AppStrings.spinAdminWaveLabel,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppStyles.spinAdminDangerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SpinAdminDateTimeTile(
            label: AppStrings.spinAdminWaveStart,
            value: wave.startAt,
            onChanged: onStartChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: wave.releasePctController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: spinAdminInputDecoration(
                    labelText: AppStrings.spinAdminWaveReleasePct,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: wave.budgetPctController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: spinAdminInputDecoration(
                    labelText: AppStrings.spinAdminWaveBudgetPct,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
