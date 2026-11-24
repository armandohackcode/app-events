import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Tactile pop-brutalist button that presses into its hard shadow.
class ChunkyButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;
  final double minHeight;
  final double minTapHeight;
  final double radius;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.minHeight = 48,
    this.minTapHeight = 0,
    this.radius = 14,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const double _shadow = 3;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final offset = _pressed ? _shadow : 0.0;
    final shadowOffset = _pressed || !enabled ? 0.0 : _shadow;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(offset, offset, 0),
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        minWidth: widget.expand ? double.infinity : 0,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        border: Border.all(color: AppStyles.borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                  color: AppStyles.borderColor,
                  offset: Offset(shadowOffset, shadowOffset),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
          ),
        ],
      ),
    );

    final tapTarget = widget.minTapHeight > widget.minHeight
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minTapHeight),
            child: Center(widthFactor: widget.expand ? null : 1, child: button),
          )
        : button;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: tapTarget,
      ),
    );
  }
}
