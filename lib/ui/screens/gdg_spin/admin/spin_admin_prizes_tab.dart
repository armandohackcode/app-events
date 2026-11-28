import 'dart:io';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Backend-accepted reel symbols for prizes (excludes lemon, mysteryBox, wild).
const List<SpinSymbol> _kSelectablePrizeSymbols = [
  SpinSymbol.cherries,
  SpinSymbol.bell,
  SpinSymbol.bar,
  SpinSymbol.star,
  SpinSymbol.diamond,
  SpinSymbol.seven,
];

/// Tab 2: Prize catalog CRUD, stock adjustments, and manual wave release.
class SpinAdminPrizesTab extends StatelessWidget {
  final String eventId;

  const SpinAdminPrizesTab({super.key, required this.eventId});

  Future<void> _openPrizeDialog(
    BuildContext context,
    SpinAdminProvider provider, {
    SpinPrize? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PrizeEditorDialog(
        provider: provider,
        existing: existing,
        suggestedOrder: provider.prizes.length,
      ),
    );
  }

  Future<void> _openAdjustStockDialog(
    BuildContext context,
    SpinAdminProvider provider,
    SpinPrize prize,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AdjustStockDialog(provider: provider, prize: prize),
    );
  }

  Future<void> _releaseOneUnit(
    BuildContext context,
    SpinAdminProvider provider,
    SpinPrize prize,
  ) async {
    try {
      await provider.adjustPrizeStock(
        prizeId: prize.id,
        delta: 0,
        releasedDelta: 1,
        reason: AppStrings.spinAdminReleaseOneReason,
      );
      if (!context.mounted) return;
      showSpinAdminFeedback(context, AppStrings.spinAdminStockReleased);
    } catch (e) {
      if (!context.mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpinAdminProvider>();
    final prizes = provider.prizes;
    final manualWaves =
        provider.config?.pacingMode == SpinPacingMode.manualWaves;

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
                  label: AppStrings.spinAdminNewPrize,
                  color: AppStyles.colorBaseYellow,
                  expand: true,
                  minHeight: 46,
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _openPrizeDialog(context, provider),
                ),
                const SizedBox(height: 14),
                if (prizes.isEmpty)
                  const HardShadowBox(
                    color: AppStyles.cardColor,
                    radius: 16,
                    shadowOffset: 3,
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppStrings.spinAdminNoPrizes,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                  )
                else
                  for (final prize in prizes) ...[
                    _PrizeAdminCard(
                      prize: prize,
                      showManualRelease:
                          manualWaves &&
                          prize.releasedStock < prize.initialStock,
                      busy: provider.isSubmitting,
                      onEdit: () =>
                          _openPrizeDialog(context, provider, existing: prize),
                      onAdjustStock: () =>
                          _openAdjustStockDialog(context, provider, prize),
                      onReleaseOne: () =>
                          _releaseOneUnit(context, provider, prize),
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

class _PrizeAdminCard extends StatelessWidget {
  final SpinPrize prize;
  final bool showManualRelease;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;
  final VoidCallback onReleaseOne;

  const _PrizeAdminCard({
    required this.prize,
    required this.showManualRelease,
    required this.busy,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onReleaseOne,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = prize.initialStock > 0
        ? (prize.remainingStock / prize.initialStock).clamp(0.0, 1.0)
        : 0.0;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppStyles.gamesBackgroundColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SpinPrizeThumbnail(
                  symbol: prize.symbol,
                  imageUrl: prize.imageUrl,
                  size: 44,
                  fallbackSize: 32,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prize.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SpinAdminBadge(
                          text: spinRarityLabel(prize.rarity),
                          color: spinRarityColor(prize.rarity),
                        ),
                        SpinAdminBadge(
                          text: prize.active
                              ? AppStrings.spinAdminPrizeActive
                              : AppStrings.spinAdminPrizeInactive,
                          color: prize.active
                              ? AppStyles.spinAdminActiveStatusColor
                              : AppStyles.spinAdminBadgeInactiveColor,
                        ),
                        if (prize.unlockAt != null)
                          SpinAdminBadge(
                            text: AppStrings.spinAdminPrizeUnlockBadge(
                              dateFormat.format(prize.unlockAt!.toLocal()),
                            ),
                            color: AppStyles.spinTeaseColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.spinRemaining(
                  prize.remainingStock,
                  prize.initialStock,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              Text(
                '${prize.remainingStock}/${prize.initialStock}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: prize.isSoldOut
                  ? AppStyles.spinAdminDangerColor
                  : AppStyles.colorBaseGreen,
              backgroundColor: AppStyles.spinAdminProgressTrackColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.spinAdminPrizeMetrics(
              prize.awardedCount,
              prize.redeemedCount,
              prize.releasedStock,
              prize.initialStock,
            ),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChunkyButton(
                label: AppStrings.commonWordEdit,
                color: AppStyles.spinAdminTagColor,
                minHeight: 38,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                onPressed: busy ? null : onEdit,
              ),
              ChunkyButton(
                label: AppStrings.spinAdminAdjustStock,
                color: AppStyles.colorBaseYellow,
                minHeight: 38,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                onPressed: busy ? null : onAdjustStock,
              ),
              if (showManualRelease)
                ChunkyButton(
                  label: AppStrings.spinAdminReleaseOne,
                  color: AppStyles.activitiesTreasureTagColor,
                  minHeight: 38,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  onPressed: busy ? null : onReleaseOne,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrizeEditorDialog extends StatefulWidget {
  final SpinAdminProvider provider;
  final SpinPrize? existing;
  final int suggestedOrder;

  const _PrizeEditorDialog({
    required this.provider,
    this.existing,
    required this.suggestedOrder,
  });

  @override
  State<_PrizeEditorDialog> createState() => _PrizeEditorDialogState();
}

class _PrizeEditorDialogState extends State<_PrizeEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _initialStockController;
  late final TextEditingController _maxPerUserController;
  late final TextEditingController _weightController;
  late final TextEditingController _orderController;

  late PrizeRarity _rarity;
  late SpinSymbol _symbol;
  late bool _active;
  DateTime? _unlockAt;
  String? _pickedImagePath;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _initialStockController = TextEditingController(
      text: (p?.initialStock ?? 5).toString(),
    );
    _maxPerUserController = TextEditingController(
      text: (p?.maxPerUser ?? 1).toString(),
    );
    _weightController = TextEditingController(
      text: (p?.weight ?? 1.0).toString(),
    );
    _orderController = TextEditingController(
      text: (p?.order ?? widget.suggestedOrder).toString(),
    );
    _rarity = p?.rarity ?? PrizeRarity.common;
    _symbol = p != null && _kSelectablePrizeSymbols.contains(p.symbol)
        ? p.symbol
        : SpinSymbol.cherries;
    _active = p?.active ?? true;
    _unlockAt = p?.unlockAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _initialStockController.dispose();
    _maxPerUserController.dispose();
    _weightController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final maxPerUser = int.tryParse(_maxPerUserController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final order = int.tryParse(_orderController.text.trim());
    final initialStock = _isEditing
        ? null
        : int.tryParse(_initialStockController.text.trim());

    if (name.isEmpty ||
        maxPerUser == null ||
        maxPerUser < 0 ||
        maxPerUser > 100 ||
        weight == null ||
        weight <= 0 ||
        weight > 100 ||
        order == null ||
        order < 0 ||
        order > 1000 ||
        (!_isEditing && (initialStock == null || initialStock < 0))) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminPrizeValidation,
        isError: true,
      );
      return;
    }

    final rawImageUrl = _imageUrlController.text.trim();
    final payload = <String, dynamic>{
      if (_isEditing) 'id': widget.existing!.id,
      'name': name,
      'description': _descController.text.trim(),
      'symbol': _symbol.value,
      'imageUrl': rawImageUrl.isEmpty ? null : rawImageUrl,
      'rarity': _rarity.value,
      // IMPORTANT: initialStock is sent ONLY when creating a new prize.
      // Backend enforces STOCK_IMMUTABLE_ON_UPDATE on edits.
      if (!_isEditing) 'initialStock': initialStock,
      'maxPerUser': maxPerUser,
      'weight': weight,
      'unlockAt': _unlockAt?.toUtc().toIso8601String(),
      'active': _active,
      'order': order,
    };

    setState(() => _saving = true);
    try {
      await widget.provider.upsertPrize(payload, imagePath: _pickedImagePath);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSpinAdminFeedback(context, AppStrings.spinAdminPrizeSaved);
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
        constraints: const BoxConstraints(maxWidth: 440),
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
                        ? AppStrings.spinAdminEditPrize
                        : AppStrings.spinAdminNewPrize,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminPrizeName,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminPrizeDescription,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    AppStrings.spinAdminPrizeRarity,
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
                      for (final rarity in PrizeRarity.values)
                        ChoiceChip(
                          label: Text(spinRarityLabel(rarity)),
                          selected: _rarity == rarity,
                          selectedColor: spinRarityColor(rarity),
                          onSelected: (_) => setState(() => _rarity = rarity),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    AppStrings.spinAdminPrizeSymbol,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sym in _kSelectablePrizeSymbols)
                        InkWell(
                          onTap: () => setState(() => _symbol = sym),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _symbol == sym
                                  ? AppStyles.spinAdminSelectedTileColor
                                  : AppStyles.gamesBackgroundColor,
                              border: Border.all(
                                color: _symbol == sym
                                    ? AppStyles.colorBaseBlue
                                    : AppStyles.borderColor,
                                width: _symbol == sym ? 2.5 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SpinSymbolArt(symbol: sym, size: 32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_pickedImagePath != null && !kIsWeb) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImagePath!),
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          label: _pickedImagePath == null
                              ? AppStrings.spinAdminPrizePickImage
                              : AppStrings.spinAdminPrizeChangeImage,
                          color: AppStyles.spinAdminTagColor,
                          minHeight: 38,
                          fontSize: 12,
                          onPressed: _saving ? null : _pickImage,
                        ),
                      ),
                      if (_pickedImagePath != null ||
                          _imageUrlController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ChunkyButton(
                          label: AppStrings.spinAdminPrizeClearImage,
                          color: AppStyles.cardColor,
                          minHeight: 38,
                          fontSize: 12,
                          onPressed: () {
                            setState(() {
                              _pickedImagePath = null;
                              _imageUrlController.clear();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminPrizeImageUrl,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!_isEditing) ...[
                        Expanded(
                          child: TextField(
                            controller: _initialStockController,
                            keyboardType: TextInputType.number,
                            decoration: spinAdminInputDecoration(
                              labelText: AppStrings.spinAdminPrizeInitialStock,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _maxPerUserController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminPrizeMaxPerUser,
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
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminPrizeWeight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _orderController,
                          keyboardType: TextInputType.number,
                          decoration: spinAdminInputDecoration(
                            labelText: AppStrings.spinAdminPrizeOrder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SpinAdminDateTimeTile(
                    label: AppStrings.spinAdminPrizeUnlockAt,
                    value: _unlockAt,
                    onChanged: (dt) => setState(() => _unlockAt = dt),
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

class _AdjustStockDialog extends StatefulWidget {
  final SpinAdminProvider provider;
  final SpinPrize prize;

  const _AdjustStockDialog({required this.provider, required this.prize});

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  final TextEditingController _deltaController = TextEditingController(
    text: '1',
  );
  final TextEditingController _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _deltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _setDelta(int delta) {
    _deltaController.text = delta.toString();
  }

  Future<void> _submit() async {
    final delta = int.tryParse(_deltaController.text.trim());
    final reason = _reasonController.text.trim();
    if (delta == null || delta == 0 || reason.isEmpty) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminStockValidation,
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.provider.adjustPrizeStock(
        prizeId: widget.prize.id,
        delta: delta,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSpinAdminFeedback(context, AppStrings.spinAdminStockAdjusted);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: HardShadowBox(
          color: AppStyles.cardColor,
          radius: 20,
          shadowOffset: 5,
          borderWidth: 2.5,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.spinAdminAdjustStock,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.fontColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.prize.name} (${widget.prize.remainingStock}/${widget.prize.initialStock})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final preset in const [-1, 1, 5, 10])
                      ActionChip(
                        label: Text(preset > 0 ? '+$preset' : '$preset'),
                        onPressed: () => _setDelta(preset),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deltaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: spinAdminInputDecoration(
                    labelText: AppStrings.spinAdminStockDeltaLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: spinAdminInputDecoration(
                    labelText: AppStrings.spinAdminStockReasonLabel,
                    hintText: AppStrings.spinAdminStockReasonHint,
                  ),
                ),
                const SizedBox(height: 14),
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
    );
  }
}
