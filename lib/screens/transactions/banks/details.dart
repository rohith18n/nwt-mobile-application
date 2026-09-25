import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class TransactionDetails extends StatefulWidget {
  const TransactionDetails({super.key, required this.transaction});

  final Banktransation transaction;

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  final TextEditingController _receiptController = TextEditingController();
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
                onTap: () => Navigator.pop(context),
                child: const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            AppText(
              "Transaction Details",
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

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              spacing: 12,
              children: [
                SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Column(
                          spacing: 8,
                          children: [
                            ExcludeSemantics(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkButtonBorder,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  widget.transaction.type == "CREDIT"
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 22,
                                  color:
                                      widget.transaction.type == "CREDIT"
                                          ? AppColors.success
                                          : AppColors.error,
                                ),
                              ),
                            ),
                            AppText(
                              "${widget.transaction.type == "CREDIT" ? "+" : "-"}${CurrencyFormatter.formatRupeeWithCommas(widget.transaction.amount)}",
                              variant: AppTextVariant.headline2,
                              weight: AppTextWeight.bold,
                              colorType:
                                  widget.transaction.type == "CREDIT"
                                      ? AppTextColorType.success
                                      : AppTextColorType.error,
                            ),
                            AppText(
                              widget.transaction.reference ?? 'No reference',
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "Transaction ID:",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            Expanded(
                              child: Row(
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: AppText(
                                      widget.transaction.txnid ?? 'N/A',
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.medium,
                                      colorType: AppTextColorType.primary,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Semantics(
                                    label: 'Copy Transaction ID',
                                    button: true,
                                    child: GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: widget.transaction.txnid ?? 'N/A',
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: ExcludeSemantics(
                                        child: Icon(
                                          Icons.copy,
                                          color: AppColors.darkPrimary,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "To:",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: AppText(
                                  widget.transaction.narration,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.primary,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "Method:",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            AppText(
                              widget.transaction.mode,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "Date and Time:",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            AppText(
                              DateFormat(
                                'MMM d, h:mm a',
                              ).format(widget.transaction.transactiontimestamp),
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   width: double.infinity,
                //   decoration: BoxDecoration(
                //     color: AppColors.darkCardBG,
                //     borderRadius: BorderRadius.circular(15),
                //     border: Border.all(color: AppColors.darkButtonBorder),
                //   ),
                //   padding: const EdgeInsets.all(15),
                //   child: Column(
                //     children: [
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           AppText(
                //             "Supporting Receipt:",
                //             variant: AppTextVariant.bodyMedium,
                //             weight: AppTextWeight.medium,
                //             colorType: AppTextColorType.primary,
                //           ),
                //           GestureDetector(
                //             onTap: () async {
                //               final result = await FilePicker.platform
                //                   .pickFiles(
                //                     type: FileType.custom,
                //                     allowedExtensions: [
                //                       'pdf',
                //                       'png',
                //                       'jpg',
                //                       'jpeg',
                //                       'xls',
                //                       'xlsx',
                //                       'csv',
                //                     ],
                //                   );
                //               if (result != null) {
                //                 final file = result.files.first;
                //                 _receiptController.text = file.name;
                //                 // TODO: Handle file upload to server if needed
                //               }
                //             },
                //             child: AppText(
                //               "Upload",
                //               variant: AppTextVariant.bodyMedium,
                //               weight: AppTextWeight.medium,
                //               colorType: AppTextColorType.link,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                // Container(
                //   child: AppInputField(
                //     maxLines: 3,
                //     controller: TextEditingController(),
                //     hintText: "Just a little note to remember for later!",
                //     contentPadding: const EdgeInsets.all(15),
                //     fillColor: AppColors.darkCardBG,
                //     // readOnly: true,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
