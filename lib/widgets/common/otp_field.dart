import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/pinput_peek.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:pinput/pinput.dart';

class OTPField extends StatefulWidget {
  final bool enableAutofill;
  final Function(String) onOTPFilled;
  final Function(bool)? onLoading;
  final bool isLoading;
  final String? errorMessage;
  final int length;
  final Function()? onResendOTP;
  final bool canResendOTP;
  final int timeLeft;

  final bool obscureText;
  final String obscuringCharacter;

  const OTPField({
    super.key,
    this.enableAutofill = true,
    required this.onOTPFilled,
    this.onLoading,
    this.isLoading = false,
    this.errorMessage,
    this.length = 6,
    this.onResendOTP,
    this.canResendOTP = false,
    this.timeLeft = 0,
    this.obscureText = false,
    this.obscuringCharacter = '*',
  });

  @override
  State<OTPField> createState() => _OTPFieldState();
}

class _OTPFieldState extends State<OTPField> with CodeAutoFill, PinPeekMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.enableAutofill) {
      listenForCode();
    }
    // Auto-focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      _controller.text = code!;
      widget.onOTPFilled(code!);
    }
  }

  @override
  void dispose() {
    disposePeekMixin();
    _controller.dispose();
    _focusNode.dispose();
    if (widget.enableAutofill) {
      cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: TextStyle(
        fontSize: 18,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkInputBackground
                : AppColors.lightInputPrimaryBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkInputBorder
                  : AppColors.lightInputPrimaryBorder,
          width: 1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor, width: 1.5),
      borderRadius: BorderRadius.circular(15),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: primaryColor.withOpacity(0.1),
        border: Border.all(color: primaryColor, width: 1.5),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child:
              widget.obscureText
                  ? Pinput.builder(
                    length: widget.length,
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    autofillHints:
                        widget.enableAutofill
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                    enabled: !widget.isLoading,
                    onCompleted: widget.onOTPFilled,
                    onChanged: (value) {
                      onPinChanged(value);
                    },
                    builder: (context, state) {
                      final theme = switch (state.type) {
                        PinItemStateType.focused => focusedPinTheme,
                        PinItemStateType.submitted => submittedPinTheme,
                        _ => defaultPinTheme,
                      };

                      final bool isPeeking =
                          state.value.isNotEmpty && state.index == peekIndex;
                      final display =
                          state.value.isEmpty
                              ? ''
                              : isPeeking
                              ? state.value
                              : widget.obscuringCharacter;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: theme.width ?? 50,
                        height: theme.height ?? 60,
                        decoration: theme.decoration,
                        alignment: Alignment.center,
                        child:
                            display.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                  display,
                                  style:
                                      theme.textStyle ??
                                      defaultPinTheme.textStyle,
                                ),
                      );
                    },
                  )
                  : Pinput(
                    length: widget.length,
                    controller: _controller,
                    focusNode: _focusNode,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    obscureText: false,
                    enabled: !widget.isLoading,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    autofillHints:
                        widget.enableAutofill
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                    onCompleted: widget.onOTPFilled,
                    onChanged: (value) {},
                    showCursor: true,
                    cursor: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          width: 1.5,
                          height: 29,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
        ),
        if (widget.onResendOTP != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't get a code?",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap:
                    (widget.canResendOTP && !widget.isLoading)
                        ? widget.onResendOTP
                        : null,
                child: Text(
                  widget.canResendOTP
                      ? "Resend Code"
                      : "Resend in ${widget.timeLeft} s",
                  style: TextStyle(
                    color:
                        widget.canResendOTP
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
