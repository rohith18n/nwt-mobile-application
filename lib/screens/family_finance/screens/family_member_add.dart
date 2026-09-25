import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/family_finance/screens/family_management.dart';
import 'package:nwt_app/screens/family_finance/types/relation_options.dart';
import 'package:nwt_app/services/family_finance/family_member_add.dart';
import 'package:nwt_app/services/family_finance/family_member_edit.dart';
import 'package:nwt_app/services/family_finance/relation_option.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/error_message.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class FamilyMemberAddScreen extends StatefulWidget {
  final bool isEditMode;
  final String? userGuid;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? relationId;
  final String? relationName;

  const FamilyMemberAddScreen({
    super.key,
    this.isEditMode = false,
    this.userGuid,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.relationId,
    this.relationName,
  });

  @override
  State<FamilyMemberAddScreen> createState() => _FamilyMemberAddScreenState();
}

class _FamilyMemberAddScreenState extends State<FamilyMemberAddScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FamilyMemberAddService _familyMemberAddService =
      FamilyMemberAddService();
  final FamilyMemberEditService _familyMemberEditService =
      FamilyMemberEditService();
  String? _selectedRelation;
  String? _selectedRelationId;
  String _errorMessage = '';
  bool _isLoading = false;

  // Original values for tracking changes in edit mode
  String _originalFirstName = '';
  String _originalLastName = '';
  String? _originalRelation;
  String? _originalRelationId;

  // Flag to track if any field has changed in edit mode
  bool _hasChanges = false;

  final RelationOptionService _relationOptionService = RelationOptionService();

  @override
  void initState() {
    super.initState();

    // Initialize fields if in edit mode
    if (widget.isEditMode) {
      // Store original values
      _originalFirstName = widget.firstName ?? '';
      _originalLastName = widget.lastName ?? '';
      _originalRelation = widget.relationName;
      _originalRelationId = widget.relationId;

      // Set current values
      _firstNameController.text = _originalFirstName;
      _lastNameController.text = _originalLastName;
      _phoneController.text = widget.phoneNumber ?? '';
      _selectedRelation = _originalRelation;
      _selectedRelationId = _originalRelationId;

      // Add listeners to detect changes
      _firstNameController.addListener(_checkForChanges);
      _lastNameController.addListener(_checkForChanges);
    }
  }

  @override
  void dispose() {
    // Remove listeners
    if (widget.isEditMode) {
      _firstNameController.removeListener(_checkForChanges);
      _lastNameController.removeListener(_checkForChanges);
    }
    
    // Dispose focus nodes
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    
    super.dispose();
  }

  // Check if any field has changed from its original value
  void _checkForChanges() {
    if (widget.isEditMode) {
      final hasFirstNameChanged =
          _firstNameController.text != _originalFirstName;
      final hasLastNameChanged = _lastNameController.text != _originalLastName;
      final hasRelationChanged = _selectedRelation != _originalRelation;

      final newHasChanges =
          hasFirstNameChanged || hasLastNameChanged || hasRelationChanged;

      if (_hasChanges != newHasChanges) {
        setState(() {
          _hasChanges = newHasChanges;
        });
      }
    }
  }

  /// Normalizes a phone number by removing non-digits and trimming +91 or 91 prefix
  String _normalizePhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String normalizedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Trim +91 or 91 prefix if present
    if (normalizedNumber.startsWith('91') && normalizedNumber.length > 10) {
      normalizedNumber = normalizedNumber.substring(2);
    }

    return normalizedNumber;
  }

  void saveUser() async {
    if (widget.isEditMode) {
      editUser();
    } else {
      inviteUser();
    }
  }

  void inviteUser() async {
    final response = await _familyMemberAddService.inviteFamilyMember(
      familyLastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: _normalizePhoneNumber(_phoneController.text.trim()),
      relation: _selectedRelationId ?? '',
      shouldCreateShareLink: true, // Enable automatic link creation and sharing
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info(
        'Invite Family Member Response: ${response.data}',
        tag: 'FamilyMemberAddScreen',
      );

      // Navigate back to family management after successful invitation
      // The Branch link creation and sharing is now handled by the service
      Get.off(() => const FamilyManagement());
    } else {
      setState(() {
        _errorMessage = response.message;
      });
    }
  }

  void editUser() async {
    if (widget.userGuid == null) {
      setState(() {
        _errorMessage = 'User ID is missing';
      });
      return;
    }

    // Use the existing relationId from widget if the user hasn't changed it
    // or use the newly selected relationId if the user has changed it
    String relationToSend = '';
    if (_selectedRelation == widget.relationName) {
      // User didn't change the relation, use the original relationId
      relationToSend = widget.relationId ?? '';
      AppLogger.info(
        'Using original relation ID: $relationToSend',
        tag: 'FamilyMemberAddScreen',
      );
    } else {
      // User changed the relation, use the newly selected relationId
      relationToSend = _selectedRelationId ?? '';
      AppLogger.info(
        'Using newly selected relation ID: $relationToSend',
        tag: 'FamilyMemberAddScreen',
      );
    }

    final response = await _familyMemberEditService.editFamilyMember(
      userGuid: widget.userGuid!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: widget.phoneNumber ?? '',
      relation: relationToSend,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
    );
    AppLogger.info(
      'Edit Family Member Response: $relationToSend',
      tag: 'Selected Relation ID',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info(
        'Edit Family Member Response: Success',
        tag: 'FamilyMemberAddScreen',
      );

      // Navigate back to family management screen with refresh
      Get.offAll(() => const FamilyManagement());
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = response.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap:
                    () => Get.to(
                      () => const FamilyManagement(),
                      transition: Transition.rightToLeft,
                    ),
                child: const Icon(Icons.chevron_left, size: 32),
              ),
              AppText(
                widget.isEditMode ? "Edit Member" : "Add Member",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
              Opacity(opacity: 0, child: const Icon(Icons.settings_outlined)),
            ],
          ),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            AppInputField(
              labelText: "First Name",
              controller: _firstNameController,
              focusNode: _firstNameFocusNode,
              hintText: "First Name",
              validator: AppValidators.validateFirstName,
              inputFormatters: AppInputFormatters.firstNameFormatters(),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 12),
            AppInputField(
              labelText: "Last Name",
              controller: _lastNameController,
              focusNode: _lastNameFocusNode,
              hintText: "Last Name",
              validator: AppValidators.validateLastName,
              inputFormatters: AppInputFormatters.lastNameFormatters(),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 12),
            AppText(
              'Relation',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                // Unfocus all input fields before showing bottom sheet
                _firstNameFocusNode.unfocus();
                _lastNameFocusNode.unfocus();
                _phoneFocusNode.unfocus();
                _showRelationSelectionBottomSheet(context);
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                constraints: const BoxConstraints(minHeight: 55),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkButtonBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          _selectedRelation ?? 'Select Relation',
                          variant: AppTextVariant.bodyMedium,
                          colorType:
                              _selectedRelation != null
                                  ? AppTextColorType.primary
                                  : AppTextColorType.secondary,
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            AppInputField(
              labelText: "Phone Number",
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              hintText: "Phone Number",
              validator: AppValidators.validatePhone,
              inputFormatters: AppInputFormatters.phoneFormatters(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _phoneController.text = value;
                });

                // Remove any non-digit characters to count only digits
                String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                // Close keyboard when 10 digits are entered
                if (digitsOnly.length == 10) {
                  FocusScope.of(context).unfocus();
                }
              },
              readOnly: widget.isEditMode,
              enabled: !widget.isEditMode,
              suffix:
                  widget.isEditMode
                      ? null
                      : InkWell(
                        onTap: () => _showContactsBottomSheet(context),
                        child: const Icon(
                          Icons.contacts_outlined,
                          size: 18,
                          color: AppColors.lightSecondary,
                        ),
                      ),
            ),
            if (widget.isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppText(
                  "Phone number cannot be edited",
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.darkButtonBorder),
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                spacing: 8,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.darkTextMuted,
                    size: 18,
                  ),
                  Expanded(
                    child: AppText(
                      "You can add upto 5 members in your family.",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.regular,
                      colorType: AppTextColorType.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [AnimatedErrorMessage(message: _errorMessage)]),
            SizedBox(height: 12),
            if (!(widget.isEditMode && !_hasChanges)) // Only show button if not in edit mode or if there are changes
              Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                width: MediaQuery.of(context).size.width,
                child: AppButton(
                  onPressed: () {
                    if (_firstNameController.text.isNotEmpty &&
                        _lastNameController.text.isNotEmpty &&
                        _selectedRelation != null &&
                        _selectedRelationId != null) {
                      if (!widget.isEditMode) {
                        final normalizedPhoneNumber = _normalizePhoneNumber(
                          _phoneController.text,
                        );
                        _phoneController.text = normalizedPhoneNumber;

                        if (_phoneController.text.isEmpty) {
                          setState(() {
                            _errorMessage = 'Please enter a valid phone number';
                          });
                          return;
                        }
                      }
                      saveUser();
                    } else {
                      setState(() {
                        _errorMessage = 'Please fill all required fields';
                      });
                    }
                  },
                  variant: AppButtonVariant.primary,
                  text: widget.isEditMode ? "Save Changes" : "Invite",
                  isLoading: _isLoading,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  /// Show a bottom sheet with all contacts and search functionality
  Future<void> _showContactsBottomSheet(BuildContext context) async {
    // Request contacts permission
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      setState(() {
        _errorMessage = 'Contacts permission denied';
      });
      return;
    }

    // Variables for the bottom sheet state
    bool isLoading = true;
    List<Contact> contacts = [];
    List<Contact> filteredContacts = [];
    final searchController = TextEditingController();

    // Show the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            // Load contacts when the bottom sheet is opened
            if (isLoading) {
              FlutterContacts.getContacts(
                    withProperties: true,
                    withPhoto: false,
                    withThumbnail: false,
                  )
                  .then((fetchedContacts) {
                    setBottomSheetState(() {
                      contacts = fetchedContacts;
                      filteredContacts = fetchedContacts;
                      isLoading = false;
                    });
                  })
                  .catchError((error) {
                    setBottomSheetState(() {
                      isLoading = false;
                    });
                    setState(() {
                      _errorMessage = 'Error loading contacts: $error';
                    });
                  });
            }

            // Filter contacts based on search query
            void filterContacts(String query) {
              setBottomSheetState(() {
                if (query.isEmpty) {
                  filteredContacts = contacts;
                } else {
                  filteredContacts =
                      contacts.where((contact) {
                        final fullName =
                            '${contact.name.first} ${contact.name.last}'
                                .toLowerCase();
                        final phoneNumbers =
                            contact.phones
                                .map((phone) => phone.number)
                                .join(' ')
                                .toLowerCase();
                        return fullName.contains(query.toLowerCase()) ||
                            phoneNumbers.contains(query.toLowerCase());
                      }).toList();
                }
              });
            }

            // Select a contact and update the form
            void selectContact(Contact contact) async {
              if (contact.phones.isEmpty) {
                setState(() {
                  _errorMessage = 'This contact has no phone number';
                });
                return;
              }

              // Get full contact details
              final fullContact = await FlutterContacts.getContact(
                contact.id,
                withProperties: true,
              );

              if (fullContact != null) {
                // Update the form fields
                setState(() {
                  if (fullContact.name.first.isNotEmpty) {
                    _firstNameController.text = fullContact.name.first;
                  }

                  if (fullContact.name.last.isNotEmpty) {
                    _lastNameController.text = fullContact.name.last;
                  }

                  // Get the first phone number
                  if (fullContact.phones.isNotEmpty) {
                    final phoneNumber = _normalizePhoneNumber(
                      fullContact.phones.first.number,
                    );
                    _phoneController.text = phoneNumber;
                  }
                });

                // Close the bottom sheet
                Navigator.pop(context);
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      AppText(
                        "Select Contact",
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.semiBold,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  AppInputField(
                    controller: searchController,
                    hintText: "Search contacts",
                    onChanged: filterContacts,
                    prefix: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.lightSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contacts list
                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                strokeCap: StrokeCap.round,
                              ),
                            )
                            : filteredContacts.isEmpty
                            ? Center(
                              child: AppText(
                                searchController.text.isEmpty
                                    ? "No contacts found"
                                    : "No matching contacts",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.medium,
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                final hasPhoneNumber =
                                    contact.phones.isNotEmpty;
                                final phoneNumber =
                                    hasPhoneNumber
                                        ? contact.phones.first.number
                                        : 'No phone number';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkInputBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: AppText(
                                      "${contact.name.first} ${contact.name.last}",
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.medium,
                                    ),
                                    subtitle: AppText(
                                      phoneNumber,
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppColors.darkButtonBorder,
                                      child: Text(
                                        contact.name.first.isNotEmpty
                                            ? contact.name.first[0]
                                                .toUpperCase()
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    enabled: hasPhoneNumber,
                                    onTap:
                                        () =>
                                            hasPhoneNumber
                                                ? selectContact(contact)
                                                : null,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRelationSelectionBottomSheet(BuildContext context) {
    bool isLoading = true;
    List<RelationOption> relationOptions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            // Fetch relation options when the bottom sheet is opened
            if (isLoading) {
              _relationOptionService
                  .getRelationOptions(
                    onLoading: (loading) {
                      setBottomSheetState(() {
                        isLoading = loading;
                      });
                    },
                  )
                  .then((response) {
                    setBottomSheetState(() {
                      relationOptions = response.data;
                      isLoading = false;
                    });
                  });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      AppText(
                        "Select Relation",
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.semiBold,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                strokeCap: StrokeCap.round,
                              ),
                            )
                            : relationOptions.isEmpty
                            ? Center(
                              child: AppText(
                                "No relation options available",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.medium,
                              ),
                            )
                            : ListView.separated(
                              itemCount: relationOptions.length,
                              separatorBuilder:
                                  (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final relation = relationOptions[index];
                                final isSelected =
                                    _selectedRelationId == relation.codeId;
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setBottomSheetState(() {
                                        _selectedRelation = relation.name;
                                        _selectedRelationId = relation.codeId;
                                      });
                                      setState(() {
                                        if (widget.isEditMode) {
                                          _checkForChanges();
                                        }
                                      });
                                      
                                      // Close bottom sheet and clear focus
                                      Navigator.pop(context);
                                      
                                      // Unfocus all input fields after selection
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        if (mounted) {
                                          _firstNameFocusNode.unfocus();
                                          _lastNameFocusNode.unfocus();
                                          _phoneFocusNode.unfocus();
                                          FocusScope.of(context).unfocus();
                                        }
                                      });
                                    },
                                    child: Container(
                                      height: 50,
                                      padding: const EdgeInsets.all(15.0),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkInputBackground,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          AppText(
                                            relation.name,
                                            variant: AppTextVariant.bodyMedium,
                                            weight: AppTextWeight.medium,
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_rounded,
                                              color: Colors.green,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Clear focus when bottom sheet closes
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _firstNameFocusNode.unfocus();
                            _lastNameFocusNode.unfocus();
                            _phoneFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      variant: AppButtonVariant.primary,
                      text: "Done",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
