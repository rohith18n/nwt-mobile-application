# Analytics Specification Template

## 1. Purpose of This Document

This document serves as a **parent template** and reference guide for creating feature-specific analytics events lists. It is not a feature specification itself, but rather a reusable framework that defines the principles, patterns, and standards for analytics tracking.

**How to Use This Template:**

Use this document with a simple AI prompt to automatically generate feature-specific analytics events files. The prompt references this parent file and your feature name, and the AI will:

1. Read this parent template to understand analytics principles
2. Analyze your codebase to identify screens and user actions
3. Generate a new file with all events organized by screen
4. Include event names, action descriptions, and implementation locations

**Simple Prompt Format:**
```
Create analytics file with events using @analytics_parent.md condition and create a file output with all the Events by Screen for the [YOUR_FEATURE_NAME] feature.
```

This template ensures consistency across all analytics specifications and helps Product Managers and Developers align on what to track, how to name events, and where to implement analytics instrumentation.

---

## 2. Feature & Flow Metadata (Dynamic)

### Feature Information

- **Feature Name**: `{{feature_name}}`
- **Flow Name**: `{{flow_name}}`
- **User Type**: `{{user_type}}`

### Flow Context

- **Entry Points**: `{{entry_points}}`
  - Describe where users can enter this flow (e.g., from dashboard, deep link, notification, etc.)

- **Exit Conditions**: `{{exit_conditions}}`
  - Describe successful completion states
  - Describe natural exit points (e.g., user navigates away, closes app)

- **Failure Scenarios**: `{{failure_scenarios}}`
  - List all known failure modes (validation errors, API failures, network issues, etc.)

---

## 3. Analytics Design Principles

### Screen-First Thinking

Analytics should be organized around screens, not buttons or UI elements. Every screen represents a distinct user context and decision point. When designing events, start by identifying:

1. **What screen is the user on?**
2. **What meaningful action are they taking?**
3. **What is the outcome of that action?**

### Intent + Outcome Tracking

Events must capture **user intent** and **outcome**, not just UI interactions. Avoid tracking generic button clicks. Instead, track what the user is trying to accomplish.

**Bad Examples:**
- `next_clicked`
- `button_pressed`
- `cta_clicked`

**Good Examples:**
- `{{feature_name}}_verification_initiated`
- `{{feature_name}}_verification_success`
- `{{feature_name}}_verification_failed`

### Success, Failure, and Abandon Coverage

Every user action that can succeed, fail, or be abandoned should have corresponding events:

- **Success**: User completes the intended action successfully
- **Failure**: User attempts the action but it fails (validation, API error, etc.)
- **Abandon**: User starts an action but leaves before completion

### Analytics Constants Usage

All event names must be defined as constants in `lib/constants/analytics.dart` before implementation. This ensures:

- Type safety
- Easy refactoring
- Consistent naming across the codebase
- Single source of truth for event names

### Unified Analytics Service

The application uses a unified `AnalyticsService` that wraps multiple analytics platforms:

- **Firebase Analytics**
- **CleverTap**
- **AppsFlyer**

**Important**: Events are called **once** via `AnalyticsService.to.logEvent()` and are automatically sent to all platforms. You do not need to call each platform separately.

**Implementation Pattern:**
```dart
// Define constant first in lib/constants/analytics.dart
static const String myFeatureActionCompleted = 'my_feature_action_completed';

// Then use in code
await AnalyticsService.to.logEvent(
  name: AnalyticsEvents.myFeatureActionCompleted,
  parameters: {
    'parameter_name': parameterValue,
  },
);
```

---

## 4. Screen → Action Inventory Template

For each screen in the flow, identify all meaningful user actions and their outcomes. Use the following format:

### Template Format

```
<Screen Name> → <User Action> → <Outcome (if applicable)>
```

### Instructions for Writing Actions

1. **Start with the screen context**: What screen is the user on?
2. **Identify the user's intent**: What are they trying to accomplish?
3. **Capture the outcome**: Did it succeed, fail, or was it abandoned?

### Example Structure (Replace with Your Screens)

- **Screen: `{{screen_name_1}}`**
  - `{{screen_name_1}}` → `{{meaningful_action_1}}` → `{{outcome_if_applicable}}`
  - `{{screen_name_1}}` → `{{meaningful_action_2}}` → `{{outcome_if_applicable}}`

- **Screen: `{{screen_name_2}}`**
  - `{{screen_name_2}}` → `{{meaningful_action_1}}` → `{{outcome_if_applicable}}`
  - `{{screen_name_2}}` → `{{meaningful_action_2}}` → `{{outcome_if_applicable}}`

### Action Naming Guidelines

- Use verb phrases that describe user intent: `verification_initiated`, `details_submitted`, `consent_confirmed`
- Include the outcome in the event name when applicable: `verification_success`, `verification_failed`
- Use snake_case consistently
- Prefix with feature/flow name when needed for clarity: `{{feature_name}}_{{action}}`

