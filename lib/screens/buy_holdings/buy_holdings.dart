import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'widgets/choose_folio_widget.dart';
import 'widgets/investment_details_widget.dart';
import 'widgets/sip_details_widget.dart';
import 'widgets/holding_details_widget.dart';
import 'widgets/second_holder_widget.dart';
import 'widgets/add_nominee_widget.dart';
import 'widgets/payment_method_widget.dart';
import 'widgets/order_summary_widget.dart';
import 'widgets/order_preview_widget.dart';
import 'widgets/payment_success_widget.dart';

class BuyHoldings extends StatefulWidget {
  const BuyHoldings({super.key});

  @override
  State<BuyHoldings> createState() => _BuyHoldingsState();
}

class _BuyHoldingsState extends State<BuyHoldings> {
  int currentStep = 0;
  
  // Controllers
  final TextEditingController folioController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  
  // Second Holder Controllers
  final TextEditingController secondHolderNameController = TextEditingController();
  final TextEditingController secondHolderDobController = TextEditingController();
  final TextEditingController secondHolderAadhaarController = TextEditingController();
  final TextEditingController secondHolderEmailController = TextEditingController();
  final TextEditingController secondHolderMobileController = TextEditingController();
  final TextEditingController secondHolderPanController = TextEditingController();
  
  // Nominee Controllers
  final TextEditingController nomineeNameController = TextEditingController();
  final TextEditingController nomineeDobController = TextEditingController();
  final TextEditingController nomineeAadhaarController = TextEditingController();
  final TextEditingController nomineeEmailController = TextEditingController();
  final TextEditingController nomineeMobileController = TextEditingController();
  final TextEditingController shareAllocationController = TextEditingController();
  
  
  // State variables
  String? selectedFolioOption;
  String? selectedInvestmentType;
  String? selectedAmount;
  String? selectedFrequency;
  String? selectedHoldingMode;
  String selectedSecondHolderRelation = '';
  String selectedSecondHolderIdType = '';
  bool sameAsApplicantAddressSecondHolder = false;
  String selectedNomineeRelation = '';
  String selectedNomineeIdType = '';
  bool sameAsApplicantAddressNominee = false;
  
  // Order Summary variables
  String totalAmount = '₹ 500.00';
  String selectedBank = 'Bank of Baroda';
  String accountNumber = 'A/C: xxxx1234';
  String upiId = 'john@gpay';
  String selectedPaymentMethod = '';
  
  // Order Preview variables
  String fundName = 'Kotak Emerging Fund Direct Growth';
  String paymentStatus = 'Successful';
  String paymentMode = 'UPI';
  String triggerTime = '14 Oct 2025, 6:05 pm';
  String navDate = '14 Oct 2025';
  String folioNumber = 'New';
  
  final List<String> folioOptions = [
    'Existing Folio 1',
    'Existing Folio 2',
  ];
  
  final List<String> investmentTypes = [
    'SIP',
    'Lump Sum',
    'SWP',
    'STP',
  ];
  
  final List<String> frequencies = [
    'Monthly',
    'Quarterly',
    'Half-Yearly',
    'Yearly',
  ];
  
  final List<String> holdingModes = [
    'Anyone or Survivor',
    'Joint',
    'Single',
  ];

