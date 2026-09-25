import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'dart:developer' as developer;

/// Service to check if user can invest directly (skip onboarding steps)
class InvestmentReadinessService {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Check profile validation status
  /// Returns next_step: "complete" if all onboarding done
  Future<Map<String, dynamic>?> checkProfileValidation() async {
    try {
      developer.log('Checking profile validation status...');
      
      final response = await _api.get(ApiURLs.PROFILE_VALIDATE);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Profile validation response: ${data['data']}');
        return data['data'];
      }
      
      developer.log('Profile validation failed: ${response?.statusCode}');
      return null;
    } catch (e) {
      developer.log('Error checking profile validation: $e');
      return null;
    }
  }

  /// Check UCC investment readiness
  /// Returns investment_ready: true if user can invest directly
  Future<Map<String, dynamic>?> checkUccInvestmentReady({
    String holdingNature = 'SI',
    int? secondaryHolderId,
    int? nomineeHolderId,
  }) async {
    try {
      developer.log('Checking UCC investment readiness...');
      
      final body = {
        'holding_nature': holdingNature,
      };
      
      if (secondaryHolderId != null) {
        body['secondary_holder_id'] = secondaryHolderId.toString();
      }
      
      if (nomineeHolderId != null) {
        body['nominee_holder_id'] = nomineeHolderId.toString();
      }
      
      final response = await _api.post(
        ApiURLs.TRADE_UCC_RESOLVE,
        jsonEncode(body),
      );
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('UCC resolve response: ${data['data']}');
        return data['data'];
      }
      
      developer.log('UCC resolve failed: ${response?.statusCode}');
      return null;
    } catch (e) {
      developer.log('Error checking UCC readiness: $e');
      return null;
    }
  }

  /// Master check: Can user invest directly?
  /// Returns:
  /// - canInvest: true if ready to invest
  /// - uccId: UCC ID if exists
  /// - clientCode: Client code if exists
  /// - nextStep: What to show if not ready
  /// - reason: Why user can't invest (if applicable)
  Future<Map<String, dynamic>> canInvestDirectly() async {
    try {
      // Step 1: Check profile validation
      final validation = await checkProfileValidation();
      
      if (validation == null) {
        return {
          'canInvest': false,
          'reason': 'Failed to check profile status',
          'nextStep': 'error',
        };
      }
      
      final nextStep = validation['next_step'];
      
      // Optional steps that don't block investment
      const optionalSteps = ['mf_central', 'financial_aggregator', 'complete'];
      
      // Check if all required onboarding steps are complete
      if (!optionalSteps.contains(nextStep)) {
        return {
          'canInvest': false,
          'reason': 'Onboarding incomplete',
          'nextStep': nextStep,
          'validation': validation,
        };
      }
      
      // All required steps done (next step is optional or complete)
      developer.log('Required onboarding complete, next_step: $nextStep');
      
      // Step 2: Check UCC investment readiness
      final uccStatus = await checkUccInvestmentReady();
      
      if (uccStatus == null) {
        return {
          'canInvest': false,
          'reason': 'Failed to check UCC status',
          'nextStep': 'ucc_check_failed',
        };
      }
      
      final investmentReady = uccStatus['investment_ready'] == true;
      final exists = uccStatus['exists'] == true;
      
      if (investmentReady && exists) {
        // ✅ User can invest directly!
        return {
          'canInvest': true,
          'uccId': uccStatus['ucc_id'],
          'clientCode': uccStatus['client_code'],
          'paymentUpiId': uccStatus['payment_upi_id'],
          'holdingNature': uccStatus['holding_nature'],
        };
      }
      
      // UCC exists but not ready - check beta_stage
      if (exists && !investmentReady) {
        final betaStage = uccStatus['beta_stage'];
        final uccSyncPending = uccStatus['ucc_sync_pending'] == true;
        
        if (uccSyncPending) {
          return {
            'canInvest': false,
            'reason': 'UCC is syncing with BSE. Please try again in a few minutes.',
            'nextStep': 'ucc_syncing',
            'uccStatus': uccStatus,
          };
        }
        
        return {
          'canInvest': false,
          'reason': 'UCC setup incomplete',
          'nextStep': betaStage ?? 'ucc_setup',
          'uccStatus': uccStatus,
        };
      }
      
      // No UCC exists - need to create
      return {
        'canInvest': false,
        'reason': 'UCC not created',
        'nextStep': 'create_ucc',
        'uccStatus': uccStatus,
      };
      
    } catch (e) {
      developer.log('Error in canInvestDirectly: $e');
      return {
        'canInvest': false,
        'reason': 'Error checking investment readiness: $e',
        'nextStep': 'error',
      };
    }
  }

  /// Get profile details (includes all saved data)
  Future<Map<String, dynamic>?> getProfileDetails() async {
    try {
      developer.log('Fetching profile details...');
      
      final response = await _api.get(ApiURLs.PROFILE_DETAILS);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Profile details fetched successfully');
        return data['data'];
      }
      
      developer.log('Profile details fetch failed: ${response?.statusCode}');
      return null;
    } catch (e) {
      developer.log('Error fetching profile details: $e');
      return null;
    }
  }

  /// Get holders list (for checking signatures)
  Future<List<dynamic>?> getHolders() async {
    try {
      developer.log('Fetching holders list...');
      
      final response = await _api.get(ApiURLs.PROFILE_HOLDERS);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Holders fetched: ${data['data']?['holders']?.length ?? 0}');
        return data['data']?['holders'];
      }
      
      developer.log('Holders fetch failed: ${response?.statusCode}');
      return null;
    } catch (e) {
      developer.log('Error fetching holders: $e');
      return null;
    }
  }
}