---

## 5. Failure & Edge Case Tracking Template

### Validation Failures

Track when user input fails validation:

- **Event Pattern**: `{{feature_name}}_{{action}}_validation_failed`
- **Parameters to Include**:
  - `error_type`: Type of validation error (e.g., "format_invalid", "required_field_missing")
  - `field_name`: Which field failed validation (if applicable)
  - `error_message`: Human-readable error message

### API Failures

Track when backend API calls fail:

- **Event Pattern**: `{{feature_name}}_{{action}}_failed`
- **Parameters to Include**:
  - `error_code`: API error code (if available)
  - `error_message`: Error message from API
  - `http_status_code`: HTTP status code (if applicable)
  - `retry_attempted`: Whether user or system attempted retry

### User Abandon Scenarios

Track when users start an action but leave before completion:

- **Event Pattern**: `{{feature_name}}_{{action}}_abandoned`
- **Parameters to Include**:
  - `abandon_point`: Where in the flow the user abandoned (screen name or step)
  - `time_spent_seconds`: How long the user spent before abandoning
  - `progress_percentage`: How far through the flow the user got (if applicable)

### Network Failures

Track when network issues prevent actions:

- **Event Pattern**: `{{feature_name}}_{{action}}_network_error`
- **Parameters to Include**:
  - `error_type`: Type of network error (e.g., "timeout", "no_connection", "server_error")
  - `retry_attempted`: Whether retry was attempted

---

## 6. Flow Completion & Drop-off Template

### Flow Completed Successfully

Track when users successfully complete the entire flow:

- **Event Pattern**: `{{flow_name}}_completed`
- **Parameters to Include**:
  - `completion_time_seconds`: Total time to complete the flow
  - `screens_visited`: Number of screens visited
  - `retry_count`: Number of retries needed (if applicable)
  - `entry_point`: How the user entered the flow

### Flow Dropped Before Completion

Track when users exit the flow without completing it:

- **Event Pattern**: `{{flow_name}}_dropped`
- **Parameters to Include**:
  - `drop_off_screen`: Last screen the user was on
  - `time_spent_seconds`: Total time spent in flow
  - `screens_visited`: Number of screens visited before dropping
  - `exit_reason`: Reason for exit if known (e.g., "user_navigation", "app_backgrounded", "error")

### Flow Progress Tracking

Consider tracking progress at key milestones:

- **Event Pattern**: `{{flow_name}}_milestone_reached`
- **Parameters to Include**:
  - `milestone_name`: Name of the milestone (e.g., "verification_complete", "consent_given")
  - `milestone_number`: Sequential number of milestone
  - `total_milestones`: Total number of milestones in flow
  - `time_to_milestone_seconds`: Time taken to reach this milestone

---

## 7. Naming & Constants Guidance

### snake_case Naming Convention

All event names must use snake_case (lowercase letters with underscores):

- ✅ `feature_verification_success`
- ✅ `user_consent_confirmed`
- ❌ `featureVerificationSuccess` (camelCase)
- ❌ `Feature-Verification-Success` (kebab-case)
- ❌ `FEATURE_VERIFICATION_SUCCESS` (SCREAMING_SNAKE_CASE)

### Central Analytics Constants File

All event names must be defined in `lib/constants/analytics.dart`:

**File Structure:**
```dart
class AnalyticsEvents {
  // Feature-specific events
  static const String {{feature_name}}_{{action}} = '{{feature_name}}_{{action}}';
  // ... more events
}

class AnalyticsParams {
  // Common parameters
  static const String errorMessage = 'error_message';
  static const String errorCode = 'error_code';
  
  // Feature-specific parameters
  static const String {{parameter_name}} = '{{parameter_name}}';
  // ... more parameters
}
```

### Platform-Agnostic Event Design

Events are designed to work across all analytics platforms (Firebase Analytics, CleverTap, AppsFlyer). Follow these guidelines:

1. **Event Name Length**: Keep event names under 40 characters when possible
2. **Parameter Names**: Use descriptive, consistent parameter names
3. **Parameter Types**: All parameter values must be strings (convert booleans, integers, and doubles using `.toString()`)
4. **Parameter Count**: Limit to essential parameters (most platforms have limits)
5. **No Platform-Specific Logic**: Event names and parameters should not reference specific platforms

### Event Naming Patterns

- **Action Initiated**: `{{feature_name}}_{{action}}_initiated`
- **Action Success**: `{{feature_name}}_{{action}}_success`
- **Action Failed**: `{{feature_name}}_{{action}}_failed`
- **Action Cancelled**: `{{feature_name}}_{{action}}_cancelled`
- **Action Abandoned**: `{{feature_name}}_{{action}}_abandoned`

