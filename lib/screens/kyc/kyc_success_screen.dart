import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/kyc/kyc_service.dart';
import 'package:nwt_app/services/kyc/kyc_state_helper.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

const String _logTag = 'KycSuccessScreen';

/// Poll every 5 minutes; stop when Validated or after max attempts (e.g. 24 = 2 hours).
const Duration kycPollInterval = Duration(minutes: 5);
const int kycMaxPollAttempts = 24;

class KycSuccessScreen extends StatefulWidget {
  const KycSuccessScreen({super.key});

  @override
  State<KycSuccessScreen> createState() => _KycSuccessScreenState();
}

class _KycSuccessScreenState extends State<KycSuccessScreen> {
  final KycService _kycService = KycService();
  final KycStateHelper _stateHelper = KycStateHelper();

  Timer? _pollTimer;
  int _pollAttempts = 0;
  bool _validated = false;

  @override
  void initState() {
    super.initState();
    _stateHelper.setSuccessScreenSeenAt();
    // Keep backend onboarding flow status aligned with KYC completion.
    AuthService().updateOnboardingProgress(
      flowType: OnboardingFlowType.completeKyc.apiValue,
      status: 'completed',
    );
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(kycPollInterval, _onPoll);
  }

  void _onPoll(Timer timer) {
    if (_pollAttempts >= kycMaxPollAttempts) {
      _pollTimer?.cancel();
      _pollTimer = null;
      AppLogger.info('KYC polling stopped: max attempts reached', tag: _logTag);
      return;
    }
    _pollAttempts++;
    _kycService.verifyPanStatus().then((result) {
      if (!mounted) return;
      if (result.isValidated) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _stateHelper.clearJourneyStartedAt();
        _stateHelper.setLastVerifiedStatus('Validated');
        setState(() => _validated = true);
        AppLogger.info('KYC validated via polling', tag: _logTag);
      }
    }).catchError((e) {
      AppLogger.warning('KYC poll error: $e', tag: _logTag);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  void _backToDashboard() {
    _pollTimer?.cancel();
    _pollTimer = null;
    Get.offAll(() => const Dashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCardBG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const AppText(
                'KYC submitted successfully',
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppText(
                _validated
                    ? 'Your KYC has been validated.'
                    : 'We will verify your details. You can check back later.',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Back to Dashboard',
                onPressed: _backToDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
