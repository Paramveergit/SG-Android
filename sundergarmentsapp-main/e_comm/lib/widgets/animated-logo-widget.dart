import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedLogoWidget extends StatefulWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> opacityAnimation;

  const AnimatedLogoWidget({
    Key? key,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.opacityAnimation,
  }) : super(key: key);

  @override
  State<AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.scaleAnimation,
        widget.rotationAnimation,
        widget.opacityAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.scaleAnimation.value,
          child: Transform.rotate(
            angle: widget.rotationAnimation.value * 2 * 3.14159,
            child: Opacity(
              opacity: widget.opacityAnimation.value.clamp(0.0, 1.0),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.textOnBrand,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/SG_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
