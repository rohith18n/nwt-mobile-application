import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_parser.dart';

/// Shared mapper: GET aa/data/result response → FipStatusResponse for account list UI.
/// Used by SaafeDataFetch and Dashboard so Finarkein account list is built in one place.
class FinarkeinDataResultMapper {
  /// Maps data/result [response] to FipStatusResponse. [userguid] is used for each Datum.
  /// Supports ReBIT-style data['Account'] and Finarkein array-of-arrays (equities.summary, etc.).
  static FipStatusResponse? mapDataResultToFipStatus(
    Map<String, dynamic> response,
    String userguid,
  ) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) return null;

    final now = DateTime.now();
    final status = (response['status'] ?? 'SUCCESS').toString().toUpperCase();
    final fetchStatus =
        status == 'SUCCESS' ? 'SUCCESS' : (status == 'FAILED' ? 'FAILED' : 'FETCHING');

    // ReBIT-style: data['Account'] array
    final accountList = data['Account'];
    if (accountList is List && accountList.isNotEmpty) {
      final List<Datum> dataList = [];
      for (int i = 0; i < accountList.length; i++) {
        final acc = accountList[i];
        if (acc is! Map<String, dynamic>) continue;
        final fitype = (acc['FIType'] ?? acc['fiType'] ?? 'ACCOUNT').toString();
        final linkedAccRef =
            (acc['linkedAccRef'] ?? acc['linked_acc_ref'] ?? '').toString();
        final maskedAccNumber =
            (acc['maskedAccNumber'] ?? acc['masked_acc_number'] ?? '').toString();
        final fipname = maskedAccNumber.isNotEmpty
            ? maskedAccNumber
            : (linkedAccRef.isNotEmpty ? 'Account $linkedAccRef' : 'Account');
        dataList.add(Datum(
          userguid: userguid,
          type: fitype,
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: linkedAccRef.isNotEmpty ? linkedAccRef : 'finarkein-$i',
          fipid: 'finarkein',
          fipname: fipname,
          fetchstatus: fetchStatus,
          balancedatetime: now,
          imageurl: null,
        ));
      }
      return FipStatusResponse(
        statusCode: 200,
        message: 'OK',
        FIPStatusData: dataList,
        last_fetch_date_time_mfc: null,
        can_fetch_mfc: false,
      );
    }

    // Finarkein array-of-arrays: parse and build Datum from each asset type
    final parsed = FinarkeinDataResultParser.parse(data);
    final List<Datum> dataList = [];
    int index = 0;
    for (final b in parsed.banks) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'DEPOSIT',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: b.guid,
        fipid: 'finarkein',
        fipname: b.fipname,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final s in parsed.stocks) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'EQUITIES',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: s.guid,
        fipid: 'finarkein',
        fipname: s.name,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final m in parsed.mf) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'MUTUAL_FUNDS',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: m.guid,
        fipid: 'finarkein',
        fipname: m.name,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final e in parsed.etf) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'ETF',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: e.guid,
        fipid: 'finarkein',
        fipname: e.name,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final i in parsed.insurance) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'INSURANCE',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: i.accountguid,
        fipid: 'finarkein',
        fipname: i.policyname,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final row in parsed.npsRows) {
      final guid = (row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['guid'] ?? 'nps-$index')
          .toString();
      final fipname = (row['issuerName'] ?? row['issuer_name'] ?? row['fipname'] ??
              row['accountName'] ?? 'NPS')
          .toString();
      dataList.add(Datum(
        userguid: userguid,
        type: 'NPS',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: guid,
        fipid: 'finarkein',
        fipname: fipname,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    for (final p in parsed.personalAssets) {
      dataList.add(Datum(
        userguid: userguid,
        type: 'PERSONAL_ASSETS',
        activestatus: true,
        fetchstatusupdatedat: now,
        guid: 'pa-${p.id}',
        fipid: 'finarkein',
        fipname: p.title,
        fetchstatus: fetchStatus,
        balancedatetime: now,
        imageurl: null,
      ));
      index++;
    }
    if (dataList.isEmpty) return null;
    return FipStatusResponse(
      statusCode: 200,
      message: 'OK',
      FIPStatusData: dataList,
      last_fetch_date_time_mfc: null,
      can_fetch_mfc: false,
    );
  }
}
