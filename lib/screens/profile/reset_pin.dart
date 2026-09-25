import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/widgets/common/pinput_peek.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:pinput/pinput.dart';

class ResetPin extends StatefulWidget {
  const ResetPin({super.key});

  @override
  State<ResetPin> createState() => _ResetPinState();
}

class _ResetPinState extends State<ResetPin> with PinPeekMixin {
  static const int _pinLength = 4;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    disposePeekMixin();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final pin = _pinController.text;
    if (pin.length != _pinLength) {
      setState(() => _errorMessage = 'Please enter a 4-digit PIN');
      return;
    }
    // TODO: Add reset pin logic
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF242424), width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.white, width: 1.5),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.white, width: 1.5),
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const AppText(
          'Reset Pin',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.primary,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 90),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Lottie.asset('assets/lottie/Reset Pin.json'),
                  ),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: AppText(
                    'Reset your 4-digit pin',
                    variant: AppTextVariant.headline4,
                    lineHeight: 1.5,
                    colorType: AppTextColorType.primary,
                    weight: AppTextWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Pinput.builder(
                    length: _pinLength,
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      onPinChanged(v);
                      setState(() {});
                    },
                    onCompleted: (_) => _handleConfirm(),
                    autofocus: false,
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
                              : obscuringCharacter;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: theme.width ?? 50,
                        height: theme.height ?? 50,
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
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AppText(
                      _errorMessage!,
                      colorType: AppTextColorType.error,
                      variant: AppTextVariant.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 20,
          right: 20,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            disabledBackgroundColor: Colors.white.withOpacity(0.5),
          ),
          onPressed:
              _pinController.text.length == _pinLength ? _handleConfirm : null,
          child: const AppText(
            'Confirm',
            variant: AppTextVariant.bodyLarge,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.tertiary,
          ),
        ),
      ),
    );
  }
}
