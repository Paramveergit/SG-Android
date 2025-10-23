import 'package:flutter/material.dart';
import 'package:e_comm/utils/app-constant.dart';

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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstant.appTextColor,
                      AppConstant.appTextColor.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppConstant.appMainColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 0),
                      spreadRadius: 5,
                    ),
                  ],
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
