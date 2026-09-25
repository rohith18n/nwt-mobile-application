import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/aa_branding.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/connections/finarkein_journey_webview.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/aa_consent.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_integration_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// Finarkein-only screen to revoke consent (delink account).
/// Guard at entry: if user is not Finarkein AA, pops immediately.
class ConsentRevokeScreen extends StatefulWidget {
  const ConsentRevokeScreen({super.key});

  @override
  State<ConsentRevokeScreen> createState() => _ConsentRevokeScreenState();
}

class _ConsentRevokeScreenState extends State<ConsentRevokeScreen> {
  final UserController _userController = Get.find<UserController>();
  final FinarkeinConsentsService _consentsService = FinarkeinConsentsService();

  List<AaConsent>? _consents;
  bool _loadingConsents = true;
  bool _revokeInProgress = false;
  String? _errorMessage;
  bool _showRetryBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAndLoad());
  }

  void _guardAndLoad() {
    final user = _userController.userData;
    if (user?.isFinarkeinAa != true) {
      Navigator.of(context).pop();
      return;
    }
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    if (!mounted) return;
    AppLogger.info('Loading consents for delink screen', tag: 'CONSENT_REVOKE');
    setState(() {
      _loadingConsents = true;
      _errorMessage = null;
      _showRetryBack = false;
    });
    try {
      final list = await _consentsService.getConsents(forceRefresh: true);
      if (!mounted) return;
      AppLogger.info(
        'Consents loaded: ${list.length} total, ${list.where((c) => c.isActive).length} active',
        tag: 'CONSENT_REVOKE',
      );
      setState(() {
        _consents = list;
        _loadingConsents = false;
      });
    } catch (e, st) {
      AppLogger.error(
        'Error loading consents',
        error: e,
        stackTrace: st,
        tag: 'CONSENT_REVOKE',
      );
      if (!mounted) return;
      setState(() {
        _consents = [];
        _loadingConsents = false;
        _errorMessage = 'Check your connection and try again.';
        _showRetryBack = true;
      });
    }
  }

  String _getMobileNumber() {
    final user = _userController.userData;
    final p = user?.phonenumber?.trim();
    if (p != null && p.isNotEmpty) return p;
    final s = user?.secondaryphonenumber?.trim();
    if (s != null && s.isNotEmpty) return s;
    return '';
  }

  List<String> _getConsentHandles() {
    if (_consents == null || _consents!.isEmpty) return [];
    final handles = <String>[];
    for (final c in _consents!) {
      if (!c.isActive) continue;
      final h = c.consentHandle?.trim();
      if (h != null && h.isNotEmpty) handles.add(h);
    }
    return handles;
  }

  Future<void> _startRevoke() async {
    final handles = _getConsentHandles();
    final mobile = _getMobileNumber();
    AppLogger.info(
      'Starting revoke process: ${handles.length} consent handles',
      tag: 'CONSENT_REVOKE',
    );
    if (handles.isEmpty) {
      AppLogger.info('No linked accounts to delink', tag: 'CONSENT_REVOKE');
      setState(() {
        _errorMessage = 'No linked accounts to delink.';
        _showRetryBack = false;
      });
      return;
    }
    if (mobile.isEmpty) {
      AppLogger.info(
        'Mobile number is required but not found',
        tag: 'CONSENT_REVOKE',
      );
      setState(() {
        _errorMessage = 'Mobile number is required to delink.';
        _showRetryBack = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _revokeInProgress = true;
      _errorMessage = null;
      _showRetryBack = false;
    });

    RevokeResult result;
    try {
      AppLogger.info(
        'Calling revokeConsent API with mobile=$mobile',
        tag: 'CONSENT_REVOKE',
      );
      result = await _consentsService.revokeConsent(handles, mobile);
      AppLogger.info(
        'RevokeConsent API response: success=${result.isSuccess} requestId=${result.requestId}',
        tag: 'CONSENT_REVOKE',
      );
    } catch (e, st) {
      AppLogger.error(
        'Error calling revokeConsent API',
        error: e,
        stackTrace: st,
        tag: 'CONSENT_REVOKE',
      );
      if (!mounted) return;
      setState(() {
        _revokeInProgress = false;
        _errorMessage = 'Check your connection and try again.';
        _showRetryBack = true;
      });
      return;
    }

    if (!result.isSuccess) {
      AppLogger.info(
        'Revoke failed: result.isSuccess=false',
        tag: 'CONSENT_REVOKE',
      );
      if (!mounted) return;
      setState(() {
        _revokeInProgress = false;
        _errorMessage = 'Unable to start delink. Please try again.';
        _showRetryBack = true;
      });
      return;
    }

    final redirectUrl = result.redirectUrl;
    AppLogger.info(
      'Revoke initiated successfully, redirectUrl=${redirectUrl != null ? "present" : "null"}',
      tag: 'CONSENT_REVOKE',
    );

    // Clear all Finarkein cache/storage so UI shows unlinked state and next consent is fresh.
    AppLogger.info(
      'Clearing Finarkein cache and storage',
      tag: 'CONSENT_REVOKE',
    );
    _clearFinarkeinCacheAndStorage();

    if (redirectUrl != null && redirectUrl.trim().isNotEmpty) {
      AppLogger.info(
        'Opening delink webview with redirectUrl',
        tag: 'CONSENT_REVOKE',
      );
      if (!mounted) return;
      final completedWithRedirect = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (context) => FinarkeinJourneyWebView(
                journeyUrl: redirectUrl.trim(),
                redirectUrlToDetect: FinarkeinIntegrationService.redirectUrl,
                onRedirectDetected: () {},
              ),
        ),
      );
      if (!mounted) return;
      AppLogger.info(
        'Webview closed: completedWithRedirect=$completedWithRedirect',
        tag: 'CONSENT_REVOKE',
      );

      // Set pending flag so Dashboard can trigger data fetch (even if cancelled)
      AppLogger.info(
        'Setting pendingRevokeRequestIdFromUi=${result.requestId} for Dashboard to process',
        tag: 'CONSENT_REVOKE',
      );
      FinarkeinConsentsService.pendingRevokeRequestIdFromUi = result.requestId;

      // Also set pendingDelinkRefresh in DashboardRefreshController to ensure full refresh
      if (Get.isRegistered<DashboardRefreshController>()) {
        DashboardRefreshController.to.pendingDelinkRefresh = true;
      }

      AppLogger.info('Navigating to Dashboard', tag: 'CONSENT_REVOKE');
      Get.offAll(() => StackedNavbar(selectedIdx: 0));
      if (completedWithRedirect != true) {
        AppLogger.info(
          'User cancelled delink flow, but will still trigger data fetch',
          tag: 'CONSENT_REVOKE',
        );
        SnackbarHelper.showInfo(
          title: 'Delink cancelled',
          message: 'You cancelled the delink flow.',
          position: SnackPosition.TOP,
        );
      }
      return;
    }

    // No webview: set pending flag so Dashboard can trigger data fetch
    AppLogger.info(
      'No webview flow - setting pendingRevokeRequestIdFromUi=${result.requestId}',
      tag: 'CONSENT_REVOKE',
    );
    if (!mounted) return;
    FinarkeinConsentsService.pendingRevokeRequestIdFromUi = result.requestId;

    // Also set pendingDelinkRefresh in DashboardRefreshController to ensure full refresh
    if (Get.isRegistered<DashboardRefreshController>()) {
      DashboardRefreshController.to.pendingDelinkRefresh = true;
    }

    AppLogger.info('Navigating to Dashboard', tag: 'CONSENT_REVOKE');
    Get.offAll(() => StackedNavbar(selectedIdx: 0));
  }

  /// Clears all Finarkein cache and in-memory storage so dashboard shows unlinked state and Link Now is usable.
  void _clearFinarkeinCacheAndStorage() {
    if (Get.isRegistered<FinarkeinDataStore>()) {
      Get.find<FinarkeinDataStore>().clear();
    }
    _consentsService.clearConsentsCache();
    FinarkeinConsentsService.resetDataResultCircuit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                CupertinoIcons.back,
                color: AppColors.darkTextPrimary,
                size: 24.sp,
              ),
            ),
            AppText(
              'Revoke consent',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            SizedBox(width: 24.sp),
          ],
        ),
      ),
      body: SafeArea(
        child:
            _loadingConsents
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final empty = _consents == null || !_consents!.any((c) => c.isActive);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          if (empty) ...[
            AppText(
              'No linked accounts',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            AppButton(
              text: 'Back',
              onPressed: () => Navigator.pop(context),
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isFullWidth: true,
            ),
          ] else ...[
            AppText(
              'You have ${_consents?.where((c) => c.isActive).length ?? 0} active ${(_consents?.where((c) => c.isActive).length ?? 0) == 1 ? "account" : "accounts"} linked via ${AaBranding.providerName}. After revoking, your linked account data will no longer be available in the app.',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.regular,
              colorType: AppTextColorType.primary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ...(_consents
                    ?.where((c) => c.isActive)
                    .map((c) => _buildConsentItem(c)) ??
                []),
            SizedBox(height: 32.h),
            if (_errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText(
                  _errorMessage!,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.regular,
                  colorType: AppTextColorType.primary,
                ),
              ),
              SizedBox(height: 20.h),
            ],
            AppButton(
              text: 'Delink account',
              onPressed: _startRevoke,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isFullWidth: true,
              isDisabled: _revokeInProgress,
              isLoading: _revokeInProgress,
            ),
            if (_showRetryBack) ...[
              SizedBox(height: 12.h),
              TextButton(
                onPressed:
                    _revokeInProgress
                        ? null
                        : () {
                          setState(() {
                            _errorMessage = null;
                            _showRetryBack = false;
                          });
                          _startRevoke();
                        },
                child: AppText(
                  'Try again',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.link,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkTextSecondary,
                ),
                child: AppText(
                  'Back',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.regular,
                  colorType: AppTextColorType.secondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConsentItem(AaConsent consent) {
    return Column(
      children: [
        ...(consent.accounts.map(
          (acc) => Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.darkButtonBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getFiTypeIcon(acc.fiType),
                    color: AppColors.darkPrimary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        _cleanFipName(acc.fipId),
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        '${acc.accType ?? ""} • ${acc.maskedAccNumber ?? ""}',
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _cleanFipName(String? fipId) {
    if (fipId == null) return 'Unknown Institution';
    String name = fipId;
    // Remove -FIP suffix
    if (name.endsWith('-FIP')) {
      name = name.substring(0, name.length - 4);
    }
    // Handle specific cases
    final upper = name.toUpperCase();
    if (upper == 'AXIS001') return 'Axis Bank';
    if (upper == 'CAMSRTAFIP') return 'CAMS (Mutual Funds)';
    if (upper == 'KOTAKMAHINDRABANK') return 'Kotak Mahindra Bank';
    if (upper == 'PUNJABNATIONALBANK') return 'Punjab National Bank';
    if (upper == 'HDFCBANK') return 'HDFC Bank';
    if (upper == 'ICICIBANK') return 'ICICI Bank';
    if (upper == 'SBIN') return 'State Bank of India';

    // Convert CamelCase to Space Case
    String result = name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (Match m) => '${m[1]} ${m[2]}',
    );
    return result;
  }

  IconData _getFiTypeIcon(String? fiType) {
    switch (fiType?.toUpperCase()) {
      case 'DEPOSIT':
      case 'TERM_DEPOSIT':
      case 'RECURRING_DEPOSIT':
        return Icons.account_balance_outlined;
      case 'MUTUAL_FUNDS':
      case 'SIP':
        return Icons.donut_small_outlined;
      case 'EQUITIES':
      case 'ETF':
        return Icons.trending_up_outlined;
      case 'INSURANCE_POLICIES':
      case 'LIFE_INSURANCE':
      case 'GENERAL_INSURANCE':
        return Icons.shield_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}
