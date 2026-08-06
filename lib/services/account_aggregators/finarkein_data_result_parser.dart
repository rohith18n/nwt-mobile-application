import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart'
    as invtx;
import 'package:nwt_app/screens/personal_assets/types/personal_assets_models.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';

/// Parsed result from Finarkein GET aa/data/result response (array-of-arrays per asset type).
class FinarkeinParsedResult {
  final List<Bank> banks;
  final List<Stock> stocks;
  final List<Mf> mf;
  final List<Etf> etf;
  final List<Insurance> insurance;
  final List<Map<String, dynamic>> npsRows;
  final List<PersonalAssetItem> personalAssets;
  final List<Banktransation> bankTransactions;
  final List<invtx.Investment> equityTransactions;
  final List<invtx.Investment> mfTransactions;
  final List<invtx.Investment> etfTransactions;
  final List<Map<String, dynamic>> mfHolders;

  FinarkeinParsedResult({
    this.banks = const [],
    this.stocks = const [],
    this.mf = const [],
    this.etf = const [],
    this.insurance = const [],
    this.npsRows = const [],
    this.personalAssets = const [],
    this.bankTransactions = const [],
    this.equityTransactions = const [],
    this.mfTransactions = const [],
    this.etfTransactions = const [],
    this.mfHolders = const [],
  });
}

/// Known data/result keys (array-of-arrays). Alternate keys supported per asset type.
class _AssetKeys {
  static const List<String> deposit = [
    'deposit.summary',
    'deposits.summary',
    'banks.summary',
    'bank_accounts.summary',
    'deposit_accounts.summary',
    'accounts.summary',
  ];
  static const String equities = 'equities.summary';
  static const List<String> mutualFunds = ['mutual_funds.summary'];
  static const List<String> etf = ['etf.summary'];
  static const List<String> insurance = ['insurance.summary'];
  static const List<String> nps = ['nps.summary'];
  static const List<String> personal = [
    'personal_assets.summary',
    'personal.summary',
  ];
}