  @override
  void initState() {
    super.initState();
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    startDateController.text =
        '${nextWeek.day}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32, color: Colors.white),
            ),
            AppText(
              _getScreenTitle(),
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.white,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: _buildCurrentScreen(),
    );
  }

  String _getScreenTitle() {
    switch (currentStep) {
      case 0:
        return 'Kotak Emerging Fund Direct Growth';
      case 1:
        return 'Investment Details';
      case 2:
        return 'Kotak Emerging Fund Direct Growth';
      case 3:
        return 'Kotak Emerging Fund Direct Growth';
      case 4:
        return 'Kotak Emerging Fund Direct Growth';
      case 5:
        return 'Kotak Emerging Fund Direct Growth';
      case 6:
        return 'Order Summary';
      case 7:
        return 'Order Summary';
      case 8:
        return 'Order Preview';
      case 9:
        return 'Payment Successful';
      default:
        return 'Buy Holdings';
    }
  }

  Widget _buildCurrentScreen() {
    switch (currentStep) {
      case 0:
        return ChooseFolioWidget(
          folioController: folioController,
          selectedFolioOption: selectedFolioOption,
          folioOptions: folioOptions,
          onFolioOptionChanged: (value) {
            setState(() {
              selectedFolioOption = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 1;
            });
          },
        );
      case 1:
        return InvestmentDetailsWidget(
          minAmount: 500.0,
          amountController: amountController,
          selectedInvestmentType: selectedInvestmentType,
          selectedAmount: selectedAmount,
          investmentTypes: investmentTypes,
          onInvestmentTypeChanged: (value) {
            print('Investment type changed to: $value');
            setState(() {
              selectedInvestmentType = value;
            });
          },
          onAmountSelected: (value) {
            setState(() {
              selectedAmount = value;
            });
          },
          onNext: () {
            // Debug print to check the selected investment type
            print('Selected Investment Type: $selectedInvestmentType');
            
            // Validate that investment type is selected
            if (selectedInvestmentType == null || selectedInvestmentType!.isEmpty) {
              // Show error message or prevent navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select an investment type'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            setState(() {
              // Debug: Force SIP details for testing
              print('Current selectedInvestmentType: "$selectedInvestmentType"');
              print('Comparison result: ${selectedInvestmentType?.trim().toUpperCase() == 'SIP'}');
              
              // Check if SIP is selected to show SIP details
              if (selectedInvestmentType?.trim().toUpperCase() == 'SIP') {
                print('Navigating to SIP Details (Step 2)');
                currentStep = 2;
              } else {
                print('Skipping to Holding Details (Step 3) - Selected: $selectedInvestmentType');
                // Temporarily force SIP details for testing
                print('FORCING SIP DETAILS FOR TESTING');
                currentStep = 2;
              }
            });
          },
        );
      case 2:
        return SipDetailsWidget(
          startDateController: startDateController,
          selectedFrequency: selectedFrequency,
          frequencies: frequencies,
          onFrequencyChanged: (value) {
            setState(() {
              selectedFrequency = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 3;
            });
          },
        );
      case 3:
        return HoldingDetailsWidget(
          selectedHoldingMode: selectedHoldingMode,
          holdingModes: holdingModes,
          onHoldingModeChanged: (value) {
            setState(() {
              selectedHoldingMode = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 4;
            });
          },
        );
      case 4:
        return SecondHolderWidget(
          nomineeNameController: secondHolderNameController,
          nomineeDobController: secondHolderDobController,
          aadhaarController: secondHolderAadhaarController,
          emailController: secondHolderEmailController,
          mobileController: secondHolderMobileController,
          panController: secondHolderPanController,
          selectedRelation: selectedSecondHolderRelation,
          selectedIdType: selectedSecondHolderIdType,
          sameAsApplicantAddress: sameAsApplicantAddressSecondHolder,
          onRelationChanged: (value) {
            setState(() {
              selectedSecondHolderRelation = value;
            });
          },
          onIdTypeChanged: (value) {
            setState(() {
              selectedSecondHolderIdType = value;
            });
          },
          onAddressChanged: (value) {
            setState(() {
              sameAsApplicantAddressSecondHolder = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 5;
            });
          },
        );
      case 5:
        return AddNomineeWidget(
          nomineeNameController: nomineeNameController,
          nomineeDobController: nomineeDobController,
          aadhaarController: nomineeAadhaarController,
          emailController: nomineeEmailController,
          mobileController: nomineeMobileController,
          shareAllocationController: shareAllocationController,
          selectedRelation: selectedNomineeRelation,
          selectedIdType: selectedNomineeIdType,
          sameAsApplicantAddress: sameAsApplicantAddressNominee,
          onRelationChanged: (value) {
            setState(() {
              selectedNomineeRelation = value;
            });
          },
          onIdTypeChanged: (value) {
            setState(() {
              selectedNomineeIdType = value;
            });
          },
          onAddressChanged: (value) {
            setState(() {
              sameAsApplicantAddressNominee = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 6;
            });
          },
        );
      case 6:
        return PaymentMethodWidget(
          totalAmount: totalAmount,
          selectedPaymentMethod: selectedPaymentMethod,
          onPaymentMethodChanged: (value) {
            setState(() {
              selectedPaymentMethod = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 7;
            });
          },
        );
      case 7:
        return OrderSummaryWidget(
          totalAmount: totalAmount,
          selectedBank: selectedBank,
          accountNumber: accountNumber,
          upiId: upiId,
          onBankTap: () {
            // Handle bank selection
            print('Bank selection tapped');
          },
          onPayNow: () {
            setState(() {
              currentStep = 8;
            });
          },
        );
      case 8:
        return OrderPreviewWidget(
          fundName: fundName,
          amount: totalAmount,
          paymentStatus: paymentStatus,
          paymentMode: paymentMode,
          bankName: selectedBank,
          triggerTime: triggerTime,
          navDate: navDate,
          folioNumber: folioNumber,
          onNext: () {
            setState(() {
              currentStep = 9;
            });
          },
        );
      case 9:
        return PaymentSuccessWidget(
          onDone: () {
            // Handle completion - go back to main screen
            Navigator.pop(context);
          },
        );
      default:
        return ChooseFolioWidget(
          folioController: folioController,
          selectedFolioOption: selectedFolioOption,
          folioOptions: folioOptions,
          onFolioOptionChanged: (value) {
            setState(() {
              selectedFolioOption = value;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 1;
            });
          },
        );
    }
  }

  @override
  void dispose() {
    folioController.dispose();
    amountController.dispose();
    startDateController.dispose();
    
    // Second Holder Controllers
    secondHolderNameController.dispose();
    secondHolderDobController.dispose();
    secondHolderAadhaarController.dispose();
    secondHolderEmailController.dispose();
    secondHolderMobileController.dispose();
    secondHolderPanController.dispose();
    
    // Nominee Controllers
    nomineeNameController.dispose();
    nomineeDobController.dispose();
    nomineeAadhaarController.dispose();
    nomineeEmailController.dispose();
    nomineeMobileController.dispose();
    shareAllocationController.dispose();
    
    super.dispose();
  }
}