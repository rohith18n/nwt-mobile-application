import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class MUScreen extends StatefulWidget {
  const MUScreen({super.key});

  @override
  State<MUScreen> createState() => _MUScreenState();
}

class _MUScreenState extends State<MUScreen> {
  // Form controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Selected values
  String _selectedAccountType = 'Savings';
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  void _showAccountTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Select Bank Account Type',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.white,
            ),
            const SizedBox(height: 20),
            _buildAccountTypeOption('Savings'),
            _buildAccountTypeOption('Current'),
            _buildAccountTypeOption('Fixed Deposit'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption(String accountType) {
    final bool isSelected = _selectedAccountType == accountType;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = accountType;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                accountType,
                variant: AppTextVariant.bodyLarge,
                colorType: AppTextColorType.white,
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Bank Account Type',
          variant: AppTextVariant.bodyLarge,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showAccountTypeBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    _selectedAccountType,
                    variant: AppTextVariant.bodyLarge,
                    colorType: AppTextColorType.white,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTINSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Enter TIN Number',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        ),
        const SizedBox(height: 16),
        DarkInputField(
          controller: _tinController,
          label: 'TIN Number',
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'TIN number is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Enter Your Foreign Address',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 20),
          DarkInputField(
            controller: _addressController,
            label: 'Address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DarkInputField(
            controller: _cityController,
            label: 'City',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'City is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DarkInputField(
            controller: _stateController,
            label: 'State',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'State is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DarkInputField(
            controller: _countryController,
            label: 'Country',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Country is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DarkInputField(
            controller: _pincodeController,
            label: 'Pincode',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pincode is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to next screen
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => NextScreen()),
        // );
      });
    }
  }

  bool get _isFormValid {
    return _addressController.text.isNotEmpty &&
           _cityController.text.isNotEmpty &&
           _stateController.text.isNotEmpty &&
           _countryController.text.isNotEmpty &&
           _pincodeController.text.isNotEmpty &&
           _tinController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppText(
          "MU Details",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Header Section
                        AppText(
                          "Complete Your MU Form",
                          variant: AppTextVariant.headline4,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          "Please fill in all the required information to proceed.",
                          variant: AppTextVariant.bodyMedium,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 32),

                        // Foreign Address Section
                        _buildAddressSection(),
                        const SizedBox(height: 32),
                        
                        // Bank Account Type Section
                        _buildAccountTypeSelector(),
                        const SizedBox(height: 32),
                        
                        // TIN Number Section
                        _buildTINSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: "Next",
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            isLoading: _isLoading,
            isDisabled: _isLoading || !_isFormValid,
            onPressed: _submitForm,
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}