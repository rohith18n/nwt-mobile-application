import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/types/profile/holder.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class HolderService {
  final NetworkAPIHelper _networkHelper = NetworkAPIHelper();

  Future<HolderResponse?> listHolders() async {
    try {
      final response = await _networkHelper.get(ApiURLs.HOLDERS_LIST);
      if (response != null && response.statusCode == 200) {
        return HolderResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('Error listing holders', error: e, tag: 'HolderService');
      return null;
    }
  }

  Future<HolderResponse?> addHolder(String panNumber) async {
    try {
      final response = await _networkHelper.post(ApiURLs.HOLDERS_ADD, {
        'pan_number': panNumber,
      });
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 400)) {
        return HolderResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('Error adding holder', error: e, tag: 'HolderService');
      return null;
    }
  }

  Future<Holder?> getHolderDetail(int id) async {
    try {
      final response = await _networkHelper.get(ApiURLs.holderDetail(id));
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 400)) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['holder'] != null) {
          return Holder.fromJson(data['data']['holder']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Error getting holder detail',
        error: e,
        tag: 'HolderService',
      );
      return null;
    }
  }

  Future<Holder?> updateHolder(int id, Map<String, dynamic> data) async {
    try {
      final response = await _networkHelper.patch(
        ApiURLs.holderUpdate(id),
        data,
      );
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 400)) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          if (respData['data']['holder'] != null) {
            return Holder.fromJson(respData['data']['holder']);
          }
          return Holder.fromJson(respData['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error updating holder', error: e, tag: 'HolderService');
      return null;
    }
  }

  Future<bool> removeHolder(int id) async {
    try {
      final response = await _networkHelper.delete(ApiURLs.holderDelete(id));
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 400)) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error removing holder', error: e, tag: 'HolderService');
      return false;
    }
  }
}
