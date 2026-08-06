import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_parser.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Simple service to fetch raw asset data directly from API
/// Handles all asset types: banks, equity, ETF, mutual funds
/// Fetches data directly from data.details, data.summary, and data.gainsbyasset
class RawAssetService {

  /// Fetches the full data result object from API (Summary, Details, GainsByAsset)
  /// Returns the "data" object from the response
  Future<Map<String, dynamic>> getDataResult() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        return {};
      }

      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      
      if (data == null || data is! Map<String, dynamic>) {
        print('RawAssetService.getDataResult: No data object found');
        return {};
      }
      
      return data;
    } catch (e) {
      print('RawAssetService.getDataResult error: $e');
      return {};
    }
  }

  /// Fetches summary data from API response
  /// Returns map with summary fields like totalmfamount, totalequitiesamount, etc.
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        return {};
      }

      final responseData = jsonDecode(response.body);
      
      // Navigate to summary object
      final summary = responseData['data']?['summary'];
      if (summary == null || summary is! Map<String, dynamic>) {
        print('RawAssetService.getSummary: No summary found at data.summary');
        return {};
      }
      
      print('RawAssetService.getSummary: Found summary with totalmfamount=${summary['totalmfamount']}, totalequitiesamount=${summary['totalequitiesamount']}, totaletfamount=${summary['totaletfamount']}');
      return summary;
    } catch (e) {
      print('RawAssetService.getSummary error: $e');
      return {};
    }
  }

  /// Fetches gainsbyasset data from API response
  /// Returns map with gain data for each asset type (mf, equities, etf, bank, nps, insurance)
  Future<Map<String, dynamic>> getGainsByAsset() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        return {};
      }

      final responseData = jsonDecode(response.body);
      
      // Navigate to gainsbyasset object
      final gainsbyasset = responseData['data']?['gainsbyasset'];
      if (gainsbyasset == null || gainsbyasset is! Map<String, dynamic>) {
        print('RawAssetService.getGainsByAsset: No gainsbyasset found at data.gainsbyasset');
        return {};
      }
      
      print('RawAssetService.getGainsByAsset: Found gainsbyasset with keys: ${gainsbyasset.keys.join(", ")}');
      return gainsbyasset;
    } catch (e) {
      print('RawAssetService.getGainsByAsset error: $e');
      return {};
    }
  }

  /// Fetches assets from details object (e.g., details.equities, details.etf, details.mf)
  /// Returns list of properly formatted asset objects directly from data.details
  Future<List<Map<String, dynamic>>> _getDetailsAssets(String assetType) async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        print('RawAssetService._getDetailsAssets: API call failed');
        return [];
      }

      final responseData = jsonDecode(response.body);
      
      // Navigate to details object (path: data.details)
      final details = responseData['data']?['details'];
      if (details == null || details is! Map<String, dynamic>) {
        print('RawAssetService._getDetailsAssets: No details found at data.details');
        return [];
      }
      
      print('RawAssetService._getDetailsAssets: Found details with keys: ${details.keys.join(", ")}');

      // Get the specific asset type array
      final assetArray = details[assetType];
      if (assetArray == null || assetArray is! List) {
        print('RawAssetService._getDetailsAssets: No $assetType array found in details');
        print('RawAssetService._getDetailsAssets: details[$assetType] = $assetArray');
        return [];
      }

      print('RawAssetService._getDetailsAssets: $assetType array has ${assetArray.length} items');

      // Convert to List<Map<String, dynamic>>
      final assets = assetArray
          .where((item) => item is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
      
      print('RawAssetService._getDetailsAssets: Fetched ${assets.length} $assetType from data.details');
      
      // Log first item for debugging (only for ETF)
      if (assetType == 'etf' && assets.isNotEmpty) {
        print('RawAssetService._getDetailsAssets: First ETF item: ${assets.first}');
      }
      
      return assets;
    } catch (e) {
      print('RawAssetService._getDetailsAssets error: $e');
      return [];
    }
  }


  /// Convenience methods for specific asset types - fetches directly from data.details
  Future<List<Map<String, dynamic>>> getAllEquities() async {
    return _getDetailsAssets('equities');
  }

  Future<List<Map<String, dynamic>>> getAllBanks() async {
    return _getDetailsAssets('bank');
  }

  Future<List<Map<String, dynamic>>> getAllMutualFunds() async {
    return _getDetailsAssets('mf');
  }

  Future<List<Map<String, dynamic>>> getAllETFs() async {
    return _getDetailsAssets('etf');
  }

  Future<List<Map<String, dynamic>>> getAllInsurance() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        return [];
      }

      final responseData = jsonDecode(response.body);
      
      // Debug: Check the full response structure
      print('RawAssetService.getAllInsurance: Checking response structure...');
      print('Response keys: ${responseData.keys}');
      print('Data keys: ${responseData['data']?.keys}');
      print('aaData keys: ${responseData['data']?['aaData']?.keys}');
      print('insurance_policies keys: ${responseData['data']?['aaData']?['insurance_policies']?.keys}');
      
      // Get insurance details
      final insuranceList = await _getDetailsAssets('insurance');
      
      // Get transactions from aaData.insurance_policies.transactions
      final transactionsData = responseData['data']?['aaData']?['insurance_policies.transactions'] as List<dynamic>?;
      print('Raw transactions data: $transactionsData');
      
      List<List<dynamic>> transactions = [];
      
      if (transactionsData != null && transactionsData.isNotEmpty) {
        // Convert to List<List<dynamic>> format
        transactions = transactionsData.map((item) {
          if (item is List) {
            return item.map((field) => field).toList();
          }
          return [item];
        }).toList();
        print('Processed transactions: $transactions');
      } else {
        print('No transactions found at data.aaData.insurance_policies.transactions');
      }
      
      // Merge transactions and count with insurance data
      final insuranceWithTransactions = insuranceList.map((insurance) {
        final Map<String, dynamic> insuranceWithTx = Map<String, dynamic>.from(insurance);
        
        // Add transactions if available
        if (transactions.isNotEmpty) {
          insuranceWithTx['transactions'] = transactions;
          // Use the existing count field from API response
          insuranceWithTx['count'] = insurance['count'] ?? 0;
        } else {
          insuranceWithTx['transactions'] = <List<dynamic>>[];
          insuranceWithTx['count'] = insurance['count'] ?? 0;
        }
        
        return insuranceWithTx;
      }).toList();
      
      print('RawAssetService.getAllInsurance: Fetched ${insuranceWithTransactions.length} insurance with transactions');
      return insuranceWithTransactions;
    } catch (e) {
      print('RawAssetService.getAllInsurance error: $e');
      return [];
    }
  }


  /// Fetches NPS data with transactions from API response
  Future<List<Map<String, dynamic>>> getAllNPS() async {
    try {
      print('RawAssetService.getAllNPS: Checking response structure...');
      
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        print('RawAssetService.getAllNPS: API call failed');
        return [];
      }
      
      final responseData = jsonDecode(response.body!);
      
      print('Response keys: ${responseData.keys}');
      print('Data keys: ${responseData['data']?.keys}');
      print('aaData keys: ${responseData['data']?['aaData']?.keys}');
      
      // Get NPS details
      final npsList = await _getDetailsAssets('nps');
      
      // Get transactions from aaData.nps.transactions
      final transactionsData = responseData['data']?['aaData']?['nps.transactions'] as List<dynamic>?;
      print('Raw NPS transactions data: $transactionsData');
      
      List<List<dynamic>> transactions = [];
      
      if (transactionsData != null && transactionsData.isNotEmpty) {
        // Convert to List<List<dynamic>> format
        transactions = transactionsData.map((item) {
          if (item is List) {
            return item.map((field) => field).toList();
          }
          return [item];
        }).toList();
        print('Processed NPS transactions: ${transactions.length} items');
      } else {
        print('No NPS transactions found at data.aaData.nps.transactions');
      }
      
      // Merge transactions and count with NPS data
      final npsWithTransactions = npsList.map((nps) {
        final Map<String, dynamic> npsWithTx = Map<String, dynamic>.from(nps);
        
        // Add transactions if available
        if (transactions.isNotEmpty) {
          npsWithTx['transactions'] = transactions;
          
          // Calculate policy-specific transaction count
          final npsAccountGuid = nps['accountguid']?.toString() ?? '';
          final cleanNpsAccountGuid = npsAccountGuid.replaceFirst('account|', '');
          
          int policyTransactionCount = 0;
          // Skip header row (index 0) and count transactions that belong to this policy
          for (int i = 1; i < transactions.length; i++) {
            final transaction = transactions[i];
            if (transaction != null && transaction.length >= 12) {
              final transactionLinkedAccRef = transaction[0]?.toString() ?? '';
              if (transactionLinkedAccRef == cleanNpsAccountGuid) {
                policyTransactionCount++;
              }
            }
          }
          
          npsWithTx['count'] = policyTransactionCount;
        } else {
          npsWithTx['transactions'] = <List<dynamic>>[];
          npsWithTx['count'] = 0;
        }
        
        return npsWithTx;
      }).toList();
      
      print('RawAssetService.getAllNPS: Fetched ${npsWithTransactions.length} NPS with transactions');
      return npsWithTransactions;
    } catch (e) {
      print('RawAssetService.getAllNPS error: $e');
      return [];
    }
  }

  /// Fetches bank transactions from aaData section of the API response
  Future<List<Map<String, dynamic>>> getBankTransactions() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      
      if (response == null || response.statusCode != 200) {
        print('RawAssetService.getBankTransactions: API call failed');
        return [];
      }

      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return [];
      }

      final aaData = data['aaData'];
      if (aaData == null || aaData is! Map<String, dynamic>) {
        print('RawAssetService.getBankTransactions: No aaData found');
        return [];
      }

      final List<Map<String, dynamic>> allTransactions = [];

      for (final entry in aaData.entries) {
        final key = entry.key.toString().toLowerCase().trim();
        final value = entry.value;

        // Pattern matching for bank-related transaction keys
        final isBankTxnKey = key.endsWith('.transactions') && (
          key.startsWith('deposit.') ||
          key.startsWith('rd.') ||
          key.startsWith('td.') ||
          key.startsWith('banks.') ||
          key.contains('deposit')
        );

        if (isBankTxnKey && value is List && value.isNotEmpty) {
          final mappedTxns = FinarkeinDataResultParser.arrayOfArraysToMaps(value);
          allTransactions.addAll(mappedTxns);
          print('RawAssetService.getBankTransactions: Added ${mappedTxns.length} transactions from $key');
        }
      }

      print('RawAssetService.getBankTransactions: Total fetched ${allTransactions.length} bank transactions');
      return allTransactions;
    } catch (e) {
      print('RawAssetService.getBankTransactions error: $e');
      return [];
    }
  }
}
