import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tab 3: Missions & live trivia editor with 1-tap active switch.
class SpinAdminMissionsTab extends StatelessWidget {
  final String eventId;

  const SpinAdminMissionsTab({super.key, required this.eventId});

  Future<void> _toggleActive(
    BuildContext context,
    SpinAdminProvider provider,
    SpinMission mission,
    bool active,
  ) async {
    try {
      await provider.toggleMissionActive(mission, active);
    } catch (e) {
      if (!context.mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    SpinAdminProvider provider, {
    SpinMission? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MissionEditorDialog(
        provider: provider,
        existing: existing,
        suggestedOrder: provider.missions.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpinAdminProvider>();
    final missions = provider.missions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChunkyButton(
                  label: AppStrings.spinAdminNewMission,
                  color: AppStyles.colorBaseYellow,
                  expand: true,
                  minHeight: 46,
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _openEditor(context, provider),
                ),
                const SizedBox(height: 14),
                if (missions.isEmpty)
                  const HardShadowBox(
                    color: AppStyles.cardColor,
                    radius: 16,
                    shadowOffset: 3,
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppStrings.spinAdminNoMissions,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                  )
                else
                  for (final mission in missions) ...[
                    _MissionAdminCard(
                      mission: mission,
                      busy: provider.isSubmitting,
                      onToggleActive: (next) =>
                          _toggleActive(context, provider, mission, next),
                      onEdit: () =>
                          _openEditor(context, provider, existing: mission),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _missionTypeLabel(SpinMissionType type) => switch (type) {
  SpinMissionType.trivia => AppStrings.spinAdminMissionTypeTrivia,
  SpinMissionType.profileComplete => AppStrings.spinAdminMissionTypeProfile,
  SpinMissionType.workshopRegister => AppStrings.spinAdminMissionTypeWorkshop,
  SpinMissionType.askSpeaker => AppStrings.spinAdminMissionTypeAskSpeaker,
  SpinMissionType.rateTalk => AppStrings.spinAdminMissionTypeRateTalk,
};

class _MissionAdminCard extends StatelessWidget {
  final SpinMission mission;
  final bool busy;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;

  const _MissionAdminCard({
    required this.mission,
    required this.busy,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleLabel = _buildWindowLabel(mission.startsAt, mission.endsAt);

    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 18,
      shadowOffset: 4,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SpinAdminBadge(
                          text: _missionTypeLabel(mission.type),
                          color: mission.isTrivia
                              ? AppStyles.colorBaseYellow
                              : AppStyles.spinAdminTagColor,
                        ),
                        SpinAdminBadge(
                          text: AppStrings.spinReward(mission.rewardTickets),
                          color: AppStyles.activitiesTreasureTagColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mission.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: mission.active,
                onChanged: busy ? null : onToggleActive,
              ),
            ],
          ),
          if (mission.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              mission.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ],
          if (scheduleLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              scheduleLabel,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppStyles.colorBaseBlue,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ChunkyButton(
              label: AppStrings.commonWordEdit,
              color: AppStyles.spinAdminTagColor,
              minHeight: 38,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              onPressed: busy ? null : onEdit,
            ),
          ),
        ],
      ),
    );
  }

  String? _buildWindowLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return null;
    final startStr = start != null
        ? dateFormat.format(start.toLocal())
        : AppStrings.spinAdminNotConfigured;
    final endStr = end != null
        ? dateFormat.format(end.toLocal())
        : AppStrings.spinAdminNotConfigured;
    return '$startStr → $endStr';
  }
}

class _MissionEditorDialog extends StatefulWidget {
  final SpinAdminProvider provider;
  final SpinMission? existing;
  final int suggestedOrder;

  const _MissionEditorDialog({
    required this.provider,
    this.existing,
    required this.suggestedOrder,
  });

  @override
  State<_MissionEditorDialog> createState() => _MissionEditorDialogState();
}

class _MissionEditorDialogState extends State<_MissionEditorDialog> {
  late SpinMissionType _type;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rewardController;
  late final TextEditingController _targetCountController;
  late final TextEditingController _maxCompletionsController;
  late final TextEditingController _actionLabelController;
  late final TextEditingController _orderController;
  late final TextEditingController _minAboutMeController;
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  final List<TextEditingController> _optionControllers = [];

  int _correctOptionIndex = 0;
  bool _updateTriviaSecret = false;
  late bool _active;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _type = m?.type ?? SpinMissionType.trivia;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _rewardController = TextEditingController(
      text: (m?.rewardTickets ?? 1).toString(),
    );
    _targetCountController = TextEditingController(
      text: (m?.targetCount ?? 1).toString(),
    );
    _maxCompletionsController = TextEditingController(
      text: (m?.maxCompletionsPerUser ?? 1).toString(),
    );
    _actionLabelController = TextEditingController(text: m?.actionLabel ?? '');
    _orderController = TextEditingController(
      text: (m?.order ?? widget.suggestedOrder).toString(),
    );
    _minAboutMeController = TextEditingController(
      text: (m?.minAboutMeLength ?? 200).toString(),
    );
    _questionController = TextEditingController(text: m?.triviaQuestion ?? '');
    _explanationController = TextEditingController();

    final initialOptions = (m != null && m.triviaOptions.length >= 2)
        ? m.triviaOptions
        : const ['', ''];
    for (final opt in initialOptions) {
      _optionControllers.add(TextEditingController(text: opt));
    }

    _active = m?.active ?? true;
    _startsAt = m?.startsAt;
    _endsAt = m?.endsAt;
    _updateTriviaSecret = !_isEditing;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _targetCountController.dispose();
    _maxCompletionsController.dispose();
    _actionLabelController.dispose();
    _orderController.dispose();
    _minAboutMeController.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 4) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      final removed = _optionControllers.removeAt(index);
      removed.dispose();
      if (_correctOptionIndex >= _optionControllers.length) {
        _correctOptionIndex = _optionControllers.length - 1;
      }
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final reward = int.tryParse(_rewardController.text.trim());
    final targetCount = int.tryParse(_targetCountController.text.trim());
    final maxCompletions = int.tryParse(_maxCompletionsController.text.trim());
    final order = int.tryParse(_orderController.text.trim());

    if (title.isEmpty ||
        reward == null ||
        reward < 1 ||
        reward > 20 ||
        targetCount == null ||
        targetCount < 1 ||
        targetCount > 50 ||
        maxCompletions == null ||
        maxCompletions < 1 ||
        maxCompletions > 20 ||
        order == null ||
        order < 0 ||
        order > 1000) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminMissionValidation,
        isError: true,
      );
      return;
    }

