# Universal PAN Verification Widget

## Overview

The `UniversalPanVerificationWidget` is a reusable, dynamic widget that handles the complete PAN verification flow including:

1. **Phone Number Validation** (if not already validated)
2. **OTP Verification** for phone
3. **PAN Number Collection and Verification**
4. **Automatic Retry Logic** for failed PAN verification

## Features

✅ **Dynamic Flow**: Automatically adjusts based on phone validation status
✅ **OTP Handling**: Built-in OTP sending, verification, and resend countdown
✅ **PAN Retry**: Automatically clears PAN field and allows retry on failure
✅ **Progress Indicator**: Optional progress bar showing current step
✅ **Error Handling**: Comprehensive error messages with auto-dismiss
✅ **Customizable**: Title, progress, and callbacks can be customized
✅ **Loading States**: Built-in loading indicators for all async operations

## Usage

### Basic Usage

```dart
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';

// In your screen
UniversalPanVerificationWidget(
  onSuccess: (panData) {
    // Handle successful PAN verification
    print('PAN verified: ${panData['pan_number']}');
    print('Name: ${panData['name_at_source']}');
    print('DOB: ${panData['dob_at_source']}');
    
    // Navigate to next screen
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => NextScreen(panData: panData),
    ));
  },
  onError: (error) {
    // Handle errors (optional)
    print('Error: $error');
  },
)
```

### Advanced Usage with Pre-filled Data

```dart
UniversalPanVerificationWidget(
  // Pre-fill phone number (user won't need to enter it)
  phoneNumber: '+919876543210',
  isPhoneValidated: true, // Skip phone validation
  
  // Pre-fill PAN number
  panNumber: 'ABCDE1234F',
  
  // Custom title
  title: 'Verify Your Identity',
  
  // Show progress indicator
  showProgress: true,
  currentStep: 1,
  totalSteps: 6,
  
  // Callbacks
  onSuccess: (panData) {
    // Handle success
  },
  onError: (error) {
    // Handle error
  },
)
```

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `phoneNumber` | `String?` | No | `null` | Pre-filled phone number (without country code) |
| `isPhoneValidated` | `bool` | No | `false` | Whether phone is already validated |
| `panNumber` | `String?` | No | `null` | Pre-filled PAN number |
| `onSuccess` | `Function(Map<String, dynamic>)` | **Yes** | - | Called when PAN verification succeeds |
| `onError` | `Function(String)?` | No | `null` | Called when an error occurs |
| `title` | `String?` | No | `null` | Custom title for the screen |
| `showProgress` | `bool` | No | `true` | Show progress indicator |
| `currentStep` | `int` | No | `1` | Current step number for progress |
| `totalSteps` | `int` | No | `6` | Total steps for progress |

## Flow Scenarios

### Scenario 1: New User (No Phone Validation)

```dart
UniversalPanVerificationWidget(
  onSuccess: (panData) { /* ... */ },
)
```

**Flow:**
1. User enters phone number → "SEND OTP" button
2. OTP sent → User enters OTP → "VERIFY OTP" button
3. OTP verified → User enters PAN → "VERIFY PAN" button
4. PAN verified → `onSuccess` callback triggered

### Scenario 2: Phone Already Validated

```dart
UniversalPanVerificationWidget(
  phoneNumber: '+919876543210',
  isPhoneValidated: true,
  onSuccess: (panData) { /* ... */ },
)
```

**Flow:**
1. User enters PAN → "VERIFY PAN" button
2. PAN verified → `onSuccess` callback triggered

### Scenario 3: PAN Verification Fails

```dart
UniversalPanVerificationWidget(
  phoneNumber: '+919876543210',
  isPhoneValidated: true,
  onSuccess: (panData) { /* ... */ },
)
```

**Flow:**
1. User enters PAN → "VERIFY PAN" button
2. PAN verification fails → Error message shown
3. PAN field automatically cleared
4. User can re-enter PAN and try again

## Response Data Structure

The `onSuccess` callback receives a `Map<String, dynamic>` with the following structure:

```dart
{
  "pan_number": "ABCDE1234F",
  "kyc_id": 42,
  "kyc_status": "VALID",
  "is_name_matched": true,
  "is_dob_matched": true,
  "name_at_source": "JOHN DOE",
  "dob_at_source": "1990-01-01",
  "self": true, // true if user's own PAN, false for joint holder
  "onboarding_status": "BANK",
  "prefilled_from_db": false
}
```

## Integration Examples

### Example 1: BSE Onboarding Journey

