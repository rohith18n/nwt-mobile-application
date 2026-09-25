class BseErrorTranslator {
  /// Maps technical BSE field names to user-friendly labels
  static String getFriendlyFieldName(String field) {
    final Map<String, String> fieldMap = {
      'COMM_ADDR_LINE1': 'Address Line 1',
      'COMM_ADDR_LINE2': 'Address Line 2',
      'COMM_ADDR_LINE3': 'Address Line 3',
      'COMM_ADDR_CITY': 'City',
      'COMM_ADDR_STATE': 'State',
      'COMM_ADDR_COUNTRY': 'Country',
      'COMM_ADDR_PINCODE': 'Pincode',
      'PER_ADDR_LINE1': 'Permanent Address Line 1',
      'PER_ADDR_CITY': 'Permanent City',
      'PER_ADDR_PINCODE': 'Permanent Pincode',
      'FATCA_OCCUPATION': 'Occupation',
      'FATCA_INCOME': 'Annual Income',
      'FATCA_NETWORTH': 'Net Worth',
      'FATCA_BIRTH_CITY': 'City of Birth',
      'FATCA_BIRTH_COUNTRY': 'Country of Birth',
      'BANK_NAME': 'Bank Name',
      'BANK_AC_NO': 'Account Number',
      'BANK_AC_TYPE': 'Account Type',
      'BANK_IFSC': 'IFSC Code',
      'NOMINEE_NAME': 'Nominee Name',
      'NOMINEE_RELATION': 'Nominee Relation',
      'NOMINEE_PAN': 'Nominee PAN',
      'PRIMARY_HOLDER_PAN': 'PAN Number',
      'PRIMARY_HOLDER_DOB': 'Date of Birth',
      'PRIMARY_HOLDER_GENDER': 'Gender',
      'PRIMARY_HOLDER_MOBILE': 'Mobile Number',
      'PRIMARY_HOLDER_EMAIL': 'Email Address',
      'UCC_CLIENT_CODE': 'Client Code',
      'occupation_code': 'Occupation',
    };

    // Check for exact match or partial match
    if (fieldMap.containsKey(field)) {
      return fieldMap[field]!;
    }

    // Attempt to make it readable if not in map
    return field
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  /// Maps technical BSE error messages to user-friendly ones
  static String getFriendlyErrorMessage(String message, {String? field}) {
    var workingMessage = message;
    var workingField = field;

    // Handle prepended field name (e.g., "fieldName: error message")
    // Only split if there's meaningful content after the colon
    if (workingField == null && workingMessage.contains(': ')) {
      final splitIndex = workingMessage.indexOf(': ');
      if (splitIndex > 0 && splitIndex < workingMessage.length - 2) {
        final potentialField = workingMessage.substring(0, splitIndex).trim();
        final potentialMessage = workingMessage.substring(splitIndex + 2).trim();

        // Only split if potential message is not empty and potential field is not a long sentence
        if (potentialMessage.isNotEmpty && potentialField.split(' ').length <= 3) {
          workingField = potentialField;
          workingMessage = potentialMessage;
        }
      }
    }

    final lowerMessage = workingMessage.toLowerCase();
    final friendlyField =
        workingField != null ? getFriendlyFieldName(workingField) : null;

    if (lowerMessage.contains('invalid ifsc')) {
      return 'The IFSC code you entered is invalid. Please double-check it with your bank or passbook.';
    }
    if (lowerMessage.contains('pan already exists')) {
      return 'This PAN number is already registered. If you have already started an application, please try to resume it or contact support.';
    }
    if (lowerMessage.contains('required')) {
      return '${friendlyField ?? 'This field'} is mandatory. Please provide a value.';
    }

    // Only use generic PAN error if the backend message isn't already descriptive
    if (lowerMessage.contains('invalid pan') && lowerMessage.length < 50) {
      return 'The PAN number provided is not valid. Please ensure it follows the format (e.g., ABCDE1234F).';
    }

    if (lowerMessage.contains('invalid format') && lowerMessage.length < 50) {
      return 'The format for ${friendlyField ?? 'this field'} is incorrect. Please check and try again.';
    }

    if (lowerMessage.contains('validation failed') &&
        lowerMessage.length < 50) {
      return 'We couldn\'t verify the ${friendlyField ?? 'information'} provided. Please ensure all details are correct as per your documents.';
    }

    if (lowerMessage.contains('input should be')) {
      return 'The selected value for ${friendlyField ?? 'this field'} is not valid. Please choose a valid option from the list.';
    }

    // If it's a field-specific error but message is generic
    if (friendlyField != null &&
        (lowerMessage == 'invalid' ||
            lowerMessage == 'error' ||
            lowerMessage == 'invalid_data')) {
      return 'The information provided for $friendlyField is invalid. Please check and try again.';
    }

    return workingMessage; // Fallback to original if already descriptive or no mapping found
  }

  /// Provides an action suggestion based on the error
  static String getActionSuggestion(String message, {String? field}) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('ifsc')) {
      return 'Verify the IFSC code from your bank\'s website or a cancelled cheque.';
    }
    if (lowerMessage.contains('pan')) {
      return 'Ensure the PAN belongs to the primary applicant and is entered correctly.';
    }
    if (lowerMessage.contains('address') || lowerMessage.contains('pincode')) {
      return 'Check if the pincode matches your city and state.';
    }
    if (lowerMessage.contains('bank')) {
      return 'Verify your bank account number and branch details.';
    }
    if (lowerMessage.contains('nominee')) {
      return 'Ensure the nominee details match their government-issued ID.';
    }

    return 'Please review the highlighted fields and try again. If the issue persists, contact our support team.';
  }
}
