import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/data/categories/categories.types.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/insurance/insurance_details.dart';
import 'package:nwt_app/screens/assets/insurance/widgets/insurance_card.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_insurance.dart';
import 'package:nwt_app/services/family_finance/assets/family_finance_assets_insurances.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';


class FamilyFinanceInsuranceListScreen extends StatefulWidget {
 const FamilyFinanceInsuranceListScreen({super.key, required this.familyId});


 final String familyId;


 @override
 State<FamilyFinanceInsuranceListScreen> createState() =>
     _FamilyFinanceInsuranceListScreenState();
}


final List<Category> categories = [
 Category(id: 'all', name: 'All'),
 Category(id: 'LIFE_INSURANCE', name: 'Life Insurance'),
 Category(id: 'GENERAL_INSURANCE', name: 'General Insurance'),
 Category(id: 'INSURANCE_POLICIES', name: 'Other Insurance'),
];


class _FamilyFinanceInsuranceListScreenState
   extends State<FamilyFinanceInsuranceListScreen> {
 final TextEditingController _searchController = TextEditingController();
 final RxString _searchQuery = ''.obs;
 bool _isAmountVisible = true;
 Category _selectedCategory = categories.first;


 final FamilyFinanceAssetsInsurancesService _insuranceService =
     FamilyFinanceAssetsInsurancesService();
 Rx<FamilyFinanceAssetsInsuranceResponse?> insuranceResponse =
     Rx<FamilyFinanceAssetsInsuranceResponse?>(null);
 final RxBool isLoading = false.obs;


 // Track expanded state for each member accordion
 final RxMap<String, bool> _expandedMembers = <String, bool>{}.obs;


 @override
 void initState() {
   super.initState();
   fetchFamilyInsurances();
 }


 Future<void> fetchFamilyInsurances() async {
   final response = await _insuranceService.getFamilyFinanceInsurances(
     familyId: widget.familyId,
     onLoading: (loading) {
       isLoading.value = loading;
     },
   );
   insuranceResponse.value = response;
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       surfaceTintColor: Colors.transparent,
       backgroundColor: Colors.transparent,
       automaticallyImplyLeading: false,
       leading: GestureDetector(
         onTap: () => Get.back(),
         child: const Icon(Icons.chevron_left, size: 32),
       ),
       centerTitle: true,
       title: AppText(
         "Family Insurance",
         variant: AppTextVariant.headline6,
         weight: AppTextWeight.semiBold,
       ),
     ),
     body: SafeArea(
       child: Column(
         children: [
           // Family Coverage Summary Card
           Padding(
             padding: const EdgeInsets.symmetric(
               horizontal: AppSizing.scaffoldHorizontalPadding,
             ),
             child: Container(
               decoration: BoxDecoration(
                 border: Border.all(color: AppColors.darkButtonBorder),
                 color: AppColors.darkCardBG,
                 borderRadius: BorderRadius.circular(15),
               ),
               padding: const EdgeInsets.symmetric(
                 horizontal: 20,
                 vertical: 20,
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           AppText(
                             "Family Coverage",
                             variant: AppTextVariant.bodyMedium,
                             weight: AppTextWeight.bold,
                             colorType: AppTextColorType.secondary,
                           ),
                         ],
                       ),
                     ],
                   ),
                   SizedBox(height: 5),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Obx(() {
                         final summary =
                             insuranceResponse.value?.data?.summary;
                         final totalCoverage =
                             summary != null
                                 ? (summary.lifeInsurance.totalsum +
                                     summary.generalInsurance.totalsum +
                                     summary.insurancePolicies.totalcoverage)
                                 : 0.0;


                         return AnimatedAmount(
                           isAmountVisible: _isAmountVisible,
                           amount: CurrencyFormatter.formatRupee(
                             totalCoverage,
                           ),
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 36,
                             fontWeight: FontWeight.bold,
                           ),
                         );
                       }),
                       InkWell(
                         onTap: () {
                           setState(() {
                             _isAmountVisible = !_isAmountVisible;
                           });
                         },
                         child: AnimatedSwitcher(
                           duration: const Duration(milliseconds: 300),
                           transitionBuilder: (
                             Widget child,
                             Animation<double> animation,
                           ) {
                             return FadeTransition(
                               opacity: animation,
                               child: child,
                             );
                           },
                           child: Icon(
                             _isAmountVisible
                                 ? Icons.visibility_outlined
                                 : Icons.visibility_off_outlined,
                             color: AppColors.darkButtonPrimaryBackground,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
           ),


           // Search Field
           Padding(
             padding: const EdgeInsets.symmetric(
               horizontal: AppSizing.scaffoldHorizontalPadding,
               vertical: 12,
             ),
             child: Obx(
               () => AppInputField(
                 controller: _searchController,
                 onChanged: (value) {
                   _searchQuery.value = value;
                   setState(() {}); // Ensure UI updates on search change
                 },
                 prefix: const Icon(
                   CupertinoIcons.search,
                   color: AppColors.darkTextMuted,
                 ),
                 suffix:
                     _searchQuery.value.isNotEmpty
                         ? InkWell(
                           onTap: () {
                             _searchController.clear();
                             _searchQuery.value = '';
                             setState(() {}); // Ensure UI updates on clear
                           },
                           child: const Icon(
                             Icons.clear,
                             color: AppColors.darkTextMuted,
                           ),
                         )
                         : null,
                 hintText: "Search...",
               ),
             ),
           ),


           // Category Filter
           SizedBox(
             height: 40,
             child: ListView.separated(
               scrollDirection: Axis.horizontal,
               padding: const EdgeInsets.symmetric(
                 horizontal: AppSizing.scaffoldHorizontalPadding,
               ),
               itemBuilder: (context, index) {
                 return CategoryChip(
                   label: categories[index].name,
                   isSelected: _selectedCategory == categories[index],
                   onTap: () {
                     setState(() {
                       _selectedCategory = categories[index];
                     });
                   },
                 );
               },
               separatorBuilder: (context, index) {
                 return const SizedBox(width: 8);
               },
               itemCount: categories.length,
             ),
           ),


           // Insurance List by Family Member
           Expanded(
             child: Container(
               margin: const EdgeInsets.symmetric(vertical: 12),
               width: double.infinity,
               child: Obx(() {
                 if (isLoading.value) {
                   return const Center(child: CircularProgressIndicator());
                 }


                 final members = insuranceResponse.value?.data?.members ?? [];


                 if (members.isEmpty) {
                   return Center(
                     child: EmptyState(
                       icon: Icons.policy_outlined,
                       title: "No insurance policies found",
                       subtitle:
                           "We couldn't find any insurance policies for your family members",
                     ),
                   );
                 }


                 // Filter members based on search query
                 final filteredMembers =
                     _searchQuery.value.isEmpty
                         ? members
                         : members.where((member) {
                           final fullName =
                               "${member.firstname} ${member.lastname}"
                                   .toLowerCase();
                           return fullName.contains(
                             _searchQuery.value.toLowerCase(),
                           );
                         }).toList();


                 return SingleChildScrollView(
                   padding: const EdgeInsets.symmetric(
                     horizontal: AppSizing.scaffoldHorizontalPadding,
                   ),
                   child: Column(
                     children: [
                       const SizedBox(height: 8),
                       ...filteredMembers.map((member) {
                         final memberName =
                             "${member.firstname} ${member.lastname}";
                         final memberGuid = member.userguid;


                         // Initialize expanded state for this member if not already set
                         if (!_expandedMembers.containsKey(memberGuid)) {
                           _expandedMembers[memberGuid] = false;
                         }


                         // Get policies based on selected category
                         List<dynamic> policies = [];


                         if (_selectedCategory.id == 'all' ||
                             _selectedCategory.id == 'LIFE_INSURANCE') {
                           policies.addAll(member.assets.lifeInsurance.data);
                         }


                         if (_selectedCategory.id == 'all' ||
                             _selectedCategory.id == 'GENERAL_INSURANCE') {
                           policies.addAll(
                             member.assets.generalInsurance.data,
                           );
                         }


                         if (_selectedCategory.id == 'all' ||
                             _selectedCategory.id == 'INSURANCE_POLICIES') {
                           policies.addAll(
                             member.assets.insurancePolicies.data,
                           );
                         }


                         // Skip this member if they have no policies matching the filter
                         if (policies.isEmpty) {
                           return const SizedBox.shrink();
                         }


                         return Padding(
                           padding: const EdgeInsets.only(bottom: 12),
                           child: CustomAccordion(
                             title: memberName,
                             initiallyExpanded:
                                 _expandedMembers[memberGuid] ?? false,
                             backgroundColor: AppColors.darkCardBG,
                             child: Column(
                               children: [
                                 ...policies.map((policy) {
                                   // Determine policy type and extract common fields
                                   String policyName = '';
                                   String policyNumber = '';
                                   double amount = 0.0;
                                   String accountGuid = '';


                                   if (policy
                                       is FamilyFinanceAssetsLifeInsuranceDatum) {
                                     policyName = policy.policytype;
                                     policyNumber = policy.maskedaccnumber;
                                     amount = policy.sumassured;
                                     accountGuid = policy.accountguid;
                                   } else if (policy
                                       is FamilyFinanceAssetsGeneralInsuranceDatum) {
                                     policyName = policy.policyname;
                                     policyNumber = policy.maskedpolicynumber;
                                     amount = policy.sumassured;
                                     accountGuid = policy.accountguid;
                                   } else if (policy
                                       is FamilyFinanceAssetsInsurancePoliciesDatum) {
                                     policyName = policy.policyname;
                                     policyNumber = policy.policynumber;
                                     amount = policy.coverageamount;
                                     accountGuid = policy.accountguid;
                                   }


                                   return Padding(
                                     padding: const EdgeInsets.only(
                                       bottom: 12,
                                     ),
                                     child: GestureDetector(
                                       onTap: () {
                                         // Navigate to details screen
                                         Get.to(
                                           () => InsuranceDetailsScreen(
                                             accountguid: accountGuid,
                                             companyLogo:
                                                 'assets/app/pivot.money.png',
                                             policyName: policyName,
                                             policyNumber: policyNumber,
                                             sumAssured: amount,
                                             policyType: _getPolicyType(
                                               policy,
                                             ),
                                             subcategory: _getSubcategory(
                                               policy,
                                             ),
                                           ),
                                         );
                                       },
                                       child: InsuranceCard(
                                         companyLogo:
                                             'assets/app/pivot.money.png',
                                         policyName: policyName,
                                         policyNumber: policyNumber,
                                         amount: amount,
                                         isAmountVisible: _isAmountVisible,
                                         subcategory: _getSubcategory(policy),
                                       ),
                                     ),
                                   );
                                 }),
                               ],
                             ),
                           ),
                         );
                       }),
                     ],
                   ),
                 );
               }),
             ),
           ),
         ],
       ),
     ),
   );
 }


 // Helper method to determine policy type
 String _getPolicyType(dynamic policy) {
   if (policy is FamilyFinanceAssetsLifeInsuranceDatum) {
     return 'LIFE_INSURANCE';
   } else if (policy is FamilyFinanceAssetsGeneralInsuranceDatum) {
     return 'GENERAL_INSURANCE';
   } else if (policy is FamilyFinanceAssetsInsurancePoliciesDatum) {
     return 'INSURANCE_POLICIES';
   }
   return '';
 }


 // Helper method to get subcategory
 String? _getSubcategory(dynamic policy) {
   if (policy is FamilyFinanceAssetsLifeInsuranceDatum) {
     return policy.policytype;
   } else if (policy is FamilyFinanceAssetsGeneralInsuranceDatum) {
     return policy.insurancetype;
   } else if (policy is FamilyFinanceAssetsInsurancePoliciesDatum) {
     return policy.policytype;
   }
   return null;
 }
}



