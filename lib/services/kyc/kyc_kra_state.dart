// KRA state machine: (KRASUBMISSIONSTATUS, KRAKYCCOMPLETEDSTATUS) -> display state -> user message.
// Single source of truth for all KYC UI messages.

/// Display state derived from KRA submission and completed status.
enum KycKraDisplayState {
  validated,
  completed,
  pending,
  inProgress,
  rejected,
  submitted,
  notSubmitted,
  unknown,
}

/// Maps persisted status string (from [KycPanVerifyResult.statusForPersistence]) to [KycKraDisplayState].
KycKraDisplayState kraDisplayStateFromPersistedStatus(String? persisted) {
  if (persisted == null || persisted.trim().isEmpty) return KycKraDisplayState.unknown;
  final p = persisted.trim().toLowerCase().replaceAll(' ', '');
  switch (p) {
    case 'validated':
      return KycKraDisplayState.validated;
    case 'pending':
      return KycKraDisplayState.pending;
    case 'inprogress':
      return KycKraDisplayState.inProgress;
    case 'rejected':
      return KycKraDisplayState.rejected;
    default:
      return KycKraDisplayState.unknown;
  }
}

/// Maps normalized (submission, completed) status strings to [KycKraDisplayState].
KycKraDisplayState kraDisplayStateFromStatus({
  String? submissionNormalized,
  String? completedNormalized,
}) {
  final c = completedNormalized;
  final s = submissionNormalized;

  if (c == 'validated' || c == 'completed') return KycKraDisplayState.validated;
  if (c == 'rejected') return KycKraDisplayState.rejected;
  if (c == 'pending') return KycKraDisplayState.pending;
  if (c == 'inprogress' || c == 'in progress') return KycKraDisplayState.inProgress;
  if (s == 'submitted' && (c == null || c.isEmpty)) return KycKraDisplayState.submitted;
  if (s == 'notsubmitted' || s == 'not submitted') return KycKraDisplayState.notSubmitted;

  return KycKraDisplayState.unknown;
}

/// User-facing message for a given state. Use [forSnackbar] for post-WebView/polling snackbars,
/// [forErrorScreen] for pan/verify failure screen, [forCardSubtitle] for dashboard card.
String messageForKycKraState(
  KycKraDisplayState state, {
  bool forSnackbar = true,
  bool forErrorScreen = false,
  bool forCardSubtitle = false,
}) {
  if (forErrorScreen) {
    switch (state) {
      case KycKraDisplayState.unknown:
        return 'Could not verify KYC status. Please try again from the dashboard.';
      default:
        return 'Could not verify KYC status. Please try again from the dashboard.';
    }
  }

  if (forCardSubtitle) {
    switch (state) {
      case KycKraDisplayState.validated:
      case KycKraDisplayState.completed:
        return 'Validated';
      case KycKraDisplayState.pending:
        return 'Pending';
      case KycKraDisplayState.inProgress:
        return 'In progress';
      case KycKraDisplayState.rejected:
        return 'Rejected';
      case KycKraDisplayState.submitted:
        return 'Submitted';
      case KycKraDisplayState.notSubmitted:
        return 'Not submitted';
      case KycKraDisplayState.unknown:
        return 'Unknown';
    }
  }

  // forSnackbar (default)
  switch (state) {
    case KycKraDisplayState.validated:
    case KycKraDisplayState.completed:
      return "KYC verified successfully.";
    case KycKraDisplayState.pending:
      return "KYC is pending. We'll notify you when it's verified.";
    case KycKraDisplayState.inProgress:
      return "KYC is in progress. We'll notify you when it's verified.";
    case KycKraDisplayState.rejected:
      return "KYC was rejected. Please try again or contact support.";
    case KycKraDisplayState.submitted:
      return "KYC has been submitted. We'll notify you when it's verified.";
    case KycKraDisplayState.notSubmitted:
      return "KYC not yet submitted. Complete the steps to verify.";
    case KycKraDisplayState.unknown:
      return "KYC status is being updated. Check back later from the dashboard.";
  }
}
