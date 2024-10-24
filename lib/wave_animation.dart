import 'package:flutter/material.dart';

class VoiceWaveAnimation extends StatefulWidget {
  final List<BarParams> bars;

  VoiceWaveAnimation({required this.bars});

  @override
  _VoiceWaveAnimationState createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.bars
          .map((bar) => AnimatedBar(
        animation: _controller,
        index: bar.index,
        barHeightMultiplier: bar.heightMultiplier,
        spacing: bar.spacing,
      ))
          .toList(),
    );
  }
}

class AnimatedBar extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final double barHeightMultiplier;
  final double spacing;

  AnimatedBar({
    required this.animation,
    required this.index,
    required this.barHeightMultiplier,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(
              index * 0.2,
              1.0,
              curve: Curves.easeInOut,
            ),
          ),
        ),
        child: Container(
          width: 10.0,
          height: 30.0 * barHeightMultiplier,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }
}

class BarParams {
  final int index;
  final double heightMultiplier;
  final double spacing;

  BarParams({
    required this.index,
    required this.heightMultiplier,
    this.spacing = 16.0,
  });
}
