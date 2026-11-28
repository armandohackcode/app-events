import 'dart:async';
import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/dashed_line.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Auto-dismissing ticket card popup shown when earning a ticket or tapping the balance pill.
class SpinTicketPopup extends StatefulWidget {
  final int tickets;
  final String? serial;

  const SpinTicketPopup({super.key, required this.tickets, this.serial});

  static Future<void> showWon(
    BuildContext context, {
    required int tickets,
    required String serial,
  }) => _show(context, tickets: tickets, serial: serial);

  static Future<void> showBalance(
    BuildContext context, {
    required int tickets,
  }) => _show(context, tickets: tickets);

  static Future<void> _show(
    BuildContext context, {
    required int tickets,
    String? serial,
  }) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.commonWordClose,
      barrierColor: AppStyles.spinScrimColor,
      transitionDuration: Duration(milliseconds: reduced ? 0 : 180),
      pageBuilder: (dialogContext, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: SpinTicketPopup(tickets: tickets, serial: serial),
        ),
      ),
    );
  }

  @override
  State<SpinTicketPopup> createState() => _SpinTicketPopupState();
}

class _SpinTicketPopupState extends State<SpinTicketPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;
  late final Animation<double> _opacity;
  Timer? _timer;

  bool get _isWonMode => widget.serial != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    const curve = Cubic(0.34, 1.56, 0.64, 1);
    _scale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    _rotation = Tween<double>(
      begin: -14 * math.pi / 180,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final delayMs = _isWonMode ? 2800 : 2600;
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headline = _isWonMode
        ? AppStrings.spinTicketWon
        : AppStrings.spinTicketHave(widget.tickets);
    final subtitle = _isWonMode
        ? AppStrings.spinTicketWonSub
        : AppStrings.spinTicketBalanceSub;
    final footerLabel = _isWonMode
        ? AppStrings.spinTicketNumber
        : AppStrings.spinTicketBalance;
    final footerValue = _isWonMode ? widget.serial! : widget.tickets.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        ),
        child: Transform.rotate(
          angle: -4 * math.pi / 180,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HardShadowBox(
                  color: AppStyles.spinBezelColor,
                  radius: 18,
                  shadowOffset: 7,
                  borderWidth: 2.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        decoration: const BoxDecoration(
                          color: AppStyles.borderColor,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.spinTicketHeader,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.2,
                              height: 1,
                              color: AppStyles.spinBezelColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Column(
                          children: [
                            Text(
                              headline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppStyles.fontColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: AppStyles.fontColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              AppStrings.spinTicketBrand,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: AppStyles.fontSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: DashedLine(strokeWidth: 2.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                footerLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppStyles.fontSecondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  footerValue,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: AppStyles.monospaceFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppStyles.fontColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  bottom: 34,
                  child: _TicketNotch(isLeft: true),
                ),
                const Positioned(
                  right: 0,
                  bottom: 34,
                  child: _TicketNotch(isLeft: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketNotch extends StatelessWidget {
  final bool isLeft;
  const _TicketNotch({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: 0.5,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppStyles.spinScrimColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppStyles.borderColor, width: 2.5),
          ),
        ),
      ),
    );
  }
}
