import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            AppText(
              "Account Details",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Spacer(),
            const WhatsAppSupportButton(size: 20),
          ],
        ),
      ),
      body: GetBuilder<UserController>(
        builder: (controller) {
          final user = controller.userData;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final ucc = user.uccProfile ?? {};
          final bank = ucc['bank'] as Map<String, dynamic>? ?? {};
          final address = ucc['address'] as Map<String, dynamic>? ?? {};
          final uccAccounts = user.rawData?['ucc_accounts'] as List? ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _buildSection(
                    title: "Personal Information",
                    items: [
                      _buildInfoRow(
                        "Full Name",
                        "${user.firstname} ${user.lastname}",
                      ),
                      _buildInfoRow("Email", user.email ?? "N/A"),
                      _buildInfoRow("Phone", "+91 ${user.phonenumber}"),
                      _buildInfoRow("PAN Number", user.pannumber ?? "N/A"),
                      _buildInfoRow(
                        "Date of Birth",
                        user.dob != null
                            ? "${user.dob!.day}/${user.dob!.month}/${user.dob!.year}"
                            : "N/A",
                      ),
                      _buildInfoRow(
                        "Gender",
                        _mapGender(ucc['primary_gender']),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                  child: _buildSection(
                    title: "Investor Details",
                    items: [
                      _buildInfoRow(
                        "Investor Residency",
                        user.isNri == true ? "Non-Resident" : "Resident",
                      ),
                      _buildInfoRow(
                        "Tax Status",
                        ucc['primary_tax_status'] ?? "N/A",
                      ),
                      _buildInfoRow(
                        "Occupation",
                        _mapOccupation(ucc['primary_occupation']),
                      ),
                      _buildInfoRow(
                        "Income Slab",
                        _mapIncomeSlab(ucc['primary_income_slab']),
                      ),
                      _buildInfoRow("PEP Status", _mapPEP(ucc['primary_pep'])),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 400),
                  child: _buildSection(
                    title: "Correspondence Address",
                    items: [
                      _buildInfoRow(
                        "Address",
                        user.rawData?['address_line_1'] ?? "N/A",
                      ),
                      _buildInfoRow("City", user.rawData?['city'] ?? "N/A"),
                      _buildInfoRow("State", user.rawData?['state'] ?? "N/A"),
                      _buildInfoRow(
                        "Pincode",
                        user.rawData?['pincode'] ?? "N/A",
                      ),
                      _buildInfoRow(
                        "Country",
                        user.rawData?['country'] ?? "N/A",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 400),
                  child: _buildSection(
                    title: "Bank Details",
                    items: [
                      _buildInfoRow("Bank Name", bank['bank_name'] ?? "N/A"),
                      _buildInfoRow(
                        "Account Number",
                        bank['account_number'] ?? "N/A",
                      ),
                      _buildInfoRow("IFSC Code", bank['ifsc_code'] ?? "N/A"),
                      _buildInfoRow(
                        "Account Type",
                        _mapAccountType(bank['account_type']),
                      ),
                    ],
                  ),
                ),
                if (uccAccounts.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 400),
                    child: _buildUccSection(uccAccounts),
                  ),
                ],
                if (ucc['primary_signature'] != null) ...[
                  SizedBox(height: 16.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 400),
                    child: _buildSignatureSection(ucc['primary_signature']),
                  ),
                ],
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF17181A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            customColor: AppColors.darkPrimary,
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          SizedBox(height: 12.h),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              colorType: AppTextColorType.secondary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.medium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUccSection(List accounts) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF17181A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "UCC Accounts",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            customColor: AppColors.darkPrimary,
          ),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final acc = accounts[index] as Map<String, dynamic>;
              return Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow("Client Code", acc['client_code'] ?? "N/A"),
                    _buildInfoRow("Status", acc['bse_status'] ?? "N/A"),
                    _buildInfoRow("Tax Status", acc['tax_status'] ?? "N/A"),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(String signatureBase64) {
    try {
      final bytes = base64Decode(signatureBase64.split(',').last);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFF17181A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              "Digital Signature",
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              customColor: AppColors.darkPrimary,
            ),
            SizedBox(height: 16.h),
            Center(
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Image.memory(bytes, height: 120.h, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _mapGender(dynamic code) {
    switch (code?.toString().toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return code?.toString() ?? "N/A";
    }
  }

  String _mapOccupation(dynamic code) {
    final codes = {
      '01': 'Business',
      '02': 'Professional',
      '03': 'Agriculture',
      '04': 'Retired',
      '05': 'Housewife',
      '06': 'Student',
      '07': 'Others',
      '08': 'Service',
    };
    return codes[code?.toString()] ?? code?.toString() ?? "N/A";
  }

  String _mapIncomeSlab(dynamic code) {
    final codes = {
      '31': 'Below 1 Lakh',
      '32': '1-5 Lakhs',
      '33': '5-10 Lakhs',
      '34': '10-25 Lakhs',
      '35': 'Above 25 Lakhs',
    };
    return codes[code?.toString()] ?? code?.toString() ?? "N/A";
  }

  String _mapPEP(dynamic code) {
    switch (code?.toString().toUpperCase()) {
      case 'N':
        return 'Not Applicable';
      case 'Y':
        return 'Politically Exposed';
      case 'R':
        return 'Related to PEP';
      default:
        return code?.toString() ?? "N/A";
    }
  }

  String _mapAccountType(dynamic code) {
    switch (code?.toString().toUpperCase()) {
      case 'SB':
        return 'Savings';
      case 'CB':
        return 'Current';
      case 'NE':
        return 'NRE';
      case 'NO':
        return 'NRO';
      default:
        return code?.toString() ?? "N/A";
    }
  }
}
