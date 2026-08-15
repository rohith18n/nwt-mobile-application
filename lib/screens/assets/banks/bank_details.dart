import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/assets/banks/types/bank_details.dart' as details;
import 'package:nwt_app/services/account_aggregators/raw_asset_service.dart';
import 'package:nwt_app/services/assets/banks/bank_details.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/loading.dart';

class BankDetailsScreen extends StatefulWidget {
  final String bankGUID;
  final double balance;
  final String bankLogo;
  final bool forceStandardApis;

  const BankDetailsScreen({
    super.key,
    required this.bankGUID,
    required this.balance,
    required this.bankLogo,
    this.forceStandardApis = true,
  });

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final RxBool _isLoading = false.obs;
  final BankDetailsService _bankDetailsService = BankDetailsService();
  details.Data? _bankDetailsData;

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is String) {
      final parsed = double.tryParse(amount);
      return CurrencyFormatter.formatRupeeWithCommas(parsed ?? 0);
    }
    return CurrencyFormatter.formatRupeeWithCommas(amount.toDouble());
  }

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    try {
      _isLoading.value = true;
      
      // Check if user is Finarkein AA user
      final userController = Get.find<UserController>();
      final isFinarkein = !widget.forceStandardApis && userController.userData?.isFinarkeinAa == true;
      
      if (isFinarkein) {
        // For Finarkein users, fetch data directly from API using RawAssetService
        final rawAssetService = RawAssetService();
        final banksData = await rawAssetService.getAllBanks();
        
        // Find the bank matching the GUID
        final bankData = banksData.firstWhereOrNull(
          (b) => b['accountguid'] == widget.bankGUID || 
                 b['linkedaccref'] == widget.bankGUID ||
                 b['guid'] == widget.bankGUID,
        );
        
        if (bankData != null && mounted) {
          setState(() {
            _bankDetailsData = details.Data(
              guid: bankData['accountguid'] ?? bankData['linkedaccref'] ?? bankData['guid'],
              accountguid: bankData['accountguid'] ?? bankData['linkedaccref'] ?? bankData['guid'],
              fipname: bankData['fipname'] ?? 'Bank',
              maskedaccnumber: bankData['maskedaccnumber'] ?? '',
              linkrefnumber: bankData['linkedaccref'] ?? bankData['accountguid'],
              accounttype: bankData['type'] ?? 'DEPOSIT',
              branch: bankData['branch'],
              ifsc: bankData['ifsccode'] ?? bankData['ifsc'],
              openingdate: bankData['openingdate'],
              maturityamount: bankData['principalamount']?.toDouble(),
              interestpayout: bankData['interestrate'] != null ? '${bankData['interestrate']}%' : null,
              profile: details.Profile(
                name: bankData['holdername'] ?? '',
                nominee: '',
              ),
            );
          });
        }
      } else {
        // For non-Finarkein users, fetch from API
        final response = await _bankDetailsService.getBankDetails(
          accountguid: widget.bankGUID,
          onLoading: (isLoading) {
            if (mounted) {
              setState(() {
                _isLoading.value = isLoading;
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _bankDetailsData = response.data;
          });
        }

        // Log the response data
        print('Bank Details Response: ${response.toJson()}');
      }
    } catch (e) {
      print('Error fetching bank details: $e');
      // You might want to show an error message to the user here
    } finally {
      if (mounted) {
        setState(() {
          _isLoading.value = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Back',
              button: true,
              child: GestureDetector(
                onTap: () {
                  // GetX may attempt to close an (uninitialized) snackbar controller
                  // on back, throwing LateInitializationError. Fallback to Flutter
                  // navigation to ensure the screen can always be popped safely.
                  try {
                    Get.back(closeOverlays: false);
                  } catch (_) {
                    Navigator.of(context).maybePop();
                  }
                },
                child: const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            AppText(
              'Account  Details',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Obx(() {
            if (_isLoading.value) {
              return const Center(child: LoadingIndicator());
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                spacing: 12,
                children: [
                  // Bank logo and name
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.darkButtonBorder),
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      spacing: 16,
                      children: [
                        // Logo
                        Center(
                          child: Avatar(
                            path: widget.bankLogo,
                            width: 60,
                            height: 60,
                            isNetworkImage: false,
                            borderRadius: BorderRadius.circular(4),
                            errorWidget: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.darkButtonPrimaryBackground,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  // _bankDetailsData?.fipname.isNotEmpty
                                  //     ? _bankDetailsData?.fipname.toUpperCase()
                                  "B",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Bank name
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: AppText(
                            _bankDetailsData?.fipname ?? "",
                            variant: AppTextVariant.headline5,
                            weight: AppTextWeight.semiBold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_bankDetailsData?.openingdate != null &&
                      _bankDetailsData!.openingdate!.isNotEmpty)
                    _buildDetailItem(
                      label: "Opening Date:",
                      value: _formatDate(_bankDetailsData?.openingdate),
                    ),
                  if (_bankDetailsData?.maturityamount != null)
                    _buildDetailItem(
                      label: "Maturity Amount:",
                      value: _formatCurrency(_bankDetailsData?.maturityamount),
                    ),
                  if (_bankDetailsData?.maturitydate != null &&
                      _bankDetailsData!.maturitydate!.isNotEmpty)
                    _buildDetailItem(
                      label: "Maturity Date:",
                      value: _formatDate(_bankDetailsData?.maturitydate),
                    ),
                  if (_bankDetailsData?.interestpayout != null &&
                      _bankDetailsData!.interestpayout!.isNotEmpty)
                    _buildDetailItem(
                      label: "Interest Payout:",
                      value: _bankDetailsData!.interestpayout!,
                    ),
                  if (_bankDetailsData?.accounttype != null &&
                      _bankDetailsData!.accounttype!.isNotEmpty)
                    _buildDetailItem(
                      label: "Account Type:",
                      value: _bankDetailsData!.accounttype!,
                    ),
                  if (_bankDetailsData?.tenureyears != null)
                    _buildDetailItem(
                      label: "Tenure Years:",
                      value: _bankDetailsData!.tenureyears.toString(),
                    ),
                  if (_bankDetailsData?.profile?.name != null &&
                      _bankDetailsData!.profile!.name!.isNotEmpty)
                    _buildDetailItem(
                      label: "Holder Name:",
                      value: _bankDetailsData!.profile!.name!,
                    ),

                  if (_bankDetailsData?.branch != null &&
                      _bankDetailsData!.branch!.isNotEmpty)
                    _buildDetailItem(
                      label: "Branch:",
                      value: _bankDetailsData!.branch!,
                    ),
                  if (_bankDetailsData?.ifsc != null &&
                      _bankDetailsData!.ifsc!.isNotEmpty)
                    _buildDetailItem(
                      label: "IFSC:",
                      value: _bankDetailsData!.ifsc!,
                    ),
                  if (_bankDetailsData?.profile?.nominee != null &&
                      _bankDetailsData!.profile!.nominee!.isNotEmpty)
                    _buildDetailItem(
                      label: "Nominee:",
                      value: _bankDetailsData!.profile!.nominee!,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value}) {
    // Skip rendering if value is null or empty
    if (value.isEmpty || value == 'N/A') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      child: MergeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText(
                label,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.secondary,
              ),
            ),
            Expanded(
              child: AppText(
                value,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
                textAlign: TextAlign.right,
                // overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
