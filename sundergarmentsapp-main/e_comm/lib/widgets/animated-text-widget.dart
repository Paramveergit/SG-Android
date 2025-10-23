import 'package:flutter/material.dart';
import 'package:e_comm/utils/app-constant.dart';

class AnimatedTextWidget extends StatefulWidget {
  final String text;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final bool startAnimation;
  final TextStyle? textStyle;

  const AnimatedTextWidget({
    Key? key,
    required this.text,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.startAnimation,
    this.textStyle,
  }) : super(key: key);

  @override
  State<AnimatedTextWidget> createState() => _AnimatedTextWidgetState();
}

class _AnimatedTextWidgetState extends State<AnimatedTextWidget>
    with TickerProviderStateMixin {
  late AnimationController _characterController;
  late Animation<double> _characterAnimation;
  int _currentCharacterIndex = 0;

  @override
  void initState() {
    super.initState();
    _characterController = AnimationController(
      duration: Duration(milliseconds: 100 * widget.text.length),
      vsync: this,
    );

    _characterAnimation = Tween<double>(
      begin: 0.0,
      end: widget.text.length.toDouble(),
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.easeInOut,
    ));

    _characterAnimation.addListener(() {
      setState(() {
        _currentCharacterIndex = _characterAnimation.value.toInt();
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !oldWidget.startAnimation) {
      _characterController.forward();
    }
  }

  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.scaleAnimation,
        widget.opacityAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.scaleAnimation.value,
          child: Opacity(
            opacity: widget.opacityAnimation.value.clamp(0.0, 1.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: List.generate(widget.text.length, (index) {
                  final isVisible = index < _currentCharacterIndex;
                  final isLastCharacter = index == _currentCharacterIndex - 1;
                  
                  return TextSpan(
                    text: widget.text[index],
                    style: (widget.textStyle ?? TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.appTextColor,
                      letterSpacing: 2.0,
                    )).copyWith(
                      color: isVisible 
                          ? AppConstant.appTextColor 
                          : AppConstant.appTextColor.withOpacity(0.3),
                      shadows: isVisible ? [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ] : null,
                      fontSize: isLastCharacter 
                          ? (widget.textStyle?.fontSize ?? 36) + 2
                          : widget.textStyle?.fontSize ?? 36,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
