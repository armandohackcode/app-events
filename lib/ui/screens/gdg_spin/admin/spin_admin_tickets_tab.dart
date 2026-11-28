import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_registration_parser.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class _PackageBonusDraft {
  final TextEditingController nameController;
  final TextEditingController bonusController;

  _PackageBonusDraft({required String name, required int bonus})
    : nameController = TextEditingController(text: name),
      bonusController = TextEditingController(text: bonus.toString());

  void dispose() {
    nameController.dispose();
    bonusController.dispose();
  }
}

/// Tab 4: CSV/JSON registrations import, package bonuses, stand QR campaigns,
/// and manual ticket grants.
class SpinAdminTicketsTab extends StatefulWidget {
  final String eventId;

  const SpinAdminTicketsTab({super.key, required this.eventId});

  @override
  State<SpinAdminTicketsTab> createState() => _SpinAdminTicketsTabState();
}

class _SpinAdminTicketsTabState extends State<SpinAdminTicketsTab> {
  final TextEditingController _importController = TextEditingController();
  final TextEditingController _attendeeSearchController =
      TextEditingController();
  final TextEditingController _grantReasonController = TextEditingController();
  final List<_PackageBonusDraft> _packageDrafts = [];

  bool _replaceAll = false;
  bool _attendeesLoadRequested = false;
  bool _isSyncingConfig = false;
  bool _isDirty = false;
  bool _hasRemoteConfigUpdate = false;
  SpinConfig? _lastSyncedConfig;
  UserCompetitor? _selectedAttendee;
  int _grantAmount = 1;