/// Parser for Finarkein data/result response. Supports both:
/// 1. New format: data.details with direct arrays of objects
/// 2. Legacy format: data.aaData with array-of-arrays
class FinarkeinDataResultParser {
  /// Parse [data] (the "data" object from GET aa/data/result response).
  /// Returns [FinarkeinParsedResult] with empty lists when keys are missing or invalid.
  static FinarkeinParsedResult parse(Map<String, dynamic>? data) {
    if (data == null) return FinarkeinParsedResult();

    final banks = <Bank>[];
    final stocks = <Stock>[];
    final mf = <Mf>[];
    final etf = <Etf>[];
    final insurance = <Insurance>[];
    final npsRows = <Map<String, dynamic>>[];
    final personalAssets = <PersonalAssetItem>[];
    final bankTransactions = <Banktransation>[];
    final equityTransactions = <invtx.Investment>[];
    final mfTransactions = <invtx.Investment>[];
    final etfTransactions = <invtx.Investment>[];
    final mfHolders = <Map<String, dynamic>>[];

    // Check for new format: data.details (direct arrays of objects)
    final details = data['details'];
    if (details is Map<String, dynamic>) {
      print('FinarkeinDataResultParser: Using data.details format');

      // Parse banks from details.bank
      final bankArray = details['bank'];
      if (bankArray is List) {
        for (final item in bankArray) {
          if (item is Map<String, dynamic>) {
            final b = _detailsToBank(item);
            if (b != null) banks.add(b);
          }
        }
        print(
          'FinarkeinDataResultParser: Parsed ${banks.length} banks from details.bank',
        );
      }

      // Parse equities from details.equities
      final equitiesArray = details['equities'];
      if (equitiesArray is List) {
        for (final item in equitiesArray) {
          if (item is Map<String, dynamic>) {
            final s = _detailsToStock(item);
            if (s != null) stocks.add(s);
          }
        }
        print(
          'FinarkeinDataResultParser: Parsed ${stocks.length} stocks from details.equities',
        );
      }

      // Parse mutual funds from details.mf
      final mfArray = details['mf'];
      if (mfArray is List) {
        for (final item in mfArray) {
          if (item is Map<String, dynamic>) {
            final m = _detailsToMf(item);
            if (m != null) mf.add(m);
          }
        }
        print(
          'FinarkeinDataResultParser: Parsed ${mf.length} MFs from details.mf',
        );
      }

      // Parse ETFs from details.etf
      final etfArray = details['etf'];
      if (etfArray is List) {
        for (final item in etfArray) {
          if (item is Map<String, dynamic>) {
            final e = _detailsToEtf(item);
            if (e != null) etf.add(e);
          }
        }
        print(
          'FinarkeinDataResultParser: Parsed ${etf.length} ETFs from details.etf',
        );
      }

      // Parse insurance from details.insurance
      final insuranceArray = details['insurance'];
      if (insuranceArray is List) {
        for (final item in insuranceArray) {
          if (item is Map<String, dynamic>) {
            final i = _detailsToInsurance(item);
            if (i != null) insurance.add(i);
          }
        }
      }

      // Parse NPS from details.nps
      final npsArray = details['nps'];
      if (npsArray is List) {
        for (final item in npsArray) {
          if (item is Map<String, dynamic>) {
            npsRows.add(item);
          }
        }
      }

      return FinarkeinParsedResult(
        banks: banks,
        stocks: stocks,
        mf: mf,
        etf: etf,
        insurance: insurance,
        npsRows: npsRows,
        personalAssets: personalAssets,
        bankTransactions: bankTransactions,
        equityTransactions: equityTransactions,
        mfTransactions: mfTransactions,
        etfTransactions: etfTransactions,
        mfHolders: mfHolders,
      );
    }

    // Fallback to legacy format: data.aaData (array-of-arrays)
    print('FinarkeinDataResultParser: Using legacy data.aaData format');
    final aaData = data['aaData'] ?? data;
    if (aaData is! Map<String, dynamic>) return FinarkeinParsedResult();

    for (final entry in aaData.entries) {
      final key = entry.key.toString();
      final k = key.toLowerCase().trim();
      final isSummaryKey = k.endsWith('.summary');
      final isTransactionsKey = k.endsWith('.transactions');
      final isHoldersKey = k.endsWith('.holders');
      final value = entry.value;
      if (value is! List || value.isEmpty) continue;
      // Skip noise keys (e.g. exception objects)
      if (key.startsWith('io.') || key.contains('exception')) continue;

      final rows = arrayOfArraysToMaps(value);
      if (rows.isEmpty) continue;

      // Parse *.transactions rows into existing UI models (kept separate from holdings).
      if (isTransactionsKey) {
        if (k.startsWith('deposit.') ||
            k.startsWith('rd.') ||
            k.startsWith('td.') ||
            k.startsWith('banks.') ||
            k.contains('deposit')) {
          for (final row in rows) {
            final t = rowToBankTransaction(row);
            if (t != null) bankTransactions.add(t);
          }
          continue;
        }
        if (k.startsWith('equities.') || k.contains('equities')) {
          for (final row in rows) {
            final t = _rowToInvestmentTransaction(row, category: 'EQUITY');
            if (t != null) equityTransactions.add(t);
          }
          continue;
        }
        if (k.startsWith('mutual_funds.') ||
            k.contains('mutual_fund') ||
            k.contains('mutualfund') ||
            k.startsWith('mf.') ||
            k.startsWith('mfs.')) {
          for (final row in rows) {
            final t = _rowToInvestmentTransaction(
              row,
              category: 'MUTUAL FUNDS',
            );
            if (t != null) mfTransactions.add(t);
          }
          final isinTrasactionMap = <String, int>{};
          for (var mfTransaction in mfTransactions) {
            if (mfTransaction.isin != null) {
              isinTrasactionMap.update(
                mfTransaction.isin!,
                (value) => value + 1,
                ifAbsent: () => 1,
              );
            }
          }

          for (var mfItem in mf) {
            if (isinTrasactionMap.containsKey(mfItem.isin)) {
              mfItem.count = isinTrasactionMap[mfItem.isin]!;
            }
          }
          continue;
        }
        if (k.startsWith('etf.') || k.contains('etf')) {
          for (final row in rows) {
            final t = _rowToInvestmentTransaction(row, category: 'ETF');
            if (t != null) etfTransactions.add(t);
          }
          continue;
        }
        // Unknown *.transactions key: ignore.
        continue;
      }

      // Parse holders: keep as raw maps for now (no UI model yet), but persist for MF screens.
      if (isHoldersKey) {
        if (k.startsWith('mutual_funds.') ||
            k.contains('mutual_fund') ||
            k.contains('mutualfund') ||
            k.startsWith('mf.') ||
            k.startsWith('mfs.')) {
          mfHolders.addAll(rows);
        }
        continue;
      }

      // Only .summary keys should contribute to holdings / dashboard asset values.
      if (isSummaryKey && k == _AssetKeys.equities) {
        print(
          'FinarkeinDataResultParser: Found equities.summary with ${rows.length} rows',
        );
        for (final row in rows) {
          final s = _rowToStock(row);
          if (s != null) {
            stocks.add(s);
          } else {
            print('FinarkeinDataResultParser: Failed to parse stock row: $row');
          }
        }
        print(
          'FinarkeinDataResultParser: Successfully parsed ${stocks.length} stocks',
        );
        continue;
      }
      if (isSummaryKey &&
          (_AssetKeys.deposit.contains(k) ||
              // Allow other deposit variants while still enforcing *.summary only.
              k.startsWith('deposit.') ||
              k.startsWith('rd.') ||
              k.startsWith('td.') ||
              k == 'banks.summary' ||
              k.startsWith('banks.'))) {
        for (final row in rows) {
          final b = _rowToBank(row);
          if (b != null) banks.add(b);
        }
        continue;
      }
      if (isSummaryKey &&
          (_AssetKeys.mutualFunds.contains(k) ||
              k.contains('mutual_fund') ||
              k.contains('mutualfund') ||
              k == 'mf.summary' ||
              k.startsWith('mf.') ||
              k.startsWith('mfs.'))) {
        for (final row in rows) {
          final m = _rowToMf(row);
          if (m != null) mf.add(m);
        }
        continue;
      }
      if (isSummaryKey && (_AssetKeys.etf.contains(k) || k == 'etf.summary')) {
        for (final row in rows) {
          final e = _rowToEtf(row);
          if (e != null) etf.add(e);
        }
        continue;
      }
      if (isSummaryKey &&
          (_AssetKeys.insurance.contains(k) || k.contains('insurance'))) {
        for (final row in rows) {
          final i = _rowToInsurance(row);
          if (i != null) insurance.add(i);
        }
        continue;
      }
      if (isSummaryKey && (_AssetKeys.nps.contains(k) || k.contains('nps'))) {
        npsRows.addAll(rows);
        continue;
      }
      if (isSummaryKey &&
          (_AssetKeys.personal.contains(k) || k.contains('personal'))) {
        for (final row in rows) {
          final p = _rowToPersonalAsset(row);
          if (p != null) personalAssets.add(p);
        }
      }
    }

    return FinarkeinParsedResult(
      banks: banks,
      stocks: stocks,
      mf: mf,
      etf: etf,
      insurance: insurance,
      npsRows: npsRows,
      personalAssets: personalAssets,
      bankTransactions: bankTransactions,
      equityTransactions: equityTransactions,
      mfTransactions: mfTransactions,
      etfTransactions: etfTransactions,
      mfHolders: mfHolders,
    );
  }

  /// Convert array-of-arrays (first element = list of header strings) to list of maps.
  static List<Map<String, dynamic>> arrayOfArraysToMaps(List<dynamic> raw) {
    if (raw.isEmpty) return [];
    final first = raw.first;
    if (first is! List) return [];
    final headers =
        first
            .map((e) => (e?.toString() ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
    if (headers.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i < raw.length; i++) {
      final row = raw[i];
      if (row is! List) continue;
      final map = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        final header = headers[j];
        final value = j < row.length ? row[j] : null;
        if (header.isNotEmpty) {
          map[header] = value;
          final lower = _toCamelCase(header);
          if (lower != header) map[lower] = value;
        }
      }
      result.add(map);
    }
    return result;
  }

  static String _toCamelCase(String s) {
    final parts = s.split(RegExp(r'[_\s]+'));
    if (parts.isEmpty) return s;
    final out = [parts[0].toLowerCase()];
    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.isEmpty) continue;
      out.add(p.substring(0, 1).toUpperCase() + p.substring(1).toLowerCase());
    }
    return out.join();
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime _toDate(dynamic v, {DateTime? fallback}) {
    final fb = fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (v == null) return fb;
    if (v is DateTime) return v;
    if (v is num) {
      // Treat as epoch milliseconds when reasonable.
      try {
        final ms = v.toInt();
        if (ms > 1000000000) return DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (_) {}
      return fb;
    }
    final s = v.toString().trim();
    if (s.isEmpty) return fb;
    return DateTime.tryParse(s) ?? fb;
  }

  static String _str(dynamic v, [String fallback = '']) =>
      v?.toString().trim() ?? fallback;

  static Banktransation? rowToBankTransaction(Map<String, dynamic> row) {
    try {
      final now = DateTime.now();
      final accountguid = _str(
        row['accountguid'] ??
            row['linkedAccRef'] ??
            row['linked_acc_ref'] ??
            row['linkrefnumber'] ??
            row['linkRefNumber'],
        '',
      );
      if (accountguid.isEmpty) return null;

      final amount = _toDouble(
        row['amount'] ??
            row['txnAmount'] ??
            row['txnamount'] ??
            row['transactionAmount'],
      );

      final balanceAfter = _toDouble(
        row['balanceaftertransaction'] ??
            row['balanceAfterTransaction'] ??
            row['currentBalance'] ??
            row['current_balance'] ??
            row['balance'],
      );

      final ts = _toDate(
        row['transactiontimestamp'] ??
            row['transactionTimestamp'] ??
            row['transactionDateTime'] ??
            row['transaction_date_time'] ??
            row['date'] ??
            row['txnDateTime'] ??
            row['txndatetime'],
        fallback: now,
      );
      final vd = _toDate(
        row['valuedate'] ?? row['valueDate'] ?? row['value_date'],
        fallback: ts,
      );

      final type = _str(row['type'] ?? row['txnType'], 'DEBIT').toUpperCase();
      final mode = _str(row['mode'] ?? row['txnMode'], 'N/A');
      final narration = _str(
        row['narration'] ?? row['description'] ?? row['remarks'],
        'Transaction',
      );
      final guid = _str(row['guid'] ?? row['txnid'] ?? row['txnId'], '');
      final rawTxnId = row['txnid'] ?? row['txnId'];
      String? txnid = rawTxnId != null ? rawTxnId.toString().trim() : null;
      if (txnid != null && txnid.isEmpty) txnid = null;
      final rawRef = row['reference'] ?? row['ref'];
      String? reference = rawRef != null ? rawRef.toString().trim() : null;
      if (reference != null && reference.isEmpty) reference = null;

      return Banktransation(
        id: 0,
        guid: guid.isEmpty ? null : guid,
        accountguid: accountguid,
        userguid: _str(row['userguid'], ''),
        txnid: txnid,
        type: type.isEmpty ? 'DEBIT' : type,
        mode: mode,
        amount: amount,
        balanceaftertransaction: balanceAfter,
        transactiontimestamp: ts,
        valuedate: vd,
        narration: narration,
        reference: reference,
        finishprocessed: true,
        createdat: now,
        updatedat: now,
      );
    } catch (_) {
      return null;
    }
  }

  static invtx.Investment? _rowToInvestmentTransaction(
    Map<String, dynamic> row, {
    required String category,
  }) {
    try {
      final now = DateTime.now();
      final date = _toDate(
        row['transactionDate'] ??
            row['transactionDateTime'] ??
            row['transactiontimestamp'] ??
            row['transactionTimestamp'] ??
            row['date'] ??
            row['txnDate'] ??
            row['txnDateTime'],
        fallback: now,
      );
      final amount = _toDouble(
        row['amount'] ??
            row['txnAmount'] ??
            row['txnamount'] ??
            row['transactionAmount'],
      );
      final qty = _toDouble(row['units'] ?? row['quantity']);
      final nav = _toDouble(row['nav'] ?? row['price'] ?? row['rate']);
      final isin = _str(
        row['isin'] ??
            row['isinCode'] ??
            row['isin_code'] ??
            row['isinNumber'] ??
            row['isin_number'],
        '',
      );
      final name = _str(
        row['companyName'] ??
            row['company_name'] ??
            row['isinDescription'] ??
            row['isin_description'] ??
            row['issuerName'] ??
            row['issuer_name'] ??
            row['schemeName'] ??
            row['scheme_name'] ??
            row['name'],
        category,
      );
      final type = _str(row['type'] ?? row['txnType'], '');
      final rawDesc = row['narration'] ?? row['description'];
      String? description = rawDesc != null ? rawDesc.toString().trim() : null;
      if (description != null && description.isEmpty) description = null;

      if (category == 'ETF') {
        print(
          'FinarkeinParser: ETF Transaction - ISIN: $isin, units from row: ${row['units']}, parsed qty: $qty, name: $name',
        );
      }

      // NOTE: we stash ISIN into an existing field (brokercode) so the existing
      // InvestmentTransactionService can filter by isinCode without changing UI models.
      return invtx.Investment(
        category: category,
        date: date,
        quantity: qty,
        avgBuyPrice: nav,
        txnamount: amount,
        name: name,
        type: type,
        description: description,
        brokercode: isin.isEmpty ? null : isin,
        isin: isin.isEmpty ? null : isin,
      );
    } catch (_) {
      return null;
    }
  }

  static Stock? _rowToStock(Map<String, dynamic> row) {
    try {
      final guid = _str(
        row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['guid'],
        '',
      );
      final name = _str(
        row['issuerName'] ?? row['issuer_name'] ?? row['name'],
        'Equity',
      );
      final currentValue = _toDouble(
        row['currentValue'] ??
            row['current_value'] ??
            row['currentmktvalue'] ??
            row['current_balance'] ??
            row['currentBalance'],
      );
      final quantity = _toDouble(row['units'] ?? row['quantity']);
      final rate =
          quantity > 0
              ? currentValue / quantity
              : _toDouble(
                row['lastTradedPrice'] ??
                    row['last_traded_price'] ??
                    row['rate'],
              );
      final json = <String, dynamic>{
        'id': 0,
        'guid': guid.isEmpty ? 'eq-${row.hashCode}' : guid,
        'name': name,
        'currentmktvalue': currentValue,
        'quantity': quantity,
        'rate': rate,
        'isin': row['isin'],
        'issuername': row['issuerName'] ?? row['issuer_name'],
        'logo': row['logo'] ?? row['logourl'] ?? row['icon'],
      };
      return Stock.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Bank? _rowToBank(Map<String, dynamic> row) {
    try {
      final linkRef = _str(
        row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['linkrefnumber'],
        '',
      );
      final masked = _str(
        row['maskedAccNumber'] ??
            row['masked_acc_number'] ??
            row['maskedaccountid'],
        '',
      );
      final fipname = _str(
        row['fipName'] ??
            row['fipname'] ??
            row['accountName'] ??
            row['account_name'],
        masked.isNotEmpty ? masked : 'Account',
      );
      final currentValue = _toDouble(
        row['currentValue'] ??
            row['current_value'] ??
            row['currentvalue'] ??
            row['current_balance'] ??
            row['currentBalance'],
      );
      final typeRaw =
          _str(
            row['type'] ??
                row['fiType'] ??
                row['fitype'] ??
                row['accountType'] ??
                row['account_type'] ??
                row['depositType'] ??
                row['deposit_type'],
            '',
          ).toUpperCase();
      // Deposits UI expects one of: DEPOSIT / TERM_DEPOSIT / RECURRING_DEPOSIT.
      final normalizedType =
          typeRaw.contains('TERM') ||
                  typeRaw == 'FD' ||
                  typeRaw.contains('FIXED')
              ? 'TERM_DEPOSIT'
              : (typeRaw.contains('RECURR') || typeRaw == 'RD'
                  ? 'RECURRING_DEPOSIT'
                  : 'DEPOSIT');
      final interestRate = _toDouble(
        row['interestRate'] ??
            row['interest_rate'] ??
            row['rate'] ??
            row['roi'] ??
            row['apr'],
      );
      final principal = _toDouble(
        row['principalAmount'] ??
            row['principal_amount'] ??
            row['principal'] ??
            row['depositAmount'] ??
            row['deposit_amount'],
      );
      final recurring = _toDouble(
        row['recurringAmount'] ??
            row['recurring_amount'] ??
            row['installmentAmount'] ??
            row['installment_amount'],
      );
      final branch = _str(
        row['branch'] ?? row['branchName'] ?? row['branch_name'],
        '',
      );
      final ifsc = _str(
        row['ifsc'] ?? row['ifscCode'] ?? row['ifsc_code'] ?? row['IFSC'],
        '',
      );
      final holderName = _str(
        row['holderName'] ??
            row['holder_name'] ??
            row['accountHolderName'] ??
            row['account_holder_name'] ??
            row['name'],
        '',
      );
      final now = DateTime.now();
      final json = <String, dynamic>{
        'guid': linkRef.isEmpty ? 'bank-${row.hashCode}' : linkRef,
        'fipid': 'finarkein',
        'fipname': fipname,
        'linkrefnumber': linkRef,
        'maskedaccountid': masked.isEmpty ? linkRef : masked,
        'currentvalue': currentValue,
        'balancedatetime': now.toIso8601String(),
        'isprimary': false,
        'addedat': now.toIso8601String(),
        'deltavalue': 0,
        'deltapercentage': 0,
        'havedata': true,
        'type': normalizedType,
        'branch': branch.isNotEmpty ? branch : null,
        'ifsc': ifsc.isNotEmpty ? ifsc : null,
        'interestrate': interestRate > 0 ? interestRate : null,
        'principalamount': principal > 0 ? principal : null,
        'recurringamount': recurring > 0 ? recurring : null,
        'profile': {
          'nominee': '',
          'name': holderName.isNotEmpty ? holderName : null,
        },
      };
      return Bank.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Mf? _rowToMf(Map<String, dynamic> row) {
    try {
      final linkRef = _str(row['linkedAccRef'] ?? row['linked_acc_ref'], '');
      final guid = _str(
        row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['guid'],
        '',
      );
      final name = _str(
        row['isinDescription'] ??
            row['schemeName'] ??
            row['scheme_name'] ??
            row['name'] ??
            row['amcname'],
        'MF',
      );
      final schemecode = _str(
        row['schemeCode'] ?? row['scheme_code'] ?? row['schemecode'],
        '',
      );
      final isin = _str(
        row['isin'] ??
            row['isinCode'] ??
            row['isin_code'] ??
            row['isinNumber'] ??
            row['isin_number'],
        '',
      );
      final folio = _str(
        row['folio'] ??
            row['folioNo'] ??
            row['foliono'] ??
            row['folio_number'] ??
            row['folioNumber'],
        '',
      );
      final currentValue = _toDouble(
        row['currentValue'] ??
            row['current_value'] ??
            row['currentMarketValue'] ??
            row['current_market_value'] ??
            row['currentmarketvalue'] ??
            row['currentmktvalue'] ??
            row['marketValue'] ??
            row['market_value'] ??
            row['current_balance'] ??
            row['currentBalance'],
      );
      final units = _toDouble(
        row['units'] ??
            row['quantity'] ??
            row['closingbalance'] ??
            row['closingUnits'],
      );
      final nav = _toDouble(row['nav'] ?? 1);
      final now = DateTime.now();
      final json = <String, dynamic>{
        'id': 0,
        'createdat': now.toIso8601String(),
        'userguid': '',
        'logo': row['logo'] ?? row['logourl'] ?? row['icon'],
        'activestate': true,
        'reqid': '',
        'amc': _str(row['amc'], ''),
        'amcname': _str(row['amcName'] ?? row['amcname'], ''),
        'taxstatus': 'EQUITY',
        'modeofholding': null,
        'transactionsource': 'AA',
        'schemecode': schemecode.isEmpty ? null : schemecode,
        'name': name,
        'idcwchangeallowed': false,
        'schemeoption': 'GROWTH',
        'assettype': null,
        'schemetype': _str(row['schemetype'], ''),
        'nav': nav,
        'navdate': null,
        'closingbalance': units,
        'isdemat': null,
        'currentmktvalue': currentValue,
        'costvalue': _toDouble(
          row['costValue'] ?? row['costvalue'] ?? currentValue,
        ),
        'gainloss': 0,
        'gainlosspercentage': 0,
        'lienunitsflag': null,
        'decimalunits': 4,
        'decimalamount': 2,
        'decimalnav': 4,
        'brokercode': '',
        'brokername': '',
        'purallow': null,
        'redallow': null,
        'swtallow': null,
        'sipallow': null,
        'stpallow': null,
        'swpallow': null,
        'planmode': 'DIRECT',
        'dpid': null,
        'mobilerelationship': null,
        'emailrelationship': null,
        'newfolio': null,
        'nomineestatus': 'N',
        'lienavailableunits': null,
        'investorname': '',
        'guid': guid.isEmpty ? 'mf-${row.hashCode}' : guid,
        'quantity': units,
        'rtacode': null,
        'lasttrxndate': null,
        'openingbal': null,
        'folio': folio,
        'age': null,
        'phonenumber': '',
        'email': '',
        'availableunits': units,
        'availableamount': null,
        'isin': isin,
        'validpan': false,
        'kycstatus': '',
        'lieneligibleunits': null,
        'bankaccnumber': null,
        'bankacctype': null,
        'bankaccname': null,
        'bankbranch': null,
        'bankcity': null,
        'bankpincode': null,
        'bankmicr': null,
        'bankifsc': null,
        'bankneftifsc': null,
        'rtaname': '',
        'foliocreateddate': null,
        'mfsummaryguid': guid,
        'fatcastatus': null,
        'amficode': null,
        'isindescription': null,
        'lockinunits': null,
        'registrar': row['registrar'] ?? '',
        'schemecategory': null,
        'schemetypes': null,
        'ucc': null,
        'fipname': row['fipName'] ?? row['fipname'],
        'fipid': null,
        'linkrefnumber': linkRef,
        'maskeddemataccount': null,
        'xirrvalue': null,
        'cagrvalue': 0,
        'closingunits': null,
        'lienunits': null,
        'accountguid': null,
        'investoremail': '',
        'investorphonenumber': null,
        'investoraddress': null,
        'investordataguid': '',
        'deltavalue': 0,
        'delta': null,
        'deltapercentage': 0,
        'holdingavgprice': null,
        'swapamount': null,
        'frequency': null,
        'installments': null,
        'nextinstallments': null,
        'lasttransactiondate': null,
        'count': null,
      };
      json['linkrefnumber'] = linkRef;
      return Mf.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Etf? _rowToEtf(Map<String, dynamic> row) {
    try {
      final guid = _str(
        row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['guid'],
        '',
      );
      final name = _str(
        row['isinDescription'] ??
            row['isin_description'] ??
            row['issuerName'] ??
            row['issuer_name'] ??
            row['name'],
        'ETF',
      );
      final currentValue = _toDouble(
        row['currentValue'] ??
            row['current_value'] ??
            row['currentmktvalue'] ??
            row['current_balance'] ??
            row['currentBalance'],
      );
      final units = _toDouble(row['units'] ?? row['quantity']);
      final nav = _toDouble(
        row['nav'] ?? row['lastTradedPrice'] ?? row['last_traded_price'] ?? 1,
      );
      final now = DateTime.now();
      final json = <String, dynamic>{
        'id': 0,
        'userguid': '',
        'guid': guid.isEmpty ? 'etf-${row.hashCode}' : guid,
        'activestate': true,
        'type': 'ETF',
        'isin': row['isin'],
        'units': units,
        'nav': nav,
        'currentmktvalue': currentValue,
        'createdat': now.toIso8601String(),
        'updatedat': now.toIso8601String(),
        'name': name,
        'status': 'ACTIVE',
        'logo': row['logo'] ?? row['logourl'] ?? row['icon'],
      };
      return Etf.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Insurance? _rowToInsurance(Map<String, dynamic> row) {
    try {
      final accountguid = _str(
        row['linkedAccRef'] ?? row['linked_acc_ref'] ?? row['accountguid'],
        'ins-${row.hashCode}',
      );
      final policyname = _str(
        row['policyName'] ?? row['policyname'] ?? row['productName'],
        'Policy',
      );
      final policynumber = _str(row['policyNumber'] ?? row['policynumber'], '');
      final sumassured = _toDouble(
        row['sumAssured'] ?? row['sum_assured'] ?? row['sumassured'],
      );
      final fipname = _str(
        row['fipName'] ?? row['fipname'] ?? row['issuerName'],
        '',
      );
      return Insurance(
        accountguid: accountguid,
        policyname: policyname,
        policynumber: policynumber,
        sumassured: sumassured,
        fipname: fipname.isNotEmpty ? fipname : 'Insurance',
        type: _str(row['type'], 'INSURANCE'),
        subcategory: _str(row['subcategory'], ''),
        premiumamount: _toDouble(
          row['premiumamount'] ?? row['premiumAmount'] ?? 0,
        ),
        currentvalue: _toDouble(
          row['currentvalue'] ?? row['currentValue'] ?? 0,
        ),
        premiumfrequency: _str(
          row['premiumfrequency'] ?? row['premiumFrequency'] ?? 'ANNUALLY',
        ),
        policystartdate: _toDate(
          row['policystartdate'] ?? row['policyStartDate'],
          fallback: null,
        ),
        nextpremiumduedate: _toDate(
          row['nextpremiumduedate'] ?? row['nextPremiumDueDate'],
          fallback: null,
        ),
        tenureyears:
            _toDouble(row['tenureyears'] ?? row['tenureYears']).toInt(),
        premiumpaymentyears:
            _toDouble(
              row['premiumpaymentyears'] ?? row['premiumPaymentYears'],
            ).toInt(),
        policystatus: _str(row['policystatus'] ?? row['policyStatus']),
        policyexpirydate: _toDate(
          row['policyexpirydate'] ?? row['policyExpiryDate'],
          fallback: null,
        ),
        count: _toDouble(row['count'] ?? 0).toInt(),
        transactions: (row['transactions'] as List<List<dynamic>>?) ?? [],
      );
    } catch (_) {
      return null;
    }
  }

  static PersonalAssetItem? _rowToPersonalAsset(Map<String, dynamic> row) {
    try {
      final id =
          row['id'] is int
              ? row['id'] as int
              : int.tryParse(row['id']?.toString() ?? '0') ?? 0;
      final title = _str(
        row['title'] ?? row['name'] ?? row['assetType'],
        'Asset',
      );
      final subtitle = _str(row['subtitle'] ?? row['description'], '');
      final amount = _toDouble(
        row['amount'] ?? row['value'] ?? row['currentValue'],
      );
      final type = _str(row['type'] ?? row['assetType'], 'other');
      return PersonalAssetItem(
        id: id,
        title: title,
        subtitle: subtitle,
        amount: amount,
        type: type,
      );
    } catch (_) {
      return null;
    }
  }

  // ===== Conversion methods for data.details format (direct objects) =====

  /// Convert details.bank object to Bank model
  static Bank? _detailsToBank(Map<String, dynamic> item) {
    try {
      // Map API response fields to expected field names
      final guid = _str(
        item['accountguid'] ?? item['linkedaccref'] ?? item['guid'],
        '',
      );
      final fipname = _str(item['fipname'], 'Bank');
      final currentValue = _toDouble(
        item['currentvalue'] ?? item['currentValue'] ?? item['currentbalance'],
      );
      final masked = _str(
        item['maskedaccnumber'] ?? item['maskedAccNumber'],
        '',
      );
      final accountType =
          _str(item['type'] ?? item['accounttype'], 'DEPOSIT').toUpperCase();
      final normalizedType = accountType == 'SAVINGS' ? 'DEPOSIT' : accountType;

      // Parse balance datetime
      final balanceDateTimeRaw = item['balancedatetime'];
      DateTime? balanceDateTime;
      if (balanceDateTimeRaw != null) {
        balanceDateTime = _toDate(balanceDateTimeRaw);
      }

      final now = DateTime.now();
      final json = <String, dynamic>{
        'guid': guid.isEmpty ? 'bank-${item.hashCode}' : guid,
        'fipid': item['fipid'] ?? 'finarkein',
        'fipname': fipname,
        'linkrefnumber': guid,
        'maskedaccountid': masked.isEmpty ? guid : masked,
        'currentvalue': currentValue,
        'balancedatetime': (balanceDateTime ?? now).toIso8601String(),
        'isprimary': false,
        'addedat': now.toIso8601String(),
        'deltavalue': 0,
        'deltapercentage': 0,
        'havedata': true,
        'type': normalizedType,
        'branch': item['branch'],
        'ifsc': item['ifsccode'] ?? item['ifsc'],
        'interestrate': item['interestrate'],
        'principalamount': item['principalamount'],
        'recurringamount': item['recurringamount'],
        'profile':
            item['profile'] ??
            {
              'nominee': '',
              'name':
                  item['holdername'] ??
                  item['holderName'] ??
                  item['accountHolderName'] ??
                  item['account_holder_name'] ??
                  item['name'],
            },
      };
      return Bank.fromJson(json);
    } catch (e) {
      print('_detailsToBank error: $e');
      return null;
    }
  }

  /// Convert details.equities object to Stock model
  static Stock? _detailsToStock(Map<String, dynamic> item) {
    try {
      final guid = _str(item['accountguid'] ?? item['guid'], '');
      final name = _str(item['name'], 'Equity');
      final currentValue = _toDouble(
        item['currentvalue'] ?? item['currentValue'],
      );
      final quantity = _toDouble(item['quantity'] ?? item['units']);
      final rate = _toDouble(item['rate'] ?? item['lastTradedPrice']);
      final isin = _str(item['isin'], '');

      final json = <String, dynamic>{
        'id': 0,
        'guid': guid.isEmpty ? 'eq-${item.hashCode}' : guid,
        'name': name,
        'currentmktvalue': currentValue,
        'quantity': quantity,
        'rate': rate,
        'isin': isin.isEmpty ? null : isin,
        'issuername': item['issuername'] ?? item['issuerName'],
        'avgbuyprice': item['avgbuyprice'] ?? item['averageholdingprice'],
        'investedamount': item['investedamount'] ?? item['investedAmount'],
        'gain': item['gain'],
        'gainpercentage': item['gainpercentage'] ?? item['gainPercentage'],
        'totalgain': item['totalgain'] ?? item['totalGain'],
        'totalgainpercentage':
            item['totalgainpercentage'] ?? item['totalGainPercentage'],
        'dailygain': item['dailygain'] ?? item['dailyGain'],
        'dailygainpercentage':
            item['dailygainpercentage'] ?? item['dailyGainPercentage'],
        'xirr': item['xirr'],
        'count': item['count'],
        'lasttransactiondate':
            item['lasttransactiondate'] ?? item['lastTransactionDate'],
        'logourl': item['logo'] ?? item['logourl'] ?? item['icon'],
      };
      return Stock.fromJson(json);
    } catch (e) {
      print('_detailsToStock error: $e');
      return null;
    }
  }

  /// Convert details.mf object to Mf model
  static Mf? _detailsToMf(Map<String, dynamic> item) {
    try {
      final guid = _str(item['accountguid'] ?? item['guid'], '');
      final name = _str(item['name'], 'MF');
      final folio = _str(item['folio'] ?? item['folioNo'], '');
      final isin = _str(item['isin'], '');
      final currentValue = _toDouble(
        item['currentvalue'] ?? item['currentValue'],
      );
      final units = _toDouble(item['units']);
      final nav = units > 0 ? currentValue / units : 0;

      final now = DateTime.now();
      final json = <String, dynamic>{
        'id': 0,
        'createdat': now.toIso8601String(),
        'userguid': '',
        'logo': item['logo'] ?? item['logourl'] ?? item['icon'],
        'activestate': true,
        'reqid': '',
        'amc': '',
        'amcname': item['amcname'] ?? item['amcName'],
        'taxstatus': 'EQUITY',
        'modeofholding': null,
        'transactionsource': 'AA',
        'schemecode': item['schemecode'] ?? item['schemeCode'],
        'name': name,
        'isin': isin.isEmpty ? null : isin,
        'foliono': folio.isEmpty ? null : folio,
        'currentmktvalue': currentValue,
        'units': units,
        'nav': nav,
        'avgbuyprice': item['avgbuyprice'] ?? item['averageholdingprice'],
        'costvalue': item['investedamount'] ?? item['investedAmount'],
        'gain': item['gain'],
        'gainpercentage': item['gainpercentage'] ?? item['gainPercentage'],
        'totalgain': item['totalgain'] ?? item['totalGain'],
        'totalgainpercentage':
            item['totalgainpercentage'] ?? item['totalGainPercentage'],
        'dailygain': item['dailygain'] ?? item['dailyGain'],
        'deltavalue': item['deltavalue'] ?? item['dailygain'],
        'dailygainpercentage':
            item['dailygainpercentage'] ?? item['dailyGainPercentage'],
        'xirr': item['xirr'],
        'count': item['count'],
        'lasttransactiondate':
            item['lasttransactiondate'] ?? item['lastTransactionDate'],
      };
      return Mf.fromJson(json);
    } catch (e) {
      print('_detailsToMf error: $e');
      return null;
    }
  }

  /// Convert details.etf object to Etf model
  static Etf? _detailsToEtf(Map<String, dynamic> item) {
    try {
      final guid = _str(item['accountguid'] ?? item['guid'], '');
      final name = _str(item['name'], 'ETF');
      final isin = _str(item['isin'], '');
      final currentValue = _toDouble(
        item['currentvalue'] ?? item['currentValue'],
      );
      final quantity = _toDouble(item['quantity'] ?? item['units']);
      final nav =
          quantity > 0
              ? currentValue / quantity
              : _toDouble(item['rate'] ?? item['nav']);

      final json = <String, dynamic>{
        'id': 0,
        'guid': guid.isEmpty ? 'etf-${item.hashCode}' : guid,
        'name': name,
        'isin': isin.isEmpty ? null : isin,
        'currentmarketvalue': currentValue,
        'units': quantity,
        'nav': nav,
        'foliono': item['foliono'] ?? item['folio'],
        'avgbuyprice': item['avgbuyprice'] ?? item['averageholdingprice'],
        'investedvalue': item['investedamount'] ?? item['investedAmount'],
        'gain': item['gain'],
        'gainpercentage': item['gainpercentage'] ?? item['gainPercentage'],
        'totalgain': item['totalgain'] ?? item['totalGain'],
        'totalgainpercentage':
            item['totalgainpercentage'] ?? item['totalGainPercentage'],
        'dailygain': item['dailygain'] ?? item['dailyGain'],
        'deltavalue': item['deltavalue'] ?? item['dailygain'],
        'deltapercentage':
            item['dailygainpercentage'] ?? item['dailyGainPercentage'],
        'xirr': item['xirr'],
        'count': item['count'],
        'lasttransactiondate':
            item['lasttransactiondate'] ?? item['lastTransactionDate'],
        'logourl': item['logo'] ?? item['logourl'] ?? item['icon'],
      };
      return Etf.fromJson(json);
    } catch (e) {
      print('_detailsToEtf error: $e');
      return null;
    }
  }

  /// Convert details.insurance object to Insurance model
  static Insurance? _detailsToInsurance(Map<String, dynamic> item) {
    try {
      final guid = _str(item['accountguid'] ?? item['guid'], '');
      final fipname = _str(item['fipname'], 'Insurance');
      final currentValue = _toDouble(
        item['currentvalue'] ?? item['currentValue'],
      );
      final masked = _str(
        item['maskedaccnumber'] ?? item['maskedAccNumber'],
        '',
      );

      final now = DateTime.now();
      final json = <String, dynamic>{
        'guid': guid.isEmpty ? 'ins-${item.hashCode}' : guid,
        'fipid': 'finarkein',
        'fipname': fipname,
        'linkrefnumber': guid,
        'maskedaccountid': masked.isEmpty ? guid : masked,
        'currentvalue': currentValue,
        'balancedatetime': now.toIso8601String(),
        'type': item['type'] ?? 'INSURANCE',
        'policyname': item['policyname'] ?? item['policyName'],
        'policynumber': item['policynumber'] ?? item['policyNumber'],
        'premiumamount': item['premiumamount'] ?? item['premiumAmount'],
        'sumassured': item['sumassured'] ?? item['sumAssured'],
        'maturitydate': item['maturitydate'] ?? item['maturityDate'],
        'profile': {
          'nominee': item['nominee'] ?? '',
          'name': item['holdername'] ?? item['holderName'],
        },
      };
      return Insurance.fromJson(json);
    } catch (e) {
      print('_detailsToInsurance error: $e');
      return null;
    }
  }
}
