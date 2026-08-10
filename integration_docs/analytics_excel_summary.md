# User Journey Analytics Events - Excel Sheet Summary

## 📋 Document Overview
This Excel sheet contains a comprehensive list of CleverTap analytics events designed to track user journeys and identify drop-off points in the NWT mobile application. The events are organized by user funnels to help understand where users abandon the app and optimize conversion rates.

## 📊 Excel Sheet Structure

### **Columns Explained:**

| Column Name | Description | Purpose |
|-------------|-------------|---------|
| **Funnel Name** | Major user journey category (e.g., ONBOARDING FUNNEL, BSE V2 FINAL ONBOARDING) | Groups events by user flow |
| **Step Number** | Sequential step in the funnel (1, 2, 3... or "Drop-off") | Shows user progression order |
| **Event Name** | CleverTap event name (e.g., `phone_screen_viewed`) | Technical identifier for analytics |
| **Event Description** | Human-readable description of what the event tracks | Business context for the event |
| **Event Type** | Category: Screen View, Action, Success, Error, Drop-off, etc. | Classifies event purpose |
| **Drop-off Risk** | Risk level: Low/Medium/High | Identifies potential abandonment points |
| **Priority Level** | Implementation priority: Critical/High/Medium/Low | Guides development sequencing |

## 🎯 Key User Funnels Covered

### **1. ONBOARDING FUNNEL** (Critical - 40+ events)
- **Purpose**: Track new user registration and verification
- **Key Steps**: App Launch → Phone Verification → Email → PAN → Personalization
- **Drop-off Hotspots**: Phone OTP (40-60% drop-off), PAN verification (30-50% drop-off)
- **Business Impact**: First impression and user acquisition

### **2. BSE V2 FINAL ONBOARDING** (High Priority - 20+ events)
- **Purpose**: Track BSE account opening process
- **Key Steps**: Holder Details → Bank Verification → Occupation → Signature → Nominee
- **Drop-off Hotspots**: Bank verification, signature completion
- **Business Impact**: Trading account activation

### **3. DASHBOARD ENGAGEMENT** (High Priority - 15+ events)
- **Purpose**: Track user interaction with main dashboard
- **Key Steps**: First visit → Asset exploration → Navigation
- **Drop-off Hotspots**: No interaction, short sessions
- **Business Impact**: User retention and daily engagement

### **4. ACCOUNT LINKING** (Critical - 15+ events)
- **Purpose**: Track bank and investment account connections
- **Key Steps**: Provider selection → Consent → Data sync
- **Drop-off Hotspots**: Consent decline, sync failures (35-55% drop-off)
- **Business Impact**: Data aggregation and portfolio completeness

### **5. INVESTMENT JOURNEY** (High Priority - 25+ events)
- **Purpose**: Track investment discovery and actions
- **Key Steps**: Category selection → Holdings view → MF Central → Investment actions
- **Drop-off Hotspots**: MF Central QR scanning (45-65% drop-off), first investment (60-80% drop-off)
- **Business Impact**: Revenue generation and user portfolio growth

### **6. ADVISORY & RECOMMENDATIONS** (Medium Priority - 15+ events)
- **Purpose**: Track advisory service adoption
- **Key Steps**: Discovery → Strategy selection → Implementation
- **Drop-off Hotspots**: Strategy selection, implementation abandonment
- **Business Impact**: Value-added service utilization

### **7. ORDER & TRANSACTION** (High Priority - 20+ events)
- **Purpose**: Track order placement and payment processing
- **Key Steps**: Order creation → Payment → Completion
- **Drop-off Hotspots**: Payment failures, order cancellation
- **Business Impact**: Transaction completion and revenue

### **8. USER RETENTION & ENGAGEMENT** (Medium Priority - 20+ events)
- **Purpose**: Track daily usage patterns and feature adoption
- **Key Steps**: Daily sessions → Portfolio checks → Feature discovery
- **Drop-off Hotspots**: Short sessions, no actions taken
- **Business Impact**: Long-term user retention

## 🔍 How to Use This Sheet