  @override
  void initState() {
    super.initState();
    _importController.addListener(_refreshUi);
    _attendeeSearchController.addListener(_refreshUi);
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
        _syncPackagesFromConfig(config);
      }
    }

    final userProvider = maybeProvider<UserProvider>(context, listen: false);
    if (!_attendeesLoadRequested &&
        userProvider != null &&
        userProvider.attendees.isEmpty &&
        !userProvider.loadingAttendees) {
      _attendeesLoadRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(userProvider.getAttendees().catchError((_) {}));
      });
    }
  }

  @override
  void dispose() {
    _importController.dispose();
    _attendeeSearchController.dispose();
    _grantReasonController.dispose();
    for (final d in _packageDrafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  void _onPackageInputChanged() {
    if (_isSyncingConfig) return;
    if (!_isDirty) {
      if (mounted) {
        setState(() => _isDirty = true);
      } else {
        _isDirty = true;
      }
    }
  }

  void _attachPackageListeners(_PackageBonusDraft draft) {
    draft.nameController.addListener(_onPackageInputChanged);
    draft.bonusController.addListener(_onPackageInputChanged);
  }

  void _reloadRemotePackages(SpinConfig config) {
    setState(() {
      _isDirty = false;
      _hasRemoteConfigUpdate = false;
      _syncPackagesFromConfig(config);
    });
  }

  void _syncPackagesFromConfig(SpinConfig config) {
    _isSyncingConfig = true;
    try {
      _lastSyncedConfig = config;
      for (final d in _packageDrafts) {
        d.dispose();
      }
      _packageDrafts
        ..clear()
        ..addAll(
          config.packageTicketBonus.entries.map((entry) {
            final draft = _PackageBonusDraft(
              name: entry.key,
              bonus: entry.value,
            );
            _attachPackageListeners(draft);
            return draft;
          }),
        );
    } finally {
      _isSyncingConfig = false;
    }
  }

  Future<void> _importRegistrations(
    SpinAdminProvider provider,
    RegistrationParseResult parsed,
  ) async {
    if (parsed.rows.isEmpty) return;
    try {
      final res = await provider.importRegistrations(
        parsed.rows,
        replaceAll: _replaceAll,
      );
      if (!mounted) return;
      _importController.clear();
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminImportSuccess(
          res.importedCount,
          res.updatedCount,
          res.totalRegistrationsCount,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _savePackageBonuses(SpinAdminProvider provider) async {
    final map = <String, int>{};
    for (final draft in _packageDrafts) {
      final key = draft.nameController.text.trim();
      final val = int.tryParse(draft.bonusController.text.trim());
      if (key.isEmpty || val == null || val < 0 || val > 50) {
        showSpinAdminFeedback(
          context,
          AppStrings.spinAdminPackageValidation,
          isError: true,
        );
        return;
      }
      map[key] = val;
    }

    try {
      final updated = await provider.updateConfig({'packageTicketBonus': map});
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _hasRemoteConfigUpdate = false;
        _syncPackagesFromConfig(updated);
      });
      showSpinAdminFeedback(context, AppStrings.spinAdminPackageSaved);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _openCodeEditor(
    SpinAdminProvider provider, {
    SpinTicketCode? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TicketCodeDialog(provider: provider, existing: existing),
    );
  }

  Future<void> _toggleTicketCodeActive(
    SpinAdminProvider provider,
    SpinTicketCode code,
    bool active,
  ) async {
    try {
      await provider.upsertTicketCode({
        'id': code.id,
        'code': code.code,
        'label': code.label,
        'rewardTickets': code.rewardTickets,
        'maxTotalUses': code.maxTotalUses,
        'maxUsesPerUser': code.maxUsesPerUser,
        'active': active,
        'startsAt': code.startsAt?.toUtc().toIso8601String(),
        'endsAt': code.endsAt?.toUtc().toIso8601String(),
      });
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _openStandQrDialog(SpinTicketCode code) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _StandQrModalDialog(eventId: widget.eventId, ticketCode: code),
    );
  }

  Future<void> _scanAttendeeQr(UserProvider? userProvider) async {
    final barcode = await Navigator.of(context).push<Barcode?>(
      CupertinoPageRoute(
        builder: (_) =>
            const QRScanContent(msg: AppStrings.spinAdminScanAttendeeMsg),
      ),
    );
    final scannedUid = barcode?.code?.trim();
    if (!mounted || scannedUid == null || scannedUid.isEmpty) return;

    UserCompetitor? found;
    if (userProvider != null) {
      for (final item in userProvider.attendees) {
        if (item.uuid == scannedUid) {
          found = item;
          break;
        }
      }
      found ??= await userProvider.getUserInfo(scannedUid);
    }

    if (!mounted) return;
    if (found == null) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminAttendeeNotFound,
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedAttendee = found;
    });
  }

  Future<void> _grantManualTickets(SpinAdminProvider provider) async {
    final attendee = _selectedAttendee;
    final reason = _grantReasonController.text.trim();
    if (attendee == null || reason.isEmpty) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminGrantValidation,
        isError: true,
      );
      return;
    }

    try {
      final result = await provider.grantTickets(
        targetUid: attendee.uuid,
        amount: _grantAmount,
        reason: reason,
      );
      if (!mounted) return;
      _grantReasonController.clear();
      setState(() {
        _selectedAttendee = null;
        _grantAmount = 1;
      });
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminGrantSuccess(
          result.ticketsAwarded,
          result.ticketsAfter,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<SpinAdminProvider>();
    final userProvider = maybeProvider<UserProvider>(context);
    final parsed = parseRegistrationInput(_importController.text);
    final maxManualGrant = max(
      1,
      min(10, adminProvider.config?.maxManualGrantPerAction ?? 5),
    );
    final safeGrantAmount = _grantAmount.clamp(1, maxManualGrant);

    final query = _attendeeSearchController.text.trim().toLowerCase();
    final attendees = userProvider?.attendees ?? const <UserCompetitor>[];
    final filteredAttendees = attendees
        .where((a) {
          if (query.isEmpty) return true;
          return a.name.toLowerCase().contains(query) ||
              a.profession.toLowerCase().contains(query) ||
              a.uuid.toLowerCase().contains(query);
        })
        .take(5)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminImportTag,
                tagColor: AppStyles.spinAdminTagColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _importController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminImportTag,
                        hintText: AppStrings.spinAdminImportHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_importController.text.trim().isNotEmpty) ...[
                      Text(
                        AppStrings.spinAdminImportPreview(
                          parsed.rows.length,
                          parsed.skippedCount,
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      if (parsed.packageCounts.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final entry in parsed.packageCounts.entries)
                              SpinAdminBadge(
                                text: '${entry.key}: ${entry.value}',
                                color: AppStyles.colorCardYellowOpaque,
                              ),
                          ],
                        ),
                      ],
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        AppStrings.spinAdminImportReplaceAll,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      value: _replaceAll,
                      onChanged: (val) => setState(() => _replaceAll = val),
                    ),
                    ChunkyButton(
                      label: AppStrings.spinAdminImportAction,
                      color: AppStyles.colorBaseYellow,
                      expand: true,
                      minHeight: 44,
                      onPressed:
                          (adminProvider.isSubmitting || parsed.rows.isEmpty)
                          ? null
                          : () => _importRegistrations(adminProvider, parsed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminPackageBonusTag,
                tagColor: AppStyles.activitiesTreasureTagColor,
                angleDegrees: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasRemoteConfigUpdate &&
                        adminProvider.config != null) ...[
                      SpinAdminRemoteConfigBanner(
                        onReload: () =>
                            _reloadRemotePackages(adminProvider.config!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (var i = 0; i < _packageDrafts.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _packageDrafts[i].nameController,
                              decoration: spinAdminInputDecoration(
                                labelText: AppStrings.spinAdminPackageNameHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _packageDrafts[i].bonusController,
                              keyboardType: TextInputType.number,
                              decoration: spinAdminInputDecoration(
                                labelText: AppStrings.spinAdminPackageBonusHint,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isDirty = true;
                                final removed = _packageDrafts.removeAt(i);
                                removed.dispose();
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppStyles.spinAdminDangerColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ChunkyButton(
                            label: AppStrings.spinAdminAddPackageBonus,
                            color: AppStyles.spinAdminTagColor,
                            minHeight: 40,
                            fontSize: 12,
                            onPressed: () {
                              final draft = _PackageBonusDraft(
                                name: '',
                                bonus: 1,
                              );
                              _attachPackageListeners(draft);
                              setState(() {
                                _isDirty = true;
                                _packageDrafts.add(draft);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChunkyButton(
                            label: AppStrings.spinAdminSavePackageBonus,
                            color: AppStyles.colorBaseYellow,
                            minHeight: 40,
                            fontSize: 12,
                            onPressed: adminProvider.isSubmitting
                                ? null
                                : () => _savePackageBonuses(adminProvider),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminStandCodesTag,
                tagColor: AppStyles.colorBaseYellow,
                angleDegrees: -1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChunkyButton(
                      label: AppStrings.spinAdminNewStandCode,
                      color: AppStyles.colorBaseYellow,
                      expand: true,
                      minHeight: 42,
                      onPressed: adminProvider.isSubmitting
                          ? null
                          : () => _openCodeEditor(adminProvider),
                    ),
                    const SizedBox(height: 12),
                    if (adminProvider.ticketCodes.isEmpty)
                      const Text(
                        AppStrings.spinAdminNoStandCodes,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      )
                    else
                      for (final code in adminProvider.ticketCodes) ...[
                        _TicketCodeRow(
                          ticketCode: code,
                          busy: adminProvider.isSubmitting,
                          onToggleActive: (active) => _toggleTicketCodeActive(
                            adminProvider,
                            code,
                            active,
                          ),
                          onEdit: () =>
                              _openCodeEditor(adminProvider, existing: code),
                          onViewQr: () => _openStandQrDialog(code),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SpinAdminSectionCard(
                tag: AppStrings.spinAdminManualGrantTag,
                tagColor: AppStyles.spinWarnColor,
                angleDegrees: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _attendeeSearchController,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminSearchAttendee,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChunkyButton(
                      label: AppStrings.spinAdminScanAttendeeQr,
                      color: AppStyles.spinAdminTagColor,
                      expand: true,
                      minHeight: 42,
                      fontSize: 12,
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 16,
                        color: AppStyles.fontColor,
                      ),
                      onPressed: () => _scanAttendeeQr(userProvider),
                    ),
                    if (filteredAttendees.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final attendee in filteredAttendees)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedAttendee = attendee),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedAttendee?.uuid == attendee.uuid
                                    ? AppStyles.spinAdminSelectedTileColor
                                    : AppStyles.gamesBackgroundColor,
                                border: Border.all(
                                  color: AppStyles.borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      attendee.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppStyles.fontColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      attendee.profession,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppStyles.fontSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (_selectedAttendee != null) ...[
                      const SizedBox(height: 8),
                      InputChip(
                        label: Text(
                          '${AppStrings.spinAdminSelectedAttendee}: ${_selectedAttendee!.name}',
                        ),
                        onDeleted: () =>
                            setState(() => _selectedAttendee = null),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      AppStrings.spinAdminGrantAmountLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var n = 1; n <= maxManualGrant; n++)
                          ChoiceChip(
                            label: Text(AppStrings.spinAdminTicketDeltaChip(n)),
                            selected: safeGrantAmount == n,
                            selectedColor: AppStyles.colorBaseYellow,
                            onSelected: (_) => setState(() => _grantAmount = n),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _grantReasonController,
                      maxLines: 2,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminGrantReasonLabel,
                        hintText: AppStrings.spinAdminGrantReasonHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ChunkyButton(
                      label: AppStrings.spinAdminGrantAction,
                      color: AppStyles.activitiesTreasureTagColor,
                      expand: true,
                      minHeight: 44,
                      onPressed: adminProvider.isSubmitting
                          ? null
                          : () => _grantManualTickets(adminProvider),
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
}

class _TicketCodeRow extends StatelessWidget {
  final SpinTicketCode ticketCode;
  final bool busy;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onViewQr;

  const _TicketCodeRow({
    required this.ticketCode,
    required this.busy,
    required this.onToggleActive,
    required this.onEdit,
    required this.onViewQr,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.gamesBackgroundColor,
      radius: 14,
      shadowOffset: 2,
      borderWidth: 2,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketCode.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SpinAdminBadge(
                          text: ticketCode.code,
                          color: AppStyles.cardColor,
                        ),
                        SpinAdminBadge(
                          text: AppStrings.spinReward(ticketCode.rewardTickets),
                          color: AppStyles.activitiesTreasureTagColor,
                        ),
                        SpinAdminBadge(
                          text: AppStrings.spinAdminCodeUses(
                            ticketCode.usedCount,
                            ticketCode.maxTotalUses,
                          ),
                          color: AppStyles.spinAdminTagColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: ticketCode.active,
                onChanged: busy ? null : onToggleActive,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChunkyButton(
                label: AppStrings.commonWordEdit,
                color: AppStyles.spinAdminTagColor,
                minHeight: 36,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onPressed: busy ? null : onEdit,
              ),
              ChunkyButton(
                label: AppStrings.spinAdminViewQr,
                color: AppStyles.colorBaseYellow,
                minHeight: 36,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                icon: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: AppStyles.fontColor,
                ),
                onPressed: onViewQr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketCodeDialog extends StatefulWidget {
  final SpinAdminProvider provider;
  final SpinTicketCode? existing;

  const _TicketCodeDialog({required this.provider, this.existing});

  @override
  State<_TicketCodeDialog> createState() => _TicketCodeDialogState();
}

class _TicketCodeDialogState extends State<_TicketCodeDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _codeController;
  late final TextEditingController _rewardController;
  late final TextEditingController _maxUsesController;
  late final TextEditingController _maxPerUserController;

  late bool _active;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _labelController = TextEditingController(text: c?.label ?? '');
    _codeController = TextEditingController(text: c?.code ?? '');
    _rewardController = TextEditingController(
      text: (c?.rewardTickets ?? 1).toString(),
    );
    _maxUsesController = TextEditingController(
      text: (c?.maxTotalUses ?? 100).toString(),
    );
    _maxPerUserController = TextEditingController(
      text: (c?.maxUsesPerUser ?? 1).toString(),
    );
    _active = c?.active ?? true;
    _startsAt = c?.startsAt;
    _endsAt = c?.endsAt;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _codeController.dispose();
    _rewardController.dispose();
    _maxUsesController.dispose();
    _maxPerUserController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _labelController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final reward = int.tryParse(_rewardController.text.trim());
    final maxTotalUses = int.tryParse(_maxUsesController.text.trim());
    final maxPerUser = int.tryParse(_maxPerUserController.text.trim());

    final codeValid = RegExp(r'^[A-Z0-9_-]{3,32}$').hasMatch(code);
    final datesInvalid =
        _startsAt != null && _endsAt != null && !_endsAt!.isAfter(_startsAt!);

    if (label.isEmpty ||
        !codeValid ||
        reward == null ||
        reward < 1 ||
        reward > 20 ||
        maxTotalUses == null ||
        maxTotalUses < 1 ||
        maxTotalUses > 100000 ||
        maxPerUser == null ||
        maxPerUser < 1 ||
        maxPerUser > 10 ||
        datesInvalid) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminCodeValidation,
        isError: true,
      );
      return;
    }

    final codeData = <String, dynamic>{
      if (_isEditing) 'id': widget.existing!.id,
      'code': code,
      'label': label,
      'rewardTickets': reward,
      'maxTotalUses': maxTotalUses,
      'maxUsesPerUser': maxPerUser,
      'active': _active,
      'startsAt': _startsAt?.toUtc().toIso8601String(),
      'endsAt': _endsAt?.toUtc().toIso8601String(),
    };

    setState(() => _saving = true);
    try {
      await widget.provider.upsertTicketCode(codeData);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSpinAdminFeedback(context, AppStrings.spinAdminCodeSaved);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: HardShadowBox(
          color: AppStyles.cardColor,
          radius: 20,
          shadowOffset: 5,
          borderWidth: 2.5,
          padding: const EdgeInsets.all(16),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing
                        ? AppStrings.spinAdminEditStandCode
                        : AppStrings.spinAdminNewStandCode,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _labelController,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminCodeLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminCodeValue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rewardController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminCodeReward,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxUsesController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminCodeMaxUses,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _maxPerUserController,
                    keyboardType: TextInputType.number,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminCodeMaxPerUser,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SpinAdminDateTimeTile(
                    label: AppStrings.spinAdminMissionStartsAt,
                    value: _startsAt,
                    onChanged: (dt) => setState(() => _startsAt = dt),
                  ),
                  const SizedBox(height: 8),
                  SpinAdminDateTimeTile(
                    label: AppStrings.spinAdminMissionEndsAt,
                    value: _endsAt,
                    onChanged: (dt) => setState(() => _endsAt = dt),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      AppStrings.spinAdminPrizeActive,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    value: _active,
                    onChanged: (val) => setState(() => _active = val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          label: AppStrings.commonWordCancel,
                          color: AppStyles.cardColor,
                          minHeight: 42,
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          label: AppStrings.commonWordSave,
                          color: AppStyles.colorBaseYellow,
                          minHeight: 42,
                          onPressed: _saving ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StandQrModalDialog extends StatefulWidget {
  final String eventId;
  final SpinTicketCode ticketCode;

  const _StandQrModalDialog({required this.eventId, required this.ticketCode});

  @override
  State<_StandQrModalDialog> createState() => _StandQrModalDialogState();
}

class _StandQrModalDialogState extends State<_StandQrModalDialog> {
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareQr() async {
    setState(() => _sharing = true);
    final payload = widget.ticketCode.qrPayload(widget.eventId);
    final shareText = AppStrings.spinAdminQrShareText(
      widget.ticketCode.label,
      widget.ticketCode.code,
    );

    try {
      final renderObject = _qrKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final image = await renderObject.toImage(pixelRatio: 3);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData?.buffer.asUint8List();
        if (bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/stand-qr-${widget.ticketCode.code}.png';
          await File(filePath).writeAsBytes(bytes);
          await SharePlus.instance.share(
            ShareParams(text: shareText, files: [XFile(filePath)]),
          );
          return;
        }
      }
      await SharePlus.instance.share(ShareParams(text: '$shareText\n$payload'));
    } catch (_) {
      await SharePlus.instance.share(ShareParams(text: '$shareText\n$payload'));
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.ticketCode.qrPayload(widget.eventId);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: HardShadowBox(
          color: AppStyles.cardColor,
          radius: 22,
          shadowOffset: 5,
          borderWidth: 2.5,
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppStyles.cardColor,
                      border: Border.all(
                        color: AppStyles.borderColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.ticketCode.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.fontColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: QrImageView(
                            data: payload,
                            backgroundColor: AppStyles.cardColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          widget.ticketCode.code,
                          style: const TextStyle(
                            fontFamily: AppStyles.monospaceFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: AppStyles.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ChunkyButton(
                  label: AppStrings.spinAdminShareQr,
                  color: AppStyles.colorBaseYellow,
                  expand: true,
                  minHeight: 44,
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: AppStyles.fontColor,
                  ),
                  onPressed: _sharing ? null : _shareQr,
                ),
                const SizedBox(height: 8),
                ChunkyButton(
                  label: AppStrings.commonWordClose,
                  color: AppStyles.cardColor,
                  expand: true,
                  minHeight: 42,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
