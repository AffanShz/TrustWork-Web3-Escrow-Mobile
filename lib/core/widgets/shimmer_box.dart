import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                TrustWorkTheme.surface,
                TrustWorkTheme.card,
                TrustWorkTheme.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonProjectCard extends StatelessWidget {
  const SkeletonProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TrustWorkTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrustWorkTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 70, height: 22, borderRadius: 6),
              ShimmerBox(width: 90, height: 20, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerBox(width: 180, height: 18, borderRadius: 4),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 80, height: 16, borderRadius: 4),
              ShimmerBox(width: 16, height: 16, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