### Parameter Naming Patterns

- **Error Information**: `error_message`, `error_code`, `error_type`
- **Timing**: `time_spent_seconds`, `completion_time_seconds`
- **Progress**: `progress_percentage`, `step_number`, `total_steps`
- **Context**: `screen_name`, `entry_point`, `user_type`

### Parameter Value Type Requirements

**IMPORTANT: All parameter values must be converted to strings.**

When adding analytics parameters, **always convert integer and boolean values to strings** to ensure consistency across all analytics platforms (Firebase Analytics, CleverTap, AppsFlyer) and maintain data type consistency.

**Required Conversions:**

1. **Boolean Values** → Convert to string using `.toString()`:
   ```dart
   // ✅ Correct
   parameters: {
     AnalyticsParams.isFamilyMode: _isFamilyMode.toString(),
     AnalyticsParams.isLinked: isLinked.toString(),
     AnalyticsParams.isVisible: _isAmountVisible.toString(),
   }
   
   // ❌ Incorrect
   parameters: {
     AnalyticsParams.isFamilyMode: _isFamilyMode,  // boolean
     AnalyticsParams.isLinked: isLinked,  // boolean
     AnalyticsParams.isVisible: _isAmountVisible,  // boolean
   }
   ```

2. **Integer Values** → Convert to string using `.toString()`:
   ```dart
   // ✅ Correct
   parameters: {
     AnalyticsParams.transactionCount: (widget.count ?? 0).toString(),
     AnalyticsParams.accountsCount: (response.FIPStatusData?.length ?? 0).toString(),
     AnalyticsParams.pollingIntervalSeconds: _pollingInterval.inSeconds.toString(),
   }
   
   // ❌ Incorrect
   parameters: {
     AnalyticsParams.transactionCount: widget.count ?? 0,  // int
     AnalyticsParams.accountsCount: response.FIPStatusData?.length ?? 0,  // int
     AnalyticsParams.pollingIntervalSeconds: _pollingInterval.inSeconds,  // int
   }
   ```

3. **Double/Float Values** → Convert to string using `.toString()`:
   ```dart
   // ✅ Correct
   parameters: {
     AnalyticsParams.marketValue: widget.currentMarketValue.toString(),
     AnalyticsParams.gainLossPercentage: (widget.gainlosspercentage ?? 0).toString(),
     AnalyticsParams.oldPrice: oldPrice.toString(),
     AnalyticsParams.newPrice: newPrice.toString(),
   }
   
   // ❌ Incorrect
   parameters: {
     AnalyticsParams.marketValue: widget.currentMarketValue,  // double
     AnalyticsParams.gainLossPercentage: widget.gainlosspercentage ?? 0,  // double
   }
   ```

4. **String Literals** → Already strings, no conversion needed:
   ```dart
   // ✅ Correct
   parameters: {
     AnalyticsParams.screenName: 'investments_main',
     AnalyticsParams.categoryName: _selectedCategory.toLowerCase(),
     AnalyticsParams.portfolioValue: '0',  // string literal for zero
   }
   ```

**Why This Matters:**

- **Consistency**: All analytics platforms receive uniform data types
- **Compatibility**: Some platforms handle string values more reliably than mixed types
- **Querying**: String values are easier to filter and segment in analytics dashboards
- **Future-proofing**: Prevents type-related issues when adding new analytics platforms

**Examples from Codebase:**

Following the pattern established with `isFamilyMode`:
```dart
// Pattern used throughout the codebase
AnalyticsParams.isFamilyMode: _isFamilyMode.toString()
```

Apply this same pattern to all boolean, integer, and double parameters:
- `isLinked` → `isLinked.toString()`
- `isVisible` → `isVisible.toString()`
- `transactionCount` → `transactionCount.toString()`
- `marketValue` → `marketValue.toString()`
- `pollingIntervalSeconds` → `pollingIntervalSeconds.toString()`
- `accountsCount` → `accountsCount.toString()`
- `adhocRemaining` → `adhocRemaining.toString()`
- `hasMfAccounts` → `hasMfAccounts.toString()`
- `canFetchMfc` → `canFetchMfc.toString()`

---

## 8. Quality Review Checklist

### PM Clarity Check

Before implementation, verify:

- [ ] All user actions that matter to the business are tracked
- [ ] Success, failure, and abandon scenarios are covered
- [ ] Event names clearly communicate what happened
- [ ] Parameters provide enough context for analysis
- [ ] Flow completion and drop-off are tracked
- [ ] Entry points and exit conditions are documented

### Dev Implementability Check

Before implementation, verify:

- [ ] All event names are defined in `lib/constants/analytics.dart`
- [ ] All parameter names are defined in `AnalyticsParams` class
- [ ] Event names follow snake_case convention
- [ ] **All parameter values are converted to strings** (booleans, integers, and doubles use `.toString()`)
- [ ] Parameter types are supported (String, int, double, bool) - but values must be strings
- [ ] No sensitive data (PII) is included in events or parameters
- [ ] Events are called via `AnalyticsService.to.logEvent()`
- [ ] Screen views are tracked using `AnalyticsService.to.logScreenView()`

### Debuggability Check

Before implementation, verify:

- [ ] Error events include sufficient context (error codes, messages)
- [ ] Failure events include information needed to diagnose issues
- [ ] Abandon events include drop-off point and time spent
- [ ] Flow completion events include timing and progress metrics
- [ ] Events are logged at the right point in the code (after action completes, not before)
- [ ] Events include user context when relevant (user type, entry point)

---

## 9. How to Generate Feature Analytics Events List

This section provides a simple prompt template for generating feature-specific analytics events lists. The output will be a file organized by screen with all events, actions, and implementation locations.

### Simple Prompt Template

Use this prompt with an AI assistant to automatically generate your feature analytics events file:

```
Create analytics file with events using @analytics_parent.md condition and create a file output with all the Events by Screen for the [FEATURE_NAME] feature.
```

**Example:**
```
Create analytics file with events using @analytics_parent.md condition and create a file output with all the Events by Screen for the payment flow feature.
```

### What the Prompt Does

When you use this prompt, the AI assistant will:

1. **Read** the `@analytics_parent.md` file to understand the analytics design principles and patterns
2. **Analyze** the codebase to identify all screens related to your feature
3. **Generate** a new file named `[feature_name]_analytics_events.md` (e.g., `payment_flow_analytics_events.md`)
4. **Organize** events by screen in the following format:

### Output Format

The generated file will follow this structure:

```markdown
# [Feature Name] Analytics Events List

A comprehensive list of user actions to track during the [feature name] flow, organized by screen with descriptive event names.

## Events by Screen

### 1. [Screen Name]

- **Screen**: [Screen Name] (`lib/screens/[path]/[file].dart`)
- **Event**: `[event_name]`
- **Action**: [Description of user action]
- **Location**: Line [number] or method name

---

### 2. [Next Screen Name]

- **Screen**: [Screen Name] (`lib/screens/[path]/[file].dart`)
- **Event**: `[event_name]`
- **Action**: [Description of user action]
- **Location**: Line [number] or method name
- **Event**: `[another_event_name]`
- **Action**: [Description of user action]
- **Location**: Line [number] or method name

---

## Summary Count

**Total Events: [X] events across [Y] screens**

1. [Screen 1]: [N] events
2. [Screen 2]: [M] events
...

## Implementation Notes

- All events use snake_case naming convention
- Event names are descriptive and indicate the action (not just generic "clicked")
- Success/failed events are separate for better analytics segmentation
- Events should be defined in `lib/constants/analytics.dart` before implementation
- All events use the unified AnalyticsService (one call triggers Firebase, CleverTap, and AppsFlyer)
```

### Key Requirements

The generated file will include:

- ✅ **Events organized by screen** - Each screen section lists all events for that screen
- ✅ **Event names in snake_case** - Following the naming convention
- ✅ **Action descriptions** - Clear description of what the user is doing
- ✅ **File locations** - Screen file paths and line numbers or method names where events should be implemented
- ✅ **Success and failure events** - Separate events for success and failure scenarios
- ✅ **Summary count** - Total events and breakdown by screen
- ✅ **Implementation notes** - Reminders about constants file and unified service

### How to Use

1. **Identify your feature name** (e.g., "payment flow", "profile setup", "investment dashboard")
2. **Use the prompt** with your feature name
3. **Review the generated file** - Check that all screens and actions are covered
4. **Add to constants file** - Define all event names in `lib/constants/analytics.dart`
5. **Implement in code** - Add analytics calls using `AnalyticsService.to.logEvent()`

### File Naming

The generated file will automatically be named:
```
[feature_name]_analytics_events.md
```

Examples:
- `payment_flow_analytics_events.md`
- `profile_setup_analytics_events.md`
- `investment_dashboard_analytics_events.md`

### Next Steps After Generation

1. **Review Events**: Verify all user actions are covered
2. **PM Review**: Share with Product Manager for clarity check
3. **Dev Review**: Share with Developer for implementability check
4. **Constants Definition**: Add event names to `lib/constants/analytics.dart`
5. **Implementation**: Implement analytics calls in the codebase
6. **Testing**: Verify events are firing correctly in all platforms (Firebase, CleverTap, AppsFlyer)

---

## Notes

- This template is intentionally generic and contains no feature-specific examples
- All placeholders must be replaced with actual feature data before use
- The unified analytics service ensures events are sent to all platforms automatically
- Always define events as constants before implementation
- Focus on user intent and outcomes, not UI interactions