```dart
class BseOnboardingScreen extends StatefulWidget {
  @override
  State<BseOnboardingScreen> createState() => _BseOnboardingScreenState();
}

class _BseOnboardingScreenState extends State<BseOnboardingScreen> {
  int _currentStep = 0;
  Map<String, dynamic>? _panData;

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return UniversalPanVerificationWidget(
        showProgress: true,
        currentStep: 1,
        totalSteps: 6,
        onSuccess: (panData) {
          setState(() {
            _panData = panData;
            _currentStep = 1; // Move to next step
          });
        },
      );
    }
    
    // Other steps...
    return NextStepWidget(panData: _panData);
  }
}
```

### Example 2: Quick PAN Verification

```dart
class QuickPanVerification extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UniversalPanVerificationWidget(
      title: 'Quick PAN Check',
      showProgress: false, // Hide progress bar
      onSuccess: (panData) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('PAN Verified'),
            content: Text('Name: ${panData['name_at_source']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
      onError: (error) {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }
}
```

### Example 3: Joint Holder Addition

```dart
class AddJointHolderScreen extends StatelessWidget {
  final String primaryHolderPhone;

  const AddJointHolderScreen({required this.primaryHolderPhone});

  @override
  Widget build(BuildContext context) {
    return UniversalPanVerificationWidget(
      title: 'Add Joint Holder',
      phoneNumber: primaryHolderPhone,
      isPhoneValidated: true, // Use primary holder's phone
      onSuccess: (panData) {
        if (panData['self'] == false) {
          // This is a joint holder
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JointHolderDetailsScreen(
                panData: panData,
              ),
            ),
          );
        } else {
          // Error: Cannot add self as joint holder
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot add your own PAN as joint holder')),
          );
        }
      },
    );
  }
}
```

## Error Handling

The widget handles the following error scenarios:

1. **Invalid Phone Number**: Shows error if phone format is incorrect
2. **OTP Send Failure**: Shows error and allows retry
3. **Invalid OTP**: Shows error and allows re-entry
4. **PAN Verification Failure**: Shows error, clears PAN field, allows retry
5. **Network Errors**: Shows generic error message

All errors are:
- Displayed in a red error box
- Auto-dismissed after 5 seconds
- Passed to `onError` callback if provided

## Customization

### Custom Styling

The widget uses the app's theme colors from `AppColors`:
- `darkBackground`: Background color
- `darkCardBG`: Input field background
- `darkPrimary`: Primary accent color

To customize, modify these colors in your theme configuration.

### Custom Validation

The widget uses standard validation:
- **Phone**: 10 digits, Indian format
- **PAN**: 10 characters, format `ABCDE1234F`

To modify validation, edit the `_validateForm()` method in the widget.

## Dependencies

- `flutter_screenutil`: For responsive sizing
- `get`: For navigation
- `OnboardingV2Service`: For API calls

## API Integration

The widget calls the following APIs:

1. **Send OTP**: `POST /api/v2/profile/contact/otp/`
2. **Verify OTP**: `POST /api/v2/profile/contact/otp/verify/`
3. **Verify PAN**: `POST /api/v2/profile/pan/verify/`

Ensure your backend supports these endpoints.

## Best Practices

1. ✅ **Always handle the `onSuccess` callback** - This is where you navigate to the next screen
2. ✅ **Use `isPhoneValidated: true`** if phone is already verified to skip phone validation
3. ✅ **Show progress indicator** for multi-step flows
4. ✅ **Provide `onError` callback** for custom error handling
5. ✅ **Pre-fill data** when available to improve UX

## Troubleshooting

### Issue: Widget shows phone input even though phone is validated

**Solution**: Set `isPhoneValidated: true` and provide `phoneNumber`

```dart
UniversalPanVerificationWidget(
  phoneNumber: '+919876543210',
  isPhoneValidated: true, // ← Add this
  onSuccess: (panData) { /* ... */ },
)
```

### Issue: PAN verification keeps failing

**Solution**: Check backend API response and error messages. Enable logging:

```dart
AppLogger.info('PAN verification response', tag: 'UniversalPanVerification');
```

### Issue: OTP not being sent

**Solution**: Verify phone number format and backend API availability

## Migration Guide

### Migrating from Old PAN Verification Flow

**Old Code:**
```dart
// Step 1: Collect PAN + Phone
PanPhoneCollection(
  onNext: (pan, phone) {
    // Step 2: Send OTP
    // Step 3: Verify OTP
    // Step 4: Verify PAN
  },
)
```

**New Code:**
```dart
// All in one widget!
UniversalPanVerificationWidget(
  onSuccess: (panData) {
    // Done! PAN verified
  },
)
```

## Support

For issues or questions, contact the development team or check the main documentation.

---

**Version**: 1.0.0  
**Last Updated**: April 2026  
**Author**: Networth Tracker Team
