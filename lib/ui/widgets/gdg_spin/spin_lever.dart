import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draggable, tappable, and keyboard-accessible lever on the side of the cabinet.
class SpinLever extends StatefulWidget {
  final double height;
  final bool canPull;
  final int tickets;
  final VoidCallback onPull;
  final VoidCallback onBlockedPull;

  const SpinLever({
    super.key,
    required this.height,
    required this.canPull,
    required this.tickets,
    required this.onPull,
    required this.onBlockedPull,
  });

  @override
  State<SpinLever> createState() => _SpinLeverState();
}

class _SpinLeverState extends State<SpinLever> with TickerProviderStateMixin {
  late final AnimationController _pullController;
  late final AnimationController _pulseController;
  double _dragDistance = 0;
  bool _dragging = false;
  bool _committing = false;
  int _jiggleCount = 0;

  @override
  void initState() {
    super.initState();
    _pullController = AnimationController(
      vsync: this,
      lowerBound: -0.1,
      upperBound: 1.0,
      value: 0.0,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant SpinLever oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canPull != widget.canPull) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (MediaQuery.disableAnimationsOf(context) ||
        !widget.canPull ||
        _dragging) {
      _pulseController.stop();
      _pulseController.value = 0;
      return;
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  void _jiggle() {
    setState(() => _jiggleCount++);
    widget.onBlockedPull();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.canPull || _committing) {
      _jiggle();
      return;
    }
    setState(() {
      _dragging = true;
      _dragDistance = 0;
    });
    _syncPulse();
    _pullController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging || !widget.canPull || _committing) return;
    _dragDistance += details.delta.dy;
    _pullController.value = (_dragDistance / 130).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _syncPulse();
    final velocity = details.primaryVelocity ?? 0;
    if (_pullController.value > 0.42 ||
        (velocity > 450 && _pullController.value > 0.1)) {
      _commitPull();
    } else {
      _springBack();
    }
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _syncPulse();
    _springBack();
  }

  void _springBack() {
    _pullController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _commitPull() async {
    if (_committing) return;
    _committing = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      if (reduced) {
        _pullController.value = 1.0;
        widget.onPull();
        _pullController.value = 0.0;
        return;
      }
      final ms = (40 + 150 * (1 - _pullController.value)).round();
      await _pullController.animateTo(
        1.0,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onPull();
      await _pullController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutBack,
      );
    } finally {
      _committing = false;
    }
  }

  void _pullFromTap() {
    if (!widget.canPull || _committing) {
      _jiggle();
      return;
    }
    _commitPull();
  }

  @override
  void dispose() {
    _pullController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final showPulse = widget.canPull && !_dragging && !reduced;

    final leverBody = AnimatedBuilder(
      animation: Listenable.merge([_pullController, _pulseController]),
      builder: (context, _) {
        final p = _pullController.value.clamp(-0.1, 1.0);
        final arrowOpacity = widget.canPull ? (1 - p * 4).clamp(0.0, 1.0) : 0.0;
        final armLength = widget.height < 170
            ? (widget.height * 0.45).clamp(48.0, 82.0)
            : 82.0;
        final chevronOffset = 30.0 * (armLength / 82.0);

        return SizedBox(
          width: 50,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Base plate
              Container(
                width: 32,
                height: 72,
                decoration: BoxDecoration(
                  color: AppStyles.cardColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: AppStyles.spinCabinetInnerShadowColor,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
              // Pivot dot
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppStyles.borderColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Downward help chevrons
              if (arrowOpacity > 0)
                Positioned(
                  top: widget.height / 2 + chevronOffset,
                  child: Opacity(
                    opacity: arrowOpacity,
                    child: const _HelpChevrons(),
                  ),
                ),
              // Rotating stick and knob
              Positioned(
                top: widget.height / 2 - armLength,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 1 / 240)
                    ..rotateX(-p * math.pi),
                  child: SizedBox(
                    width: 44,
                    height: armLength,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: armLength,
                            decoration: BoxDecoration(
                              color: AppStyles.spinLeverStickColor,
                              border: Border.all(
                                color: AppStyles.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -18 * (armLength / 82.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationX(p * math.pi),
                            child: _LeverKnob(
                              pulseValue: showPulse
                                  ? _pulseController.value
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final animatedLever = _jiggleCount > 0 && !reduced
        ? ShakeX(
            key: ValueKey('lever-jiggle-$_jiggleCount'),
            duration: const Duration(milliseconds: 400),
            child: leverBody,
          )
        : leverBody;

    return Semantics(
      button: true,
      enabled: widget.canPull,
      label: AppStrings.spinLeverSemantic,
      onTap: _pullFromTap,
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _pullFromTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          onVerticalDragCancel: _handleDragCancel,
          onTap: _pullFromTap,
          child: animatedLever,
        ),
      ),
    );
  }
}

class _LeverKnob extends StatelessWidget {
  final double? pulseValue;
  const _LeverKnob({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    final ringWidth = pulseValue == null
        ? 0.0
        : 5.0 * (0.5 - (pulseValue! - 0.5).abs()) * 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (ringWidth > 0)
          Container(
            width: 40 + ringWidth * 2,
            height: 40 + ringWidth * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppStyles.spinBezelColor,
                width: ringWidth,
              ),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.32, -0.4),
              colors: [AppStyles.onAccentColor, AppStyles.spinKnobColor],
              stops: [0.17, 0.18],
            ),
            border: Border.all(color: AppStyles.borderColor, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppStyles.spinCabinetInnerShadowColor,
                offset: Offset(3, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpChevrons extends StatelessWidget {
  const _HelpChevrons();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, -3.0 * i),
              child: const CustomPaint(
                size: Size(18, 11),
                painter: _ChevronPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppStyles.borderColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(2, 2)
      ..lineTo(size.width / 2, size.height - 2)
      ..lineTo(size.width - 2, 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
