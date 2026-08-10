# Analytics Events Implementation Guide

## 📋 Implementation Status

### ✅ Completed
1. **Analytics Constants Added** - All 295+ events added to `analytics.dart`
2. **Drop-off Detection Utility** - Created `AnalyticsDropOffDetector` with mixin support
3. **Sample Implementation** - DataFetchDetailsScreen analytics implemented

### 🚧 In Progress
1. **Critical Onboarding Events** - Phone verification, PAN, email screens
2. **BSE V2 Final Onboarding** - Complete journey tracking
3. **Dashboard Engagement** - User interaction tracking

### 📅 Pending
1. **Investment Journey Events** - MF Central, transactions, holdings
2. **Paper Trading Events** - Simulation and strategy tracking
3. **Search & Transaction Events** - Global search and transaction details
4. **Profile & Settings** - Complete settings tracking

---

## 🔧 Implementation Instructions

### **Step 1: Add Analytics Imports**
```dart
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/analytics_drop_off_detector.dart';
```

### **Step 2: Add DropOffTrackingMixin**
```dart
class _YourScreenState extends State<YourScreen> 
    with DropOffTrackingMixin {
  
  @override
  String get screenName => 'your_screen_name';
  
  @override
  void initState() {
    super.initState();
    // Your existing init code
  }
}
```

### **Step 3: Track Screen Actions**
```dart
// Button clicks, form submissions, etc.
AnalyticsService.to.logEvent(
  name: AnalyticsEvents.yourEventName,
  parameters: {
    'screen_name': screenName,
    'action': 'button_click',
    'timestamp': DateTime.now().toIso8601String(),
    // Add relevant parameters
  },
);
```

### **Step 4: Track Success/Failure**
```dart
try {
  // Your operation
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.operationCompleted,
    parameters: {'success': true},
  );
} catch (e) {
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.operationFailed,
    parameters: {'error': e.toString()},
  );
}
```

---

## 🎯 Priority Implementation Order

### **Phase 1: Critical (Week 1)**
1. **Onboarding Funnel** - Phone, Email, PAN verification
2. **BSE V2 Final Journey** - Complete onboarding flow
3. **Dashboard Engagement** - First visit, navigation, interactions
4. **Account Linking** - Data fetch, consent, sync

### **Phase 2: High Priority (Week 2)**
1. **Investment Journey** - MF Central, holdings, transactions
2. **Orders Module** - Order creation, payment, completion
3. **Profile & Settings** - User management, security settings

### **Phase 3: Medium Priority (Week 3)**
1. **Paper Trading** - Simulation, strategy, history
2. **Search Functionality** - Global search, results, filters
3. **Personal Assets** - Asset addition, management
4. **Family Features** - Multi-user functionality

---

## 📝 Screen-by-Screen Implementation

### **1. Onboarding Screens**

#### Phone Verification Screen
```dart
// Screen view
@override
void initState() {
  super.initState();
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.phoneScreenViewed,
    parameters: {'screen_name': screenName},
  );
}

// Phone number entered
onSubmitted: (phone) {
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.phoneNumberEntered,
    parameters: {'phone_length': phone.length},
  );
}

// OTP sent
onSendOtp: () {
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.phoneSubmitClicked,
    parameters: {'timestamp': DateTime.now().toIso8601String()},
  );
}
```

#### OTP Verification Screen
```dart
// OTP entered
onOtpChanged: (otp) {
  if (otp.length == 6) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.otpEntered,
      parameters: {'otp_length': otp.length},
    );
  }
}

// OTP verified
onVerified: () {
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.otpVerifiedSuccess,
    parameters: {'verification_time': 'fast'},
  );
}
```

### **2. BSE V2 Final Journey**

#### Holder Details Screen
```dart
class _BSEV2HolderDetailsScreenState extends State<BSEV2HolderDetailsScreen> 
    with DropOffTrackingMixin {
  
  @override
  String get screenName => 'bse_v2_holder_details';

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.bseV2HolderDetailsScreenViewed,
      parameters: {'screen_name': screenName},
    );
  }

  void onFormSubmitted() {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.bseV2HolderDetailsFilled,
      parameters: {
        'screen_name': screenName,
        'form_completion_time': '120_seconds',
      },
    );
    
    // Submit logic
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.bseV2HolderDetailsSubmitted,
      parameters: {'screen_name': screenName},
    );
  }
}
```

### **3. Dashboard Screens**

#### Main Dashboard
```dart
class _DashboardScreenState extends State<DashboardScreen> 
    with DropOffTrackingMixin {
  
  @override
  String get screenName => 'dashboard';

  @override
  void initState() {
    super.initState();
    
    // Check if first visit
    if (isFirstVisit) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardFirstVisit,
        parameters: {'screen_name': screenName},
      );
    }
    
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardScreenViewed,
      parameters: {'screen_name': screenName},
    );
  }

  void onAssetCardClicked(String assetType) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardAssetCardClicked,
      parameters: {
        'screen_name': screenName,
        'asset_type': assetType,
      },
    );
  }

  void onBottomTabClicked(String tabName) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardBottomTabClicked,
      parameters: {
        'screen_name': screenName,
        'tab_name': tabName,
      },
    );
  }
}
```

---

## 🚨 Error Handling & Best Practices

### **1. Always Wrap Analytics Calls**
```dart
try {
  AnalyticsService.to.logEvent(
    name: AnalyticsEvents.yourEvent,
    parameters: params,
  );
} catch (e) {
  AppLogger.error('Analytics error: $e');
  // Continue app flow - analytics should never break the app
}
```

### **2. Use Consistent Parameters**
```dart
// Standard parameters for all events
final baseParams = {
  'screen_name': screenName,
  'timestamp': DateTime.now().toIso8601String(),
  'user_id': UserController.to.user?.id,
  'session_id': getSessionId(),
};
```

### **3. Track User Progress**
```dart
// Track funnel completion
void trackFunnelCompletion(String funnelName) {
  AnalyticsService.to.logEvent(
    name: '${funnelName}_completed',
    parameters: {
      'funnel_name': funnelName,
      'completion_time': getFunnelTime(),
    },
  );
}
```

---

## 📊 Testing & Validation

### **1. Enable Debug Mode**
```dart
// In your main.dart or debug configuration
AnalyticsService.to.setDebugMode(true);
```

### **2. Verify Events in Console**
```dart
// Check console logs for event firing
AppLogger.info('Analytics event fired: $eventName');
```

### **3. Test Drop-off Detection**
```dart
// Test timeout by waiting 2+ minutes on a screen
// Test abandonment by closing app/minimizing
```

---

## 🔍 Monitoring & Optimization

### **1. Daily Checks**
- Event firing rates
- Drop-off patterns
- Error rates

### **2. Weekly Analysis**
- Funnel conversion rates
- User journey bottlenecks
- Feature adoption metrics

### **3. Monthly Optimization**
- A/B test improvements
- Implement new tracking
- Remove unused events

---

## 📞 Support & Troubleshooting

### **Common Issues**
1. **Events not firing** - Check imports and service initialization
2. **Drop-off not working** - Verify mixin implementation
3. **Parameters missing** - Ensure consistent parameter structure

### **Debug Commands**
```dart
// Test analytics service
AnalyticsService.to.logEvent(name: 'test_event');

// Check service status
print('Analytics initialized: ${AnalyticsService.to.isInitialized}');
```

---

This guide provides the complete framework for implementing analytics events across your NWT mobile application. Start with Phase 1 critical events and gradually expand coverage based on user behavior insights.
