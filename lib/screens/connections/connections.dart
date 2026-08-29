import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/connections/widgets/connections_card.dart';
import 'package:nwt_app/screens/personal_assets/personal_assets.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/profile/consent_revoke_screen.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final AccountAggregatorRouter _accountAggregatorRouter =
      AccountAggregatorRouter();
  // Kept as Get.put in case other parts of this screen rely on registration side-effects.
  // ignore: unused_field
  final UserController _userController = Get.put(UserController());

  Timer? _countdownTimer;
  // ignore: unused_field
  bool _isBottomSheetOpen = false;
  bool? _hasConsents;

  @override
  void initState() {
    super.initState();
    _loadConsentsStatus();
  }

  Future<void> _loadConsentsStatus() async {
    final user = _userController.userData;
    if (user?.isFinarkeinAa != true) {
      if (mounted) setState(() => _hasConsents = false);
      return;
    }
    try {
      final list = await FinarkeinConsentsService().getConsents();
      if (mounted) setState(() => _hasConsents = list.any((c) => c.isActive));
    } catch (_) {
      if (mounted) setState(() => _hasConsents = false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Shows a bottom sheet with 10-second countdown before opening Saafe SDK
  // void _showSaafePreparationBottomSheet() {
  //   if (_isBottomSheetOpen) return;

  //   _isBottomSheetOpen = true;
  //   int countdown = 5;

  //   showModalBottomSheet(
  //     context: context,
  //     isDismissible: false,
  //     enableDrag: false,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (BuildContext bottomSheetContext) {
  //       return StatefulBuilder(
  //         builder: (context, setBottomSheetState) {
  //           // Start countdown timer
  //           if (_countdownTimer == null || !_countdownTimer!.isActive) {
  //             _countdownTimer = Timer.periodic(const Duration(seconds: 1), (
  //               timer,
  //             ) {
  //               if (countdown > 0) {
  //                 setBottomSheetState(() {
  //                   countdown--;
  //                 });
  //               } else {
  //                 timer.cancel();
  //                 _countdownTimer = null;

  //                 // Close bottom sheet and open Saafe SDK
  //                 if (bottomSheetContext.mounted &&
  //                     Navigator.canPop(bottomSheetContext)) {
  //                   Navigator.pop(bottomSheetContext);
  //                 }
  //                 _isBottomSheetOpen = false;

  //                 // Open Saafe SDK with a small delay to ensure navigation completes
  //                 Future.delayed(const Duration(milliseconds: 100), () {
  //                   if (mounted) {
  //                     _openSaafeSdk();
  //                   }
  //                 });
  //               }
  //             });
  //           }

  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: AppColors.darkCardBG,
  //               borderRadius: BorderRadius.only(
  //                 topLeft: Radius.circular(24),
  //                 topRight: Radius.circular(24),
  //               ),
  //             ),
  //             padding: const EdgeInsets.all(32),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const SizedBox(height: 20),

  //                 // Logo section with arrows
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Align(
  //                         alignment: Alignment.centerLeft,
  //                         child: SvgPicture.asset('assets/app/pivot_money.svg'),
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: Center(
  //                         child: SvgPicture.asset(
  //                           'assets/svgs/saafe/saafe_redirection.svg',
  //                           height: 36,
  //                         ),
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: Align(
  //                         alignment: Alignment.centerRight,
  //                         child: Image.asset(
  //                           'assets/svgs/saafe/saafe_logo.png',
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 40),

  //                 // Title
  //                 const AppText(
  //                   "Redirecting to Saafe\nAccount Aggregator",
  //                   variant: AppTextVariant.headline4,
  //                   weight: AppTextWeight.bold,
  //                   textAlign: TextAlign.center,
  //                   colorType: AppTextColorType.primary,
  //                   lineHeight: 1.3,
  //                 ),
  //                 const SizedBox(height: 16),

  //                 // Description
  //                 const AppText(
  //                   "RBI authorized institution that securely finds and\nshares your financial data with us",
  //                   variant: AppTextVariant.bodyMedium,
  //                   colorType: AppTextColorType.secondary,
  //                   textAlign: TextAlign.center,
  //                   lineHeight: 1.4,
  //                 ),
  //                 const SizedBox(height: 20),

  //                 // Failure-state note (AA limitations)
  //                 Container(
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     color: AppColors.darkCardBG,
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(color: AppColors.darkButtonBorder),
  //                   ),
  //                   padding: const EdgeInsets.all(16),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: const [
  //                           Icon(
  //                             Icons.warning_amber_rounded,
  //                             color: Colors.amberAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'PLEASE NOTE',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                           SizedBox(width: 4),
  //                           Icon(
  //                             Icons.warning_amber_rounded,
  //                             color: Colors.amberAccent,
  //                             size: 18,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 12),
  //                       const AppText(
  //                         'Account Aggregators DO NOT support',
  //                         variant: AppTextVariant.bodyMedium,
  //                         colorType: AppTextColorType.secondary,
  //                       ),
  //                       const SizedBox(height: 12),

  //                       // Bullet: Joint Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'JOINT ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: Current Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'CURRENT ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: NRE/NRO Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'NRE/NRO ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: Insurance partly supported
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.error_outline,
  //                             color: Colors.orangeAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             ' INSURANCE partly supported',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),

  //                 // Learn More link
  //                 GestureDetector(
  //                   onTap: () async {
  //                     // Open Sahamati website
  //                     final Uri url = Uri.parse(
  //                       'https://sahamati.org.in/what-is-account-aggregator/',
  //                     );
  //                     if (await canLaunchUrl(url)) {
  //                       await launchUrl(
  //                         url,
  //                         mode: LaunchMode.externalApplication,
  //                       );
  //                     }
  //                   },
  //                   child: const AppText(
  //                     "Learn More",
  //                     variant: AppTextVariant.bodyMedium,
  //                     colorType: AppTextColorType.link,
  //                     weight: AppTextWeight.medium,
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),

  //                 // Trust indicator with Indian flag
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 20,
  //                     vertical: 12,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(25),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       // Indian flag
  //                       Container(
  //                         width: 24,
  //                         height: 16,
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                         child: Column(
  //                           children: [
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: const BoxDecoration(
  //                                   color: Color(0xFFFF9933),
  //                                   borderRadius: BorderRadius.only(
  //                                     topLeft: Radius.circular(2),
  //                                     topRight: Radius.circular(2),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             Expanded(
  //                               child: Container(
  //                                 color: Colors.white,
  //                                 child: const Center(
  //                                   child: Icon(
  //                                     Icons.circle,
  //                                     color: Color(0xFF000080),
  //                                     size: 6,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: const BoxDecoration(
  //                                   color: Color(0xFF138808),
  //                                   borderRadius: BorderRadius.only(
  //                                     bottomLeft: Radius.circular(2),
  //                                     bottomRight: Radius.circular(2),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                       const AppText(
  //                         "Used by 10+ million citizens across India",
  //                         variant: AppTextVariant.bodySmall,
  //                         colorType: AppTextColorType.black,
  //                         weight: AppTextWeight.semiBold,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 32),
  //                 GestureDetector(
  //                   onTap: () {
  //                     _countdownTimer?.cancel();
  //                     _countdownTimer = null;
  //                     _isBottomSheetOpen = false;
  //                     Navigator.pop(bottomSheetContext);
  //                   },
  //                   child: const AppText(
  //                     "Cancel",
  //                     variant: AppTextVariant.bodyMedium,
  //                     colorType: AppTextColorType.link,
  //                     weight: AppTextWeight.semiBold,
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),

  //                 // Bottom padding for safe area
  //                 SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   ).whenComplete(() {
  //     _isBottomSheetOpen = false;
  //     _countdownTimer?.cancel();
  //     _countdownTimer = null;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => BackNavigation.backOrHome(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Connections",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            InkWell(
              onTap: () => BackNavigation.backOrHome(),
              child: AppText(
                "Skip",
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.link,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/svgs/connections/connection.svg"),
                ],
              ),
              SizedBox(height: 42),
              AppText(
                " Connect your accounts to easily track your Networth ",
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.medium,
              ),
              SizedBox(height: 20),
              Column(
                spacing: 18,
                children: [
                  ConnectionsCard(
                    icon: Icons.account_balance_outlined,
                    title: "Banks & Investments",
                    addText: _hasConsents == true ? "Revoke" : "Connect",
                    onAddPressed: () {
                      if (_hasConsents == true) {
                        Get.to(() => const ConsentRevokeScreen());
                      } else {
                        _accountAggregatorRouter.openConnection(context);
                      }
                    },
                  ),
                  ConnectionsCard(
                    icon: Icons.account_balance_outlined,
                    title: "Personal Assets",
                    onAddPressed: () {
                      Get.to(() => const PersonalAssetsScreen());
                    },
                  ),
                  ConnectionsCard(
                    icon: Icons.credit_card_outlined,
                    title: "Credit Cards",
                    isDisabled: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
