import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Tab 5: Stand prize QR/code verification, redemption, revocation, and live wins list.
class SpinAdminRedeemTab extends StatefulWidget {
  final String eventId;

  const SpinAdminRedeemTab({super.key, required this.eventId});

  @override
  State<SpinAdminRedeemTab> createState() => _SpinAdminRedeemTabState();
}

class _SpinAdminRedeemTabState extends State<SpinAdminRedeemTab> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode(SpinAdminProvider provider, [String? input]) async {
    final code = (input ?? _codeController.text).trim();
    if (code.isEmpty) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinCodeInvalidFormat,
        isError: true,
      );
      return;
    }

    try {
      await provider.lookupWinByCode(code);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _scanPrizeQr(SpinAdminProvider provider) async {
    final barcode = await Navigator.of(context).push<Barcode?>(
      CupertinoPageRoute(
        builder: (_) =>
            const QRScanContent(msg: AppStrings.spinAdminRedeemScanMsg),
      ),
    );
    final scanned = barcode?.code?.trim();
    if (!mounted || scanned == null || scanned.isEmpty) return;
    _codeController.text = scanned;
    await _lookupCode(provider, scanned);
  }

  Future<void> _confirmRedeem(SpinAdminProvider provider, SpinWin win) async {
    try {
      await provider.redeemWin(win.id);
      if (!mounted) return;
      showSpinAdminFeedback(context, AppStrings.spinAdminRedeemedSuccess);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  Future<void> _openRevokeDialog(
    SpinAdminProvider provider,
    SpinWin win,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RevokeWinDialog(provider: provider, win: win),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpinAdminProvider>();
    final lookup = provider.lookupResult;

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
                  label: AppStrings.spinAdminRedeemScanQr,
                  color: AppStyles.colorBaseYellow,
                  expand: true,
                  minHeight: 48,
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: AppStyles.fontColor,
                  ),
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _scanPrizeQr(provider),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _lookupCode(provider),
                        decoration: spinAdminInputDecoration(
                          labelText: AppStrings.spinAdminRedeemCodeLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChunkyButton(
                      label: AppStrings.spinAdminRedeemSearch,
                      color: AppStyles.spinAdminTagColor,
                      minHeight: 46,
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _lookupCode(provider),
                    ),
                  ],
                ),
                if (lookup != null) ...[
                  const SizedBox(height: 14),
                  _WinReviewCard(
                    lookup: lookup,
                    busy: provider.isSubmitting,
                    onClear: provider.clearLookup,
                    onRedeem: () => _confirmRedeem(provider, lookup.win),
                    onRevoke: () => _openRevokeDialog(provider, lookup.win),
                  ),
                ],
                const SizedBox(height: 18),
                SpinAdminSectionCard(
                  tag: AppStrings.spinAdminWinsListTag,
                  tagColor: AppStyles.spinAdminTagColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text(AppStrings.spinAdminFilterAll),
                            selected: provider.winFilter == null,
                            selectedColor: AppStyles.colorBaseYellow,
                            onSelected: (_) => provider.setWinFilter(null),
                          ),
                          for (final status in SpinWinStatus.values)
                            ChoiceChip(
                              label: Text(_filterLabel(status)),
                              selected: provider.winFilter == status,
                              selectedColor: AppStyles.colorBaseYellow,
                              onSelected: (_) => provider.setWinFilter(status),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (provider.wins.isEmpty)
                        const Text(
                          AppStrings.spinAdminNoWins,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppStyles.fontSecondaryColor,
                          ),
                        )
                      else
                        for (final win in provider.wins) ...[
                          _WinListRow(
                            win: win,
                            selected: lookup?.win.id == win.id,
                            onTap: () => provider.selectWinForReview(win),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _filterLabel(SpinWinStatus status) => switch (status) {
    SpinWinStatus.pending => AppStrings.spinAdminFilterPending,
    SpinWinStatus.redeemed => AppStrings.spinAdminFilterRedeemed,
    SpinWinStatus.revoked => AppStrings.spinAdminFilterRevoked,
  };
}

class _WinReviewCard extends StatelessWidget {
  final AdminLookupWinResult lookup;
  final bool busy;
  final VoidCallback onClear;
  final VoidCallback onRedeem;
  final VoidCallback onRevoke;

  const _WinReviewCard({
    required this.lookup,
    required this.busy,
    required this.onClear,
    required this.onRedeem,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final win = lookup.win;
    final (statusLabel, statusColor) = spinWinStatusVisuals(win.status);
    final winnerName = win.winnerName.trim().isNotEmpty
        ? win.winnerName.trim()
        : (lookup.player?.displayName.trim().isNotEmpty == true
              ? lookup.player!.displayName.trim()
              : win.uid);

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
              _WinnerAvatar(photoUrl: win.winnerPhotoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    if (win.wonAt != null)
                      Text(
                        dateFormat.format(win.wonAt!.toLocal()),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppStyles.gamesBackgroundColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SpinPrizeThumbnail(
                  symbol: win.prizeSymbol,
                  imageUrl: win.prizeImageUrl,
                  size: 40,
                  fallbackSize: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      win.prizeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    Text(
                      win.code,
                      style: const TextStyle(
                        fontFamily: AppStyles.monospaceFontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SpinAdminBadge(text: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          if (win.status == SpinWinStatus.pending)
            Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    label: AppStrings.spinAdminConfirmRedeem,
                    color: AppStyles.spinAdminSuccessColor,
                    minHeight: 44,
                    onPressed: busy ? null : onRedeem,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChunkyButton(
                    label: AppStrings.spinAdminRevokeAction,
                    color: AppStyles.spinAdminDangerSurfaceColor,
                    minHeight: 44,
                    onPressed: busy ? null : onRevoke,
                  ),
                ),
              ],
            )
          else if (win.status == SpinWinStatus.redeemed)
            HardShadowBox(
              color: AppStyles.spinAdminDangerSurfaceColor,
              radius: 14,
              shadowOffset: 2,
              borderWidth: 2,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppStyles.spinAdminDangerColor,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppStrings.spinAdminAlreadyRedeemedBanner,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.spinAdminDangerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (win.redeemedByName != null || win.redeemedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.spinAdminRedeemedBy(
                        win.redeemedByName ?? AppStrings.commonWordAnonymous,
                        win.redeemedAt != null
                            ? dateFormat.format(win.redeemedAt!.toLocal())
                            : AppStrings.spinAdminNotConfigured,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            HardShadowBox(
              color: AppStyles.spinStatusRevokedColor,
              radius: 14,
              shadowOffset: 2,
              borderWidth: 2,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.spinRedeemQrRevoked,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  if (win.revokeReason != null &&
                      win.revokeReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.spinAdminRevokeDetails(
                        win.revokeReason!,
                        win.returnedToStock,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontColor,
                      ),
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

class _WinnerAvatar extends StatelessWidget {
  final String photoUrl;

  const _WinnerAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppStyles.gamesBackgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.borderColor, width: 2),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppStyles.fontSecondaryColor,
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: trimmed,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const Icon(Icons.person_rounded),
      ),
    );
  }
}

class _WinListRow extends StatelessWidget {
  final SpinWin win;
  final bool selected;
  final VoidCallback onTap;

  const _WinListRow({
    required this.win,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = spinWinStatusVisuals(win.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppStyles.spinAdminSelectedTileColor
              : AppStyles.gamesBackgroundColor,
          border: Border.all(
            color: selected ? AppStyles.colorBaseBlue : AppStyles.borderColor,
            width: selected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SpinPrizeThumbnail(
              symbol: win.prizeSymbol,
              imageUrl: win.prizeImageUrl,
              size: 32,
              fallbackSize: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    win.prizeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  Text(
                    '${win.winnerName.isNotEmpty ? win.winnerName : win.uid} · ${win.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SpinAdminBadge(text: statusLabel, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _RevokeWinDialog extends StatefulWidget {
  final SpinAdminProvider provider;
  final SpinWin win;

  const _RevokeWinDialog({required this.provider, required this.win});

  @override
  State<_RevokeWinDialog> createState() => _RevokeWinDialogState();
}

class _RevokeWinDialogState extends State<_RevokeWinDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _returnToStock = true;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showSpinAdminFeedback(
        context,
        AppStrings.spinAdminGrantValidation,
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.provider.revokeWin(
        winId: widget.win.id,
        returnToStock: _returnToStock,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSpinAdminFeedback(context, AppStrings.spinAdminRevokedSuccess);
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
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
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    AppStrings.spinAdminRevokeConfirmTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.spinAdminRevokeConfirmBody,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _returnToStock,
                    title: const Text(
                      AppStrings.spinAdminRevokeReturnToStock,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _returnToStock = val ?? true),
                  ),
                  TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: spinAdminInputDecoration(
                      labelText: AppStrings.spinAdminRevokeReasonLabel,
                      hintText: AppStrings.spinAdminRevokeReasonHint,
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
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          label: AppStrings.spinAdminRevokeAction,
                          color: AppStyles.spinAdminDangerSurfaceColor,
                          minHeight: 42,
                          onPressed: _submitting ? null : _submit,
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
