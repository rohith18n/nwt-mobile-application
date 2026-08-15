import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/screens/assets/insurance/insurance_transactions.dart';
import 'package:nwt_app/services/assets/insurance/insurance.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/loading.dart';

class InsuranceDetailsScreen extends StatefulWidget {
  final String accountguid;
  final String companyLogo;
  final String policyName;
  final String policyNumber;
  final double sumAssured;
  final String policyType;
  final String? subcategory;
  final Insurance? insuranceData; // Add insurance data parameter

  const InsuranceDetailsScreen({
    super.key,
    required this.accountguid,
    required this.companyLogo,
    required this.policyName,
    required this.policyNumber,
    required this.sumAssured,
    required this.policyType,
    this.subcategory,
    this.insuranceData, // Add insurance data parameter
  });

  @override
  State<InsuranceDetailsScreen> createState() => _InsuranceDetailsScreenState();
}

class _InsuranceDetailsScreenState extends State<InsuranceDetailsScreen> {
  final InsuranceService _insuranceService = InsuranceService();
  final RxBool _isLoading = false.obs;
  Rx<InsuranceDetailsData?> insuranceDetails = Rx<InsuranceDetailsData?>(null);

  @override
  void initState() {
    super.initState();
    // If we have insurance data from RawAssetController, use it directly
    if (widget.insuranceData != null) {
      _isLoading.value = false;
    } else {
      _fetchInsuranceDetails();
    }
  }

  void _fetchInsuranceDetails() async {
    final response = await _insuranceService.getInsuranceDetails(
      accountguid: widget.accountguid,
      onLoading: (isLoading) => _isLoading.value = isLoading,
    );

    if (response.statusCode == 200 && response.data != null) {
      insuranceDetails.value = response.data;
    } else {}
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd-MM-yyyy').format(date);
  }

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
            Semantics(
              label: 'Back',
              button: true,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: AppText(
                "Insurance",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
            const ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: Icon(Icons.chevron_left, size: 32),
              ),
            ),
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
                  // Insurance company logo and name
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
                        // Logo (decorative — policy name below conveys context)
                        ExcludeSemantics(
                          child: Center(
                            child: Avatar(
                              path: widget.companyLogo,
                              width: 60,
                              height: 60,
                              isNetworkImage: false,
                              borderRadius: BorderRadius.circular(4),
                              errorWidget: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    "A",
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
                        ),
                        // Policy name
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: AppText(
                            insuranceDetails.value?.policyname ??
                                (widget.policyName.isNotEmpty
                                    ? widget.policyName
                                    : (widget.subcategory ?? '')),
                            variant: AppTextVariant.headline5,
                            weight: AppTextWeight.semiBold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Premium Amount
                  _buildDetailItem(
                    label: "Premium Amount:",
                    value: CurrencyFormatter.formatRupee(
                      // Use Insurance model data if available, otherwise fallback to backend API
                      widget.insuranceData?.premiumamount ??
                          insuranceDetails.value?.premiumamount ??
                          0,
                    ),
                  ),

                  // Premium Frequency
                  _buildDetailItem(
                    label: "Premium Frequency:",
                    value:
                        widget.insuranceData?.premiumfrequency ??
                        insuranceDetails.value?.premiumfrequency ??
                        "N/A",
                  ),

                  // Coverage Amount
                  _buildDetailItem(
                    label: "Coverage Amount:",
                    value: CurrencyFormatter.formatRupee(
                      // Use Insurance model currentvalue if available, otherwise fallback to sumassured
                      widget.insuranceData?.currentvalue ??
                          insuranceDetails.value?.sumassured ??
                          widget.sumAssured,
                    ),
                  ),

                  // Surrender Value (show only if > 0)
                  if ((insuranceDetails.value?.surrendervalue ?? 0) > 0)
                    _buildDetailItem(
                      label: "Surrender Value:",
                      value: CurrencyFormatter.formatRupee(
                        insuranceDetails.value?.surrendervalue ?? 0,
                      ),
                    ),

                  // Policy Number
                  _buildDetailItem(
                    label: "Policy No:",
                    value:
                        widget.insuranceData?.policynumber ??
                        insuranceDetails.value?.policynumber ??
                        "-",
                  ),

                  // Start Date
                  _buildDetailItem(
                    label: "Start Date:",
                    value: _formatDate(
                      widget.insuranceData?.policystartdate ??
                          insuranceDetails.value?.policystartdate,
                    ),
                  ),

                  // Premium Payment Years
                  _buildDetailItem(
                    label: "Premium Payment Years:",
                    value:
                        widget.insuranceData?.premiumpaymentyears?.toString() ??
                        insuranceDetails.value?.premiumpaymentyears
                            ?.toString() ??
                        "N/A",
                  ),

                  // Next Premium Date
                  _buildDetailItem(
                    label: "Next Premium Due Date:",
                    value: _formatDate(
                      widget.insuranceData?.nextpremiumduedate ??
                          insuranceDetails.value?.nextpremiumduedate,
                    ),
                  ),

                  // Policy Type
                  _buildDetailItem(
                    label: "Policy Type:",
                    value: insuranceDetails.value?.type ?? widget.policyType,
                  ),

                  // Tenure Years
                  _buildDetailItem(
                    label: "Tenure Years:",
                    value:
                        widget.insuranceData?.tenureyears?.toString() ??
                        insuranceDetails.value?.tenureyears?.toString() ??
                        "N/A",
                  ),

                  // Transaction Count
                  if (widget.insuranceData != null)
                    Semantics(
                      label:
                          'Transactions, ${widget.insuranceData?.count ?? 0} transactions',
                      button: true,
                      hint: 'Double tap to view transaction history',
                      child: GestureDetector(
                        onTap: () => _navigateToTransactions(),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.darkCardBG,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.darkButtonBorder,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Transactions",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.primary,
                                ),
                                Row(
                                  children: [
                                    AppText(
                                      "${widget.insuranceData?.count ?? 0}",
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.semiBold,
                                      colorType: AppTextColorType.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.darkPrimary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Maturity Date
                  //  _buildDetailItem(
                  //    label: "Maturity Date:",
                  //    value: _formatDate(insuranceDetails.value?.policyenddate),
                  //  ),
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
    return Semantics(
      label: '$label $value',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                label,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.secondary,
              ),
              AppText(
                value,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTransactions() {
    if (widget.insuranceData == null) return;

    Get.to(
      () => InsuranceTransactionsScreen(insurance: widget.insuranceData!),
      transition: Transition.rightToLeft,
    );
  }
}