    if (_startsAt != null && _endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminMissionValidation,
        isError: true,
      );
      return;
    }

    final configMap = <String, dynamic>{};
    int? correctIndex;
    String? explanation;

    if (_type == SpinMissionType.profileComplete) {
      final minAbout = int.tryParse(_minAboutMeController.text.trim());
      if (minAbout == null || minAbout < 0 || minAbout > 1000) {
        showSpinAdminFeedback(
          context,
          AppStrings.spinAdminMissionValidation,
          isError: true,
        );
        return;
      }
      configMap['minAboutMeLength'] = minAbout;
    } else if (_type == SpinMissionType.trivia) {
      final question = _questionController.text.trim();
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(growable: false);
      if (question.isEmpty || options.length < 2 || options.length > 4) {
        showSpinAdminFeedback(
          context,
          AppStrings.spinAdminMissionValidation,
          isError: true,
        );
        return;
      }
      configMap['question'] = question;
      configMap['options'] = options;

      if (!_isEditing || _updateTriviaSecret) {
        correctIndex = _correctOptionIndex.clamp(0, options.length - 1);
        explanation = _explanationController.text.trim();
      }
    }

    final actionLabel = _actionLabelController.text.trim();
    final missionData = <String, dynamic>{
      if (_isEditing) 'id': widget.existing!.id,
      'type': _type.value,
      'title': title,
      'description': _descriptionController.text.trim(),
      'rewardTickets': reward,
      'targetCount': targetCount,
      'maxCompletionsPerUser': maxCompletions,
      'actionLabel': actionLabel.isEmpty ? null : actionLabel,
      'active': _active,
      'order': order,
      'startsAt': _startsAt?.toUtc().toIso8601String(),
      'endsAt': _endsAt?.toUtc().toIso8601String(),
      'config': configMap,
    };

    setState(() => _saving = true);
    try {
      await widget.provider.upsertMission(
        missionData,
        correctOptionIndex: correctIndex,
        explanation: explanation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSpinAdminFeedback(context, AppStrings.spinAdminMissionSaved);
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
    final isTrivia = _type == SpinMissionType.trivia;
    final showSecretFields = isTrivia && (!_isEditing || _updateTriviaSecret);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                        ? AppStrings.spinAdminEditMission
                        : AppStrings.spinAdminNewMission,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.spinAdminMissionType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final type in SpinMissionType.values)
                        ChoiceChip(
                          label: Text(_missionTypeLabel(type)),
                          selected: _type == type,
                          selectedColor: AppStyles.colorBaseYellow,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminMissionTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminMissionDescription,
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
                            labelText: AppStrings.spinAdminMissionReward,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _targetCountController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminMissionTargetCount,
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
                          controller: _maxCompletionsController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText:
                                AppStrings.spinAdminMissionMaxCompletions,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _orderController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminMissionOrder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _actionLabelController,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminMissionActionLabel,
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
                  if (_type == SpinMissionType.profileComplete) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _minAboutMeController,
                      keyboardType: TextInputType.number,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminMissionMinAboutMe,
                      ),
                    ),
                  ],
                  if (isTrivia) ...[
                    const Divider(height: 22),
                    TextField(
                      controller: _questionController,
                      maxLines: 2,
                      decoration: spinAdminInputDecoration(
                        labelText: AppStrings.spinAdminTriviaQuestion,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            AppStrings.spinAdminTriviaOptions,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.fontColor,
                            ),
                          ),
                        ),
                        if (_optionControllers.length < 4)
                          ChunkyButton(
                            label: AppStrings.spinAdminTriviaAddOption,
                            color: AppStyles.spinAdminTagColor,
                            minHeight: 34,
                            fontSize: 11.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            onPressed: _addOption,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_isEditing)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _updateTriviaSecret,
                        title: const Text(
                          AppStrings.spinAdminTriviaUpdateSecret,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.fontColor,
                          ),
                        ),
                        onChanged: (val) =>
                            setState(() => _updateTriviaSecret = val ?? false),
                      ),
                    RadioGroup<int>(
                      groupValue: _correctOptionIndex,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _correctOptionIndex = val);
                        }
                      },
                      child: Column(
                        children: [
                          for (var i = 0; i < _optionControllers.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  if (showSecretFields) Radio<int>(value: i),
                                  Expanded(
                                    child: TextField(
                                      controller: _optionControllers[i],
                                      decoration: spinAdminInputDecoration(
                                        labelText:
                                            AppStrings.spinAdminTriviaOptionHint(
                                              i,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (_optionControllers.length > 2)
                                    IconButton(
                                      onPressed: () => _removeOption(i),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppStyles.spinAdminDangerColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showSecretFields) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: _explanationController,
                        maxLines: 2,
                        decoration: spinAdminInputDecoration(
                          labelText: AppStrings.spinAdminTriviaExplanation,
                        ),
                      ),
                    ],
                  ],
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
