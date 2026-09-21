import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double minScale;
  final Duration duration;
  final bool enableHaptics;

  const PressableScale({
    super.key,
    required this.child,
    this.onPressed,
    this.minScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptics = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? widget.minScale : 1.0,
        duration: widget.duration,
        curve: _isPressed ? Curves.easeOutQuad : Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
