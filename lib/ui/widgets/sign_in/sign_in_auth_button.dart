import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tactile social sign-in button with optional hard bottom shadow.
class SignInAuthButton extends StatefulWidget {
  final String label;
  final String iconAssetPath;
  final Color backgroundColor;
  final Color foregroundColor;
  final double shadowHeight;
  final bool tintIcon;
  final VoidCallback? onPressed;

  const SignInAuthButton({
    super.key,
    required this.label,
    required this.iconAssetPath,
    required this.backgroundColor,
    required this.foregroundColor,
    this.shadowHeight = 0,
    this.tintIcon = false,
    required this.onPressed,
  });

  @override
  State<SignInAuthButton> createState() => _SignInAuthButtonState();
}

class _SignInAuthButtonState extends State<SignInAuthButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressTravel = widget.shadowHeight > 0 ? widget.shadowHeight : 1.5;
    final translateY = _pressed ? pressTravel : 0.0;
    final activeShadow = _pressed || !enabled ? 0.0 : widget.shadowHeight;

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
        child: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: _pressed && widget.shadowHeight == 0 ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: Matrix4.translationValues(0, translateY, 0),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(color: AppStyles.borderColor, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: activeShadow > 0
                  ? [
                      BoxShadow(
                        color: AppStyles.borderColor,
                        offset: Offset(0, activeShadow),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  widget.iconAssetPath,
                  width: 22,
                  height: 22,
                  colorFilter: widget.tintIcon
                      ? ColorFilter.mode(
                          widget.foregroundColor,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: widget.foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
