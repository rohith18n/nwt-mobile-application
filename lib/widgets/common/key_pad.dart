import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class KeyPad extends StatefulWidget {
  final Function(int) onKeyPressed;
  final VoidCallback onBackspace;

  const KeyPad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
  });

  @override
  State createState() => _KeyPadState();
}

class _KeyPadState extends State<KeyPad> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            KeyPadButton(text: 1, onPressed: () => widget.onKeyPressed(1)),
            KeyPadButton(text: 2, onPressed: () => widget.onKeyPressed(2)),
            KeyPadButton(text: 3, onPressed: () => widget.onKeyPressed(3)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            KeyPadButton(text: 4, onPressed: () => widget.onKeyPressed(4)),
            KeyPadButton(text: 5, onPressed: () => widget.onKeyPressed(5)),
            KeyPadButton(text: 6, onPressed: () => widget.onKeyPressed(6)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            KeyPadButton(text: 7, onPressed: () => widget.onKeyPressed(7)),
            KeyPadButton(text: 8, onPressed: () => widget.onKeyPressed(8)),
            KeyPadButton(text: 9, onPressed: () => widget.onKeyPressed(9)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            KeyPadButton(text: 0, isBlank: true, onPressed: () {}),
            KeyPadButton(text: 0, onPressed: () => widget.onKeyPressed(0)),
            KeyPadButton(
              text: 0,
              isBackSpace: true,
              onPressed: widget.onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class KeyPadButton extends StatefulWidget {
  final int text;
  final bool isBackSpace;
  final bool isBlank;
  final VoidCallback onPressed;

  const KeyPadButton({
    super.key,
    required this.text,
    this.isBackSpace = false,
    this.isBlank = false,
    required this.onPressed,
  });

  @override
  State<KeyPadButton> createState() => _KeyPadButtonState();
}

class _KeyPadButtonState extends State<KeyPadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine the button colors based on state
    final Color backgroundColor =
        widget.isBlank
            ? Colors.transparent
            : _isPressed
            ? isDarkMode
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.darkInputBackground.withValues(alpha: 0.85)
            : isDarkMode
            ? AppColors.darkInputBackground
            : AppColors.lightInputPrimaryBackground;

    // Determine the border color based on state
    final Color borderColor =
        widget.isBlank
            ? Colors.transparent
            : _isPressed
            ? isDarkMode
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.15)
            : isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05);

    return Expanded(
      child: GestureDetector(
        onTapDown:
            widget.isBlank
                ? null
                : (_) {
                  setState(() {
                    _isPressed = true;
                  });
                },
        onTapUp:
            widget.isBlank
                ? null
                : (_) {
                  setState(() {
                    _isPressed = false;
                  });
                  widget.onPressed();
                },
        onTapCancel:
            widget.isBlank
                ? null
                : () {
                  setState(() {
                    _isPressed = false;
                  });
                },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.fastLinearToSlowEaseIn,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child:
                widget.isBackSpace
                    ? AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.fastLinearToSlowEaseIn,
                      style: TextStyle(
                        color:
                            _isPressed
                                ? (isDarkMode ? Colors.white : Colors.white70)
                                : (isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                      ),
                      child: const Icon(Icons.backspace, size: 20),
                    )
                    : widget.isBlank
                    ? const SizedBox()
                    : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 900),
                      switchInCurve: Curves.fastLinearToSlowEaseIn,
                      switchOutCurve: Curves.fastLinearToSlowEaseIn,
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: AppText(
                        key: ValueKey<bool>(_isPressed),
                        widget.text.toString(),
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.semiBold,
                        colorType:
                            _isPressed
                                ? (isDarkMode
                                    ? AppTextColorType.tertiary
                                    : AppTextColorType.primary)
                                : (isDarkMode
                                    ? AppTextColorType.primary
                                    : AppTextColorType.tertiary),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
