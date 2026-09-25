#!/usr/bin/env python3
"""
Script to refactor dashboard.dart to remove AA_CONSENTS and AA_DATA_FETCH dependencies.
This replaces consent-based logic with data-based logic using GET_FINARKEIN_DATA.
"""

import re

def refactor_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Step 1: Remove consent-related imports
    content = re.sub(
        r"import 'package:nwt_app/services/account_aggregators/finarkein_consents_service\.dart';\n",
        "",
        content
    )
    content = re.sub(
        r"import 'package:nwt_app/services/account_aggregators/finarkein_integration_service\.dart';\n",
        "",
        content
    )
    content = re.sub(
        r"import 'package:nwt_app/services/account_aggregators/finarkein_pending_operations\.dart';\n",
        "",
        content
    )
    content = re.sub(
        r"import 'package:nwt_app/services/dashboard/dashboard_bootstrap\.dart';\n",
        "",
        content
    )
    
    # Step 2: Replace _hasAnyFinarkeinConsentNow with _hasAnyFinarkeinDataNow
    content = re.sub(
        r'_hasAnyFinarkeinConsentNow\(\)',
        '_hasAnyFinarkeinDataNow()',
        content
    )
    
    # Step 3: Replace _finarkeinBootstrapOrNull() usage in UI logic
    # This is for the FI types check - replace with data-based check
    finarkein_fi_types_pattern = r'_finarkeinBootstrapOrNull\(\)\?\.consentedFiTypesRx\s*\.map\(\(e\) => e\.toString\(\)\.trim\(\)\.toLowerCase\(\)\)\s*\.where\(\(e\) => e\.isNotEmpty\)\s*\.toList\(\);'
    finarkein_fi_types_replacement = '''Get.isRegistered<FinarkeinDataController>()
        ? (FinarkeinDataController.to.dataResponse.value?.data?.accounts
            ?.map((acc) => acc.type?.toString().trim().toLowerCase())
            .where((e) => e != null && e.isNotEmpty)
            .toSet()
            .toList())
        : null;'''
    content = re.sub(finarkein_fi_types_pattern, finarkein_fi_types_replacement, content, flags=re.DOTALL)
    
    # Step 4: Remove FinarkeinConsentsService.resetDataResultCircuit() call
    content = re.sub(
        r'\s*FinarkeinConsentsService\.resetDataResultCircuit\(\);\n',
        '',
        content
    )
    
    # Step 5: Update _shouldShowUnlockCard to not take parameter
    content = re.sub(
        r'bool _shouldShowUnlockCard\(bool hasAnyConsent\) =>\s*!_isFamilyMode && !hasAnyConsent;',
        '''bool _shouldShowUnlockCard() {
    if (_isFamilyMode) return false;
    if (!_isFinarkeinUser()) return true;
    return !_hasAnyFinarkeinDataNow();
  }''',
        content
    )
    
    # Update calls to _shouldShowUnlockCard
    content = re.sub(
        r'_shouldShowUnlockCard\(hasAnyFinarkeinConsent\)',
        '_shouldShowUnlockCard()',
        content
    )
    
    print(f"Refactored {len(original_content) - len(content)} characters")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Refactored {file_path}")

if __name__ == '__main__':
    import sys
    file_path = sys.argv[1] if len(sys.argv) > 1 else 'lib/screens/dashboard/dashboard.dart'
    refactor_dashboard(file_path)
