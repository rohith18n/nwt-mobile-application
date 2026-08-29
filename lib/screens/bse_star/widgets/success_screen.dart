import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class SuccessScreen extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const SuccessScreen({
    super.key,
    this.title = 'SUCCESS',
    this.message = 'You are ready to invest',
    this.buttonText = 'EXPLORE MUTUAL FUNDS',
    required this.onButtonPressed,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Play animation once when screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section with title and animation
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success title
                    AppText(
                      widget.title,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.white,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    
                    // Lottie animation
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/lottie/successful.json',
                        controller: _controller,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Success message
                    AppText(
                      widget.message,
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.white,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Bottom button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: widget.buttonText,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: widget.onButtonPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
