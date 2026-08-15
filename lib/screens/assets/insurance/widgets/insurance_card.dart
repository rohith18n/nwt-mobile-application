import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';


class InsuranceCard extends StatelessWidget {
 final String companyLogo;
 final String policyName;
 final String policyNumber;
 final num amount;
 final bool isAmountVisible;
 final String? subcategory;


 const InsuranceCard({
   super.key,
   required this.companyLogo,
   required this.policyName,
   required this.policyNumber,
   required this.amount,
   required this.isAmountVisible,
   this.subcategory,
 });


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.darkCardBG,
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: AppColors.darkButtonBorder),
     ),
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
             width: 48,
             height: 48,
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Image.asset(companyLogo, width: 32, height: 32),
           ),
           const SizedBox(width: 16),
           // Policy Details
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisAlignment: MainAxisAlignment.start,
               children: [
                 Text(
                   policyName.isNotEmpty ? policyName : (subcategory ?? ''),
                   style: const TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     color: Colors.white,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   'Policy No: $policyNumber',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.white.withOpacity(0.6),
                   ),
                 ),
               ],
             ),
           ),
           // Amount
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               AnimatedAmount(
                 isAmountVisible: isAmountVisible,
                 amount: CurrencyFormatter.formatRupee(amount),
                 style: TextStyle(
                   fontSize: 18,
                   fontFamily: "Montserrat",
                   fontWeight: FontWeight.w600,
                   color: AppColors.darkPrimary,
                 ),
               ),
             ],
           ),
         ],
       ),
     ),
   );
 }
}



