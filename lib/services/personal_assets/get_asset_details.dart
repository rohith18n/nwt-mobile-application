import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/crypto.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/land.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/money_lent.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/other.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/precious_metal.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/real_estate.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class GetAssetDetailsService {
  final NetworkAPIHelper _networkAPIHelper = NetworkAPIHelper();

  /// Get asset details by ID and type
  /// Returns the appropriate asset response type based on the asset type
  Future<dynamic> getAssetDetails(int assetId, String assetType) async {
    try {
      AppLogger.info(
        'Fetching asset details for ID: $assetId, Type: $assetType',
        tag: 'GetAssetDetailsService',
      );

      final response = await _networkAPIHelper.get(
        ApiURLs.GET_PERSONAL_ASSET_BY_ID(assetId),
      );

      if (response?.statusCode == 200) {
        final responseData = json.decode(response?.body ?? '{}');

        AppLogger.info(
          'Asset details fetched successfully for ID: $assetId: ${responseData.toString()}',
          tag: 'GetAssetDetailsService',
        );

        // Parse response based on asset type
        switch (assetType.toUpperCase()) {
          case 'REAL_ESTATE':
            return RealEstateAssetResponse.fromJson(responseData);
          case 'LAND':
            return LandAssetResponse.fromJson(responseData);
          case 'MONEY_LENT':
            return MoneyLentAssetResponse.fromJson(responseData);
          case 'CRYPTO':
            return CryptoAssetResponse.fromJson(responseData);
          case 'METAL':
            return PreciousMetalAssetResponse.fromJson(responseData);
          case 'OTHER':
            return OtherAssetResponse.fromJson(responseData);
          default:
            AppLogger.warning(
              'Unknown asset type: $assetType, returning raw response',
              tag: 'GetAssetDetailsService',
            );
            return responseData;
        }
      } else {
        AppLogger.error(
          'Failed to fetch asset details. Status: ${response?.statusCode}, Body: ${response?.body}',
          tag: 'GetAssetDetailsService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }

  /// Get Real Estate asset details specifically
  Future<RealEstateAssetResponse?> getRealEstateAssetDetails(
    int assetId,
  ) async {
    try {
      final result = await getAssetDetails(assetId, 'REAL_ESTATE');
      return result is RealEstateAssetResponse ? result : null;
    } catch (e) {
      AppLogger.error(
        'Error fetching real estate asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }

  /// Get Land asset details specifically
  Future<LandAssetResponse?> getLandAssetDetails(int assetId) async {
    try {
      final result = await getAssetDetails(assetId, 'LAND');
      return result is LandAssetResponse ? result : null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching land asset details: $e',
        tag: 'GetAssetDetailsService',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get Money Lent asset details specifically
  Future<MoneyLentAssetResponse?> getMoneyLentAssetDetails(int assetId) async {
    try {
      final result = await getAssetDetails(assetId, 'MONEY_LENT');
      return result is MoneyLentAssetResponse ? result : null;
    } catch (e) {
      AppLogger.error(
        'Error fetching money lent asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }

  /// Get Crypto asset details specifically
  Future<CryptoAssetResponse?> getCryptoAssetDetails(int assetId) async {
    try {
      final result = await getAssetDetails(assetId, 'CRYPTO');
      return result is CryptoAssetResponse ? result : null;
    } catch (e) {
      AppLogger.error(
        'Error fetching crypto asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }

  /// Get Precious Metal asset details specifically
  Future<PreciousMetalAssetResponse?> getPreciousMetalAssetDetails(
    int assetId,
  ) async {
    try {
      final result = await getAssetDetails(assetId, 'METAL');
      return result is PreciousMetalAssetResponse ? result : null;
    } catch (e) {
      AppLogger.error(
        'Error fetching precious metal asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }

  /// Get Other asset details specifically
  Future<OtherAssetResponse?> getOtherAssetDetails(int assetId) async {
    try {
      final result = await getAssetDetails(assetId, 'OTHER');
      return result is OtherAssetResponse ? result : null;
    } catch (e) {
      AppLogger.error(
        'Error fetching other asset details: $e',
        tag: 'GetAssetDetailsService',
      );
      return null;
    }
  }
}