### **For Development Team:**
1. **Priority-Based Implementation**: Start with "Critical" priority events
2. **Event Naming**: Use exact `Event Name` values in code
3. **Error Handling**: Implement all "Error" type events for troubleshooting
4. **Drop-off Detection**: Add "Drop-off" events at key abandonment points

### **For Product Team:**
1. **Funnel Analysis**: Monitor conversion rates between steps
2. **Drop-off Investigation**: Focus on "High" drop-off risk areas
3. **A/B Testing**: Use events to measure optimization impact
4. **User Journey Mapping**: Visualize complete user flows

### **For Analytics Team:**
1. **Dashboard Creation**: Build funnel visualization dashboards
2. **Alert Setup**: Configure alerts for high drop-off rates
3. **Segmentation**: Analyze user behavior by segments
4. **Reporting**: Generate weekly/monthly funnel performance reports

## 🚨 Critical Drop-off Points (Immediate Attention)

| Funnel | Step | Drop-off Rate | Impact | Recommended Action |
|--------|------|---------------|---------|-------------------|
| Onboarding | Phone OTP | 40-60% | User acquisition | Optimize OTP delivery, add retry options |
| Onboarding | PAN Verification | 30-50% | User acquisition | Improve scanning, clear consent language |
| Account Linking | Bank Connection | 35-55% | Data completeness | Simplify bank selection, better error messages |
| Investment | First Investment | 60-80% | Revenue | Reduce friction, provide guidance |
| MF Central | QR Scanning | 45-65% | Portfolio data | Alternative linking methods, better instructions |

## 📈 Implementation Phases

### **Phase 1 (Week 1-2): Critical Events**
- All ONBOARDING FUNNEL events
- Account linking drop-off events
- Payment failure events

### **Phase 2 (Week 3-4): High Priority Events**
- Dashboard engagement events
- Investment journey events
- Order and transaction events

### **Phase 3 (Week 5-6): Medium Priority Events**
- Advisory events
- Retention and engagement events
- Feature adoption events

## 🛠 Technical Implementation Notes

### **Event Implementation Pattern:**
```dart
// Example for phone screen view
AnalyticsService.to.logEvent(
  name: 'phone_screen_viewed',
  parameters: {
    'screen_name': 'phone_verification',
    'timestamp': DateTime.now().toIso8601String(),
    'session_id': getSessionId(),
  },
);
```

### **Drop-off Detection Pattern:**
```dart
// Example for phone screen abandonment
@override
void dispose() {
  AnalyticsService.to.logEvent(
    name: 'phone_screen_abandoned',
    parameters: {
      'time_on_screen': getTimeOnScreen(),
      'reason': 'screen_exit',
    },
  );
  super.dispose();
}
```

## 📊 Success Metrics

### **Key Performance Indicators (KPIs):**
- **Funnel Completion Rate**: % users completing each funnel
- **Drop-off Rate**: % users abandoning at each step
- **Time to Complete**: Average time to complete each funnel
- **Error Rate**: % users encountering errors
- **Retention Rate**: % users returning after onboarding

### **Target Benchmarks:**
- Onboarding completion: >70%
- Account linking success: >80%
- First investment conversion: >20%
- Daily active users: >40% of registered users

## 🔄 Maintenance & Updates

### **Regular Tasks:**
1. **Weekly**: Review funnel performance and drop-off rates
2. **Monthly**: Update event list based on new features
3. **Quarterly**: Analyze trends and optimize high-drop-off areas
4. **As Needed**: Add events for new features and user flows

### **Team Responsibilities:**
- **Development**: Implement events according to priority
- **Product**: Monitor funnel performance and prioritize optimizations
- **Analytics**: Create dashboards and generate insights
- **Design**: Use data to improve user experience and reduce friction

---

## 📞 Next Steps

1. **Review the Excel sheet** and identify immediate implementation priorities
2. **Assign ownership** for each funnel to specific team members
3. **Set up analytics dashboard** with the critical events
4. **Establish weekly review cadence** to monitor performance
5. **Create optimization roadmap** based on drop-off analysis

This comprehensive analytics setup will provide actionable insights to improve user experience, increase conversion rates, and drive business growth.
