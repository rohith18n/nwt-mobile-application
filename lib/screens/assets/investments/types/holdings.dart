import 'package:nwt_app/utils/app_logger.dart';

int? _parseSafeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseSafeDate(dynamic dateString) {
  if (dateString == null) return null;
  if (dateString is DateTime) return dateString;
  if (dateString is String) {
    if (int.tryParse(dateString) != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
    }
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }
  if (dateString is int) {
    return DateTime.fromMillisecondsSinceEpoch(dateString);
  }
  return null;
}

class InvestmentHoldingsResponse {
  int status;
  String message;
  HoldingsData? data;

  InvestmentHoldingsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory InvestmentHoldingsResponse.fromJson(Map<String, dynamic> json) {
    return InvestmentHoldingsResponse(
      status: _parseSafeInt(json['statusCode'] ?? json['status']) ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? HoldingsData.fromJson(json['data']) : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class HoldingsData {
  Investments investments;

  HoldingsData({required this.investments});

  factory HoldingsData.fromJson(Map<String, dynamic> json) {
    return HoldingsData(
      investments: Investments.fromJson(json['investments'] ?? {}),
    );
  }
}

class Investments {
  List<Stock> stocks;
  List<Mf> mf;
  List<Etf> etf;
  List<InvestmentProfile> profiles;

  Investments({
    required this.stocks,
    required this.mf,
    required this.etf,
    required this.profiles,
  });

  factory Investments.fromJson(Map<String, dynamic> json) {
    return Investments(
      stocks:
          (json['stocks'] as List<dynamic>? ?? [])
              .map((e) => Stock.fromJson(e as Map<String, dynamic>))
              .toList(),
      mf:
          (json['mf'] as List<dynamic>? ?? [])
              .map((e) => Mf.fromJson(e as Map<String, dynamic>))
              .toList(),
      etf:
          (json['etf'] as List<dynamic>? ?? [])
              .map((e) => Etf.fromJson(e as Map<String, dynamic>))
              .toList(),
      profiles:
          (json['profiles'] as List<dynamic>? ?? [])
              .map((e) => InvestmentProfile.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class Mf {
  dynamic id;
  DateTime createdat;
  String userguid;
  String? logo;
  bool activestate;
  String reqid;
  String amc;
  String amcname;
  String taxstatus;
  String? modeofholding;
  String transactionsource;
  String? schemecode;
  String name;
  bool idcwchangeallowed;
  String schemeoption;
  Assettype? assettype;
  String schemetype;
  double nav;
  DateTime? navdate;
  double closingbalance;
  bool? isdemat;
  double currentmktvalue;
  double costvalue;
  double? gainloss;
  double? gainlosspercentage;
  bool? lienunitsflag;
  double decimalunits;
  double decimalamount;
  double decimalnav;
  String brokercode;
  String? brokername;
  bool? purallow;
  bool? redallow;
  bool? swtallow;
  bool? sipallow;
  bool? stpallow;
  bool? swpallow;
  String planmode;
  String? dpid;
  String? mobilerelationship;
  String? emailrelationship;
  bool? newfolio;
  String nomineestatus;
  double? lienavailableunits;
  String investorname;
  String guid;
  double quantity;
  String? rtacode;
  String? lasttrxndate;
  double? openingbal;
  String folio;
  String? age;
  String phonenumber;
  String email;
  double availableunits;
  double? availableamount;
  String isin;
  bool validpan;
  String kycstatus;
  double? lieneligibleunits;
  String? bankaccnumber;
  String? bankacctype;
  String? bankaccname;
  String? bankbranch;
  String? bankcity;
  String? bankpincode;
  String? bankmicr;
  String? bankifsc;
  String? bankneftifsc;
  String rtaname;
  DateTime? foliocreateddate;
  String mfsummaryguid;
  String? fatcastatus;
  String? amficode;
  String? isindescription;
  double? lockinunits;
  String? registrar;
  String? schemecategory;
  String? schemetypes;
  String? ucc;
  String? fipname;
  String? fipid;
  String? linkrefnumber;
  String? maskeddemataccount;
  double? xirrvalue;
  double cagrvalue;
  double? closingunits;
  double? lienunits;
  String? accountguid;
  String investoremail;
  String? investorphonenumber;
  String? investoraddress;
  String investordataguid;
  double? deltavalue;
  double? delta;
  double? holdingavgprice;
  double? deltapercentage;
  double? swapamount;
  String? frequency;
  String? installments;
  String? nextinstallments;
  Type type;
  String? lasttransactiondate;
  int? count;

  factory Mf.fromJson(Map<String, dynamic> json) {
    AppLogger.info("LOGO_________________________: ${json['logo']}", tag: "Mf");
    return Mf(
      id: json['id'],
      logo: json['logo'] ?? json['logourl'] ?? json['icon'],
      createdat:
          json['createdat'] != null
              ? _parseSafeDate(json['createdat']) ?? DateTime.now()
              : DateTime.now(),
      userguid: json['userguid'] ?? '',
      activestate: json['activestate'] ?? false,
      reqid: json['reqid'] ?? '',
      amc: json['amc'] ?? '',
      amcname: json['amcname'] ?? '',
      taxstatus: json['taxstatus'] ?? '',
      modeofholding: json['modeofholding'] ?? '',
      transactionsource: json['transactionsource'] ?? '',
      schemecode: json['schemecode'],
      name: json['name'] ?? '',
      idcwchangeallowed: json['idcwchangeallowed'] ?? false,
      schemeoption: json['schemeoption'] ?? '',
      assettype: _parseAssettype(json['assettype']),
      schemetype: json['schemetype'] ?? '',
      nav: (json['nav'] ?? 0).toDouble(),
      navdate: json['navdate'] != null ? _parseSafeDate(json['navdate']) : null,
      closingbalance: (json['closingbalance'] ?? 0).toDouble(),
      isdemat: json['isdemat'],
      currentmktvalue:
          (json['currentvalue'] ?? json['currentmktvalue'] ?? 0.0).toDouble(),
      costvalue:
          (json['investedamount'] ?? json['costvalue'] ?? json['investedValue'] ?? json['txnamount'] ?? 0.0).toDouble(),
      gainloss: _getValidGainLoss(json),
      gainlosspercentage: _getValidGainLossPercentage(json),
      lienunitsflag: json['lienunitsflag'],
      decimalunits: (json['decimalunits'] ?? 0.0).toDouble(),
      decimalamount: (json['decimalamount'] ?? 0.0).toDouble(),
      decimalnav: (json['decimalnav'] ?? 0.0).toDouble(),
      brokercode: json['brokercode'] ?? '',
      brokername: json['brokername'],
      purallow: json['purallow'],
      redallow: json['redallow'],
      swtallow: json['swtallow'],
      sipallow: json['sipallow'],
      stpallow: json['stpallow'],
      swpallow: json['swpallow'],
      planmode: json['planmode'] ?? '',
      dpid: json['dpid'],
      mobilerelationship: json['mobilerelationship'],
      emailrelationship: json['emailrelationship'],
      newfolio: json['newfolio'],
      nomineestatus: json['nomineestatus'] ?? '',
      lienavailableunits:
          json['lienavailableunits'] != null
              ? (json['lienavailableunits']).toDouble()
              : null,
      investorname: json['investorname'] ?? '',
      guid: json['guid'] ?? json['accountguid'] ?? '',
      quantity: (json['units'] ?? json['quantity'] ?? json['closingbalance'] ?? 0).toDouble(),
      rtacode: json['rtacode'],
      lasttrxndate: json['lasttrxndate'] ?? '',
      openingbal:
          json['openingbal'] != null ? (json['openingbal']).toDouble() : null,
      folio: json['folio'] ?? json['foliono'] ?? json['folio_no'] ?? '',
      age: json['age'],
      phonenumber: json['phonenumber'] ?? '',
      email: json['email'] ?? '',
      availableunits: (json['units'] ?? json['availableunits'] ?? 0).toDouble(),
      availableamount:
          json['availableamount'] != null
              ? (json['availableamount']).toDouble()
              : null,
      isin: json['isin'] ?? '',
      validpan: json['validpan'] ?? false,
      kycstatus: json['kycstatus'] ?? '',
      lieneligibleunits:
          json['lieneligibleunits'] != null
              ? (json['lieneligibleunits']).toDouble()
              : null,
      bankaccnumber: json['bankaccnumber'],
      bankacctype: json['bankacctype'],
      bankaccname: json['bankaccname'],
      bankbranch: json['bankbranch'],
      bankcity: json['bankcity'],
      bankpincode: json['bankpincode'],
      bankmicr: json['bankmicr'],
      bankifsc: json['bankifsc'],
      bankneftifsc: json['bankneftifsc'],
      rtaname: json['rtaname'] ?? json['registrar'] ?? '',
      foliocreateddate:
          json['foliocreateddate'] != null
              ? _parseSafeDate(json['foliocreateddate'])
              : null,
      mfsummaryguid: json['mfsummaryguid'] ?? '',
      fatcastatus: json['fatcastatus'],
      amficode: json['amficode'],
      isindescription: json['isindescription'],
      lockinunits:
          json['lockinunits'] != null ? (json['lockinunits']).toDouble() : null,
      registrar: json['registrar'],
      schemecategory: json['schemecategory'],
      schemetypes: json['schemetypes'],
      ucc: json['ucc'],
      fipname: json['fipname'],
      fipid: json['fipid'],
      linkrefnumber: json['linkrefnumber'],
      maskeddemataccount: json['maskeddemataccount'],
      xirrvalue:
          json['xirr'] != null
              ? (json['xirr']).toDouble()
              : json['xirrvalue'] != null
              ? (json['xirrvalue']).toDouble()
              : null,
      cagrvalue: (json['cagrvalue'] ?? 0).toDouble(),
      closingunits:
          json['closingunits'] != null
              ? (json['closingunits']).toDouble()
              : null,
      lienunits:
          json['lienunits'] != null ? (json['lienunits']).toDouble() : null,
      accountguid: json['accountguid'],
      investoremail: json['investoremail'] ?? '',
      investorphonenumber: json['investorphonenumber'],
      investoraddress: json['investoraddress'],
      investordataguid: json['investordataguid'] ?? '',
      deltavalue:
          json['dailygain'] != null
              ? (json['dailygain']).toDouble()
              : json['deltavalue'] != null
              ? (json['deltavalue']).toDouble()
              : null,
      delta: json['delta'] != null ? (json['delta']).toDouble() : null,
      deltapercentage:
          json['dailygainpercentage'] != null
              ? (json['dailygainpercentage']).toDouble()
              : json['deltapercentage'] != null
              ? (json['deltapercentage']).toDouble()
              : null,
      holdingavgprice:
          json['avgbuyprice'] != null
              ? (json['avgbuyprice']).toDouble()
              : json['holdingavgprice'] != null
              ? (json['holdingavgprice']).toDouble()
              : null,
      type: Type.MF,
      swapamount:
          json['swapamount'] != null ? (json['swapamount']).toDouble() : null,
      frequency: json['frequency'],
      installments: json['installments'],
      nextinstallments: json['nextinstallments'],
      lasttransactiondate: json['lasttransactiondate'],
      count: _parseSafeInt(json['count']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Assettype? _parseAssettype(dynamic value) {
    if (value == null) return null;
    String assetTypeStr = value.toString().toUpperCase();
    if (assetTypeStr == 'CASH') return Assettype.CASH;
    if (assetTypeStr == 'DEBT') return Assettype.DEBT;
    if (assetTypeStr == 'EQUITY') return Assettype.EQUITY;
    if (assetTypeStr == 'STOCKS') return Assettype.STOCKS;
    return null;
  }

  Mf({
    this.id,
    required this.createdat,
    required this.userguid,
    required this.logo,
    required this.activestate,
    required this.reqid,
    required this.amc,
    required this.amcname,
    required this.taxstatus,
    this.modeofholding,
    required this.transactionsource,
    this.schemecode,
    required this.name,
    required this.idcwchangeallowed,
    required this.schemeoption,
    this.assettype,
    required this.schemetype,
    required this.nav,
    this.navdate,
    required this.closingbalance,
    this.isdemat,
    required this.currentmktvalue,
    required this.costvalue,
    this.gainloss,
    this.gainlosspercentage,
    this.lienunitsflag,
    required this.decimalunits,
    required this.decimalamount,
    required this.decimalnav,
    required this.brokercode,
    this.brokername,
    this.purallow,
    this.redallow,
    this.swtallow,
    this.sipallow,
    this.stpallow,
    this.swpallow,
    required this.planmode,
    this.dpid,
    this.mobilerelationship,
    this.emailrelationship,
    this.newfolio,
    required this.nomineestatus,
    this.lienavailableunits,
    required this.investorname,
    required this.guid,
    required this.quantity,
    this.rtacode,
    this.lasttrxndate,
    this.openingbal,
    required this.folio,
    this.age,
    required this.phonenumber,
    required this.email,
    required this.availableunits,
    this.availableamount,
    required this.isin,
    required this.validpan,
    required this.kycstatus,
    this.lieneligibleunits,
    this.bankaccnumber,
    this.bankacctype,
    this.bankaccname,
    this.bankbranch,
    this.bankcity,
    this.bankpincode,
    this.bankmicr,
    this.bankifsc,
    this.bankneftifsc,
    required this.rtaname,
    this.foliocreateddate,
    required this.mfsummaryguid,
    this.fatcastatus,
    this.amficode,
    this.isindescription,
    this.lockinunits,
    this.registrar,
    this.schemecategory,
    this.schemetypes,
    this.ucc,
    this.fipname,
    this.fipid,
    this.linkrefnumber,
    this.maskeddemataccount,
    this.xirrvalue,
    required this.cagrvalue,
    this.closingunits,
    this.lienunits,
    this.accountguid,
    required this.investoremail,
    this.investorphonenumber,
    this.investoraddress,
    required this.investordataguid,
    this.deltavalue,
    this.delta,
    this.deltapercentage,
    this.holdingavgprice,
    required this.type,
    this.swapamount,
    this.frequency,
    this.installments,
    this.nextinstallments,
    this.lasttransactiondate,
    this.count,
  });

  Mf copyWith({
    dynamic id,
    DateTime? createdat,
    String? userguid,
    String? logo,
    bool? activestate,
    String? reqid,
    String? amc,
    String? amcname,
    String? taxstatus,
    String? modeofholding,
    String? transactionsource,
    String? schemecode,
    String? name,
    bool? idcwchangeallowed,
    String? schemeoption,
    Assettype? assettype,
    String? schemetype,
    double? nav,
    DateTime? navdate,
    double? closingbalance,
    bool? isdemat,
    double? currentmktvalue,
    double? costvalue,
    double? gainloss,
    double? gainlosspercentage,
    bool? lienunitsflag,
    double? decimalunits,
    double? decimalamount,
    double? decimalnav,
    String? brokercode,
    String? brokername,
    bool? purallow,
    bool? redallow,
    bool? swtallow,
    bool? sipallow,
    bool? stpallow,
    bool? swpallow,
    String? planmode,
    String? dpid,
    String? mobilerelationship,
    String? emailrelationship,
    bool? newfolio,
    String? nomineestatus,
    double? lienavailableunits,
    String? investorname,
    String? guid,
    double? quantity,
    String? rtacode,
    String? lasttrxndate,
    double? openingbal,
    String? folio,
    String? age,
    String? phonenumber,
    String? email,
    double? availableunits,
    double? availableamount,
    String? isin,
    bool? validpan,
    String? kycstatus,
    double? lieneligibleunits,
    String? bankaccnumber,
    String? bankacctype,
    String? bankaccname,
    String? bankbranch,
    String? bankcity,
    String? bankpincode,
    String? bankmicr,
    String? bankifsc,
    String? bankneftifsc,
    String? rtaname,
    DateTime? foliocreateddate,
    String? mfsummaryguid,
    String? fatcastatus,
    String? amficode,
    String? isindescription,
    double? lockinunits,
    String? registrar,
    String? schemecategory,
    String? schemetypes,
    String? ucc,
    String? fipname,
    String? fipid,
    String? linkrefnumber,
    String? maskeddemataccount,
    double? xirrvalue,
    double? cagrvalue,
    double? closingunits,
    double? lienunits,
    String? accountguid,
    String? investoremail,
    String? investorphonenumber,
    String? investoraddress,
    String? investordataguid,
    double? deltavalue,
    double? delta,
    double? deltapercentage,
    double? holdingavgprice,
    Type? type,
    double? swapamount,
    String? frequency,
    String? installments,
    String? nextinstallments,
    String? lasttransactiondate,
    int? count,
  }) {
    return Mf(
      id: id ?? this.id,
      createdat: createdat ?? this.createdat,
      userguid: userguid ?? this.userguid,
      logo: logo ?? this.logo,
      activestate: activestate ?? this.activestate,
      reqid: reqid ?? this.reqid,
      amc: amc ?? this.amc,
      amcname: amcname ?? this.amcname,
      taxstatus: taxstatus ?? this.taxstatus,
      modeofholding: modeofholding ?? this.modeofholding,
      transactionsource: transactionsource ?? this.transactionsource,
      schemecode: schemecode ?? this.schemecode,
      name: name ?? this.name,
      idcwchangeallowed: idcwchangeallowed ?? this.idcwchangeallowed,
      schemeoption: schemeoption ?? this.schemeoption,
      assettype: assettype ?? this.assettype,
      schemetype: schemetype ?? this.schemetype,
      nav: nav ?? this.nav,
      navdate: navdate ?? this.navdate,
      closingbalance: closingbalance ?? this.closingbalance,
      isdemat: isdemat ?? this.isdemat,
      currentmktvalue: currentmktvalue ?? this.currentmktvalue,
      costvalue: costvalue ?? this.costvalue,
      gainloss: gainloss ?? this.gainloss,
      gainlosspercentage: gainlosspercentage ?? this.gainlosspercentage,
      lienunitsflag: lienunitsflag ?? this.lienunitsflag,
      decimalunits: decimalunits ?? this.decimalunits,
      decimalamount: decimalamount ?? this.decimalamount,
      decimalnav: decimalnav ?? this.decimalnav,
      brokercode: brokercode ?? this.brokercode,
      brokername: brokername ?? this.brokername,
      purallow: purallow ?? this.purallow,
      redallow: redallow ?? this.redallow,
      swtallow: swtallow ?? this.swtallow,
      sipallow: sipallow ?? this.sipallow,
      stpallow: stpallow ?? this.stpallow,
      swpallow: swpallow ?? this.swpallow,
      planmode: planmode ?? this.planmode,
      dpid: dpid ?? this.dpid,
      mobilerelationship: mobilerelationship ?? this.mobilerelationship,
      emailrelationship: emailrelationship ?? this.emailrelationship,
      newfolio: newfolio ?? this.newfolio,
      nomineestatus: nomineestatus ?? this.nomineestatus,
      lienavailableunits: lienavailableunits ?? this.lienavailableunits,
      investorname: investorname ?? this.investorname,
      guid: guid ?? this.guid,
      quantity: quantity ?? this.quantity,
      rtacode: rtacode ?? this.rtacode,
      lasttrxndate: lasttrxndate ?? this.lasttrxndate,
      openingbal: openingbal ?? this.openingbal,
      folio: folio ?? this.folio,
      age: age ?? this.age,
      phonenumber: phonenumber ?? this.phonenumber,
      email: email ?? this.email,
      availableunits: availableunits ?? this.availableunits,
      availableamount: availableamount ?? this.availableamount,
      isin: isin ?? this.isin,
      validpan: validpan ?? this.validpan,
      kycstatus: kycstatus ?? this.kycstatus,
      lieneligibleunits: lieneligibleunits ?? this.lieneligibleunits,
      bankaccnumber: bankaccnumber ?? this.bankaccnumber,
      bankacctype: bankacctype ?? this.bankacctype,
      bankaccname: bankaccname ?? this.bankaccname,
      bankbranch: bankbranch ?? this.bankbranch,
      bankcity: bankcity ?? this.bankcity,
      bankpincode: bankpincode ?? this.bankpincode,
      bankmicr: bankmicr ?? this.bankmicr,
      bankifsc: bankifsc ?? this.bankifsc,
      bankneftifsc: bankneftifsc ?? this.bankneftifsc,
      rtaname: rtaname ?? this.rtaname,
      foliocreateddate: foliocreateddate ?? this.foliocreateddate,
      mfsummaryguid: mfsummaryguid ?? this.mfsummaryguid,
      fatcastatus: fatcastatus ?? this.fatcastatus,
      amficode: amficode ?? this.amficode,
      isindescription: isindescription ?? this.isindescription,
      lockinunits: lockinunits ?? this.lockinunits,
      registrar: registrar ?? this.registrar,
      schemecategory: schemecategory ?? this.schemecategory,
      schemetypes: schemetypes ?? this.schemetypes,
      ucc: ucc ?? this.ucc,
      fipname: fipname ?? this.fipname,
      fipid: fipid ?? this.fipid,
      linkrefnumber: linkrefnumber ?? this.linkrefnumber,
      maskeddemataccount: maskeddemataccount ?? this.maskeddemataccount,
      xirrvalue: xirrvalue ?? this.xirrvalue,
      cagrvalue: cagrvalue ?? this.cagrvalue,
      closingunits: closingunits ?? this.closingunits,
      lienunits: lienunits ?? this.lienunits,
      accountguid: accountguid ?? this.accountguid,
      investoremail: investoremail ?? this.investoremail,
      investorphonenumber: investorphonenumber ?? this.investorphonenumber,
      investoraddress: investoraddress ?? this.investoraddress,
      investordataguid: investordataguid ?? this.investordataguid,
      deltavalue: deltavalue ?? this.deltavalue,
      delta: delta ?? this.delta,
      deltapercentage: deltapercentage ?? this.deltapercentage,
      holdingavgprice: holdingavgprice ?? this.holdingavgprice,
      type: type ?? this.type,
      swapamount: swapamount ?? this.swapamount,
      frequency: frequency ?? this.frequency,
      installments: installments ?? this.installments,
      nextinstallments: nextinstallments ?? this.nextinstallments,
      lasttransactiondate: lasttransactiondate ?? this.lasttransactiondate,
      count: count ?? this.count,
    );
  }

  static double? _getValidGainLoss(Map<String, dynamic> json) {
    double? gain =
        json['totalgain'] != null
            ? (json['totalgain']).toDouble()
            : json['gainloss'] != null
            ? (json['gainloss']).toDouble()
            : null;

    // Sanity check: if gain is 0 but current and cost differ, calculate it
    if (gain == null || gain == 0) {
      double current =
          (json['currentvalue'] ?? json['currentmktvalue'] ?? 0.0).toDouble();
      double cost =
          (json['investedamount'] ?? json['costvalue'] ?? 0.0).toDouble();
      if (current > 0 && cost > 0 && (current - cost).abs() > 0.01) {
        return current - cost;
      }
    }
    return gain;
  }

  static double? _getValidGainLossPercentage(Map<String, dynamic> json) {
    double? perc =
        json['totalgainpercentage'] != null
            ? (json['totalgainpercentage']).toDouble()
            : json['gainlosspercentage'] != null
            ? (json['gainlosspercentage']).toDouble()
            : null;

    // Sanity check: if percentage is 0 but current and cost differ, calculate it
    if (perc == null || perc == 0) {
      double current =
          (json['currentvalue'] ?? json['currentmktvalue'] ?? 0.0).toDouble();
      double cost =
          (json['investedamount'] ?? json['costvalue'] ?? 0.0).toDouble();
      if (current > 0 && cost > 0 && (current - cost).abs() > 0.01) {
        return ((current - cost) / cost) * 100;
      }
    }
    return perc;
  }
}

enum Assettype { CASH, DEBT, EQUITY, STOCKS }

enum Type { MF, STOCKS, ETF }

enum TrendType { UP, DOWN, NEUTRAL }

class WeekData {
  final int week;
  final DateTime weekDate;
  final double nav;

  WeekData({required this.week, required this.weekDate, required this.nav});

  factory WeekData.fromJson(Map<String, dynamic> json) {
    AppLogger.info('weekData.fromJson: $json');
    return WeekData(
      week: json['week'] ?? 0,
      weekDate:
          json['weekdate'] != null
              ? _parseSafeDate(json['weekdate']) ?? DateTime.now()
              : DateTime.now(),
      nav: (json['nav']?.toDouble() ?? 0.0).toDouble(),
    );
  }
}

class Graph {
  final double latestNav;
  final TrendType trend;
  final double percentageChange;
  final List<WeekData> weeks;

  Graph({
    required this.latestNav,
    required this.trend,
    required this.percentageChange,
    required this.weeks,
  });

  factory Graph.fromJson(Map<String, dynamic> json) {
    // Parse trend string to enum
    TrendType parseTrend(String? trendStr) {
      if (trendStr == null) return TrendType.NEUTRAL;
      switch (trendStr.toUpperCase()) {
        case 'UP':
          return TrendType.UP;
        case 'DOWN':
          return TrendType.DOWN;
        default:
          return TrendType.NEUTRAL;
      }
    }

    return Graph(
      latestNav: (json['latestnav'] ?? 0).toDouble(),
      trend: parseTrend(json['trend']),
      percentageChange: (json['percentagechange'] ?? 0).toDouble(),
      weeks:
          (json['weeks'] as List<dynamic>? ?? [])
              .map((week) => WeekData.fromJson(week as Map<String, dynamic>))
              .toList(),
    );
  }
}

class Etf {
  dynamic id;
  String userguid;
  String guid;
  bool activestate;
  String type;
  String? isin;
  double units;
  double nav;
  double currentMarketValue;
  DateTime createdat;
  DateTime updatedat;
  String name;
  String status;
  String? foliono;
  double? gainlosspercentage;
  double? deltapercentage;
  double? deltavalue;
  double? gainloss;
  double? investedvalue;
  double? averageholdingprice;
  double? currentmarketprice;
  String? lasttransactiondate;
  double? xirr;
  int? count;
  String? logourl;
  String? broker;
  String? brokername;
  String? fipid;
  String? fipname;

  Etf({
    this.id,
    required this.userguid,
    required this.guid,
    required this.activestate,
    required this.type,
    this.isin,
    required this.units,
    required this.nav,
    required this.currentMarketValue,
    required this.createdat,
    required this.updatedat,
    required this.name,
    required this.status,
    this.foliono,
    this.gainlosspercentage,
    this.deltapercentage,
    this.deltavalue,
    this.gainloss,
    this.investedvalue,
    this.averageholdingprice,
    this.currentmarketprice,
    this.lasttransactiondate,
    this.xirr,
    this.count,
    this.logourl,
    this.broker,
    this.brokername,
    this.fipid,
    this.fipname,
  });

  Etf copyWith({
    dynamic id,
    String? userguid,
    String? guid,
    bool? activestate,
    String? type,
    String? isin,
    double? units,
    double? nav,
    double? currentMarketValue,
    DateTime? createdat,
    DateTime? updatedat,
    String? name,
    String? status,
    String? foliono,
    double? gainlosspercentage,
    double? deltapercentage,
    double? deltavalue,
    double? gainloss,
    double? investedvalue,
    double? averageholdingprice,
    double? currentmarketprice,
    String? lasttransactiondate,
    double? xirr,
    int? count,
    String? logourl,
    String? broker,
    String? brokername,
    String? fipid,
    String? fipname,
  }) {
    return Etf(
      id: id ?? this.id,
      userguid: userguid ?? this.userguid,
      guid: guid ?? this.guid,
      activestate: activestate ?? this.activestate,
      type: type ?? this.type,
      isin: isin ?? this.isin,
      units: units ?? this.units,
      nav: nav ?? this.nav,
      currentMarketValue: currentMarketValue ?? this.currentMarketValue,
      createdat: createdat ?? this.createdat,
      updatedat: updatedat ?? this.updatedat,
      name: name ?? this.name,
      status: status ?? this.status,
      foliono: foliono ?? this.foliono,
      gainlosspercentage: gainlosspercentage ?? this.gainlosspercentage,
      deltapercentage: deltapercentage ?? this.deltapercentage,
      deltavalue: deltavalue ?? this.deltavalue,
      gainloss: gainloss ?? this.gainloss,
      investedvalue: investedvalue ?? this.investedvalue,
      averageholdingprice: averageholdingprice ?? this.averageholdingprice,
      currentmarketprice: currentmarketprice ?? this.currentmarketprice,
      lasttransactiondate: lasttransactiondate ?? this.lasttransactiondate,
      xirr: xirr ?? this.xirr,
      count: count ?? this.count,
      logourl: logourl ?? this.logourl,
      broker: broker ?? this.broker,
      brokername: brokername ?? this.brokername,
      fipid: fipid ?? this.fipid,
      fipname: fipname ?? this.fipname,
    );
  }

  // Helper to parse numeric values that can be strings or numbers
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  factory Etf.fromJson(Map<String, dynamic> json) {
    print(
      'Etf.fromJson: ISIN=${json['isin']}, name=${json['name']}, count from json=${json['count']}',
    );

    // Support both 'currentvalue' (from data.details) and 'currentmktvalue' (legacy)
    final double currentMktValue = _parseDouble(
      json['currentvalue'] ?? json['currentmktvalue'],
    );

    // Support both 'quantity' (from data.details) and 'units' (legacy)
    final double units = _parseDouble(json['quantity'] ?? json['units']);

    return Etf(
      id: json['id'],
      userguid: json['userguid'] ?? '',
      guid: json['guid'] ?? json['accountguid'] ?? '',
      activestate: json['activestate'] ?? false,
      type: json['type'] ?? '',
      isin: json['isin'],
      units: units,
      nav: _parseDouble(json['nav'] ?? json['rate']),
      currentMarketValue: currentMktValue,
      createdat:
          json['createdat'] != null
              ? _parseSafeDate(json['createdat']) ?? DateTime.now()
              : DateTime.now(),
      updatedat:
          json['updatedat'] != null
              ? _parseSafeDate(json['updatedat']) ?? DateTime.now()
              : DateTime.now(),
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      foliono: json['foliono'] ?? json['folio'],
      gainlosspercentage:
          json['gainlosspercentage'] != null
              ? _parseDouble(json['gainlosspercentage'])
              : json['gainpercentage'] != null
              ? _parseDouble(json['gainpercentage'])
              : null,
      deltapercentage:
          json['deltapercentage'] != null
              ? _parseDouble(json['deltapercentage'])
              : json['dailygainpercentage'] != null
              ? _parseDouble(json['dailygainpercentage'])
              : null,
      deltavalue:
          json['deltavalue'] != null
              ? _parseDouble(json['deltavalue'])
              : json['dailygain'] != null
              ? _parseDouble(json['dailygain'])
              : null,
      gainloss:
          json['gainloss'] != null
              ? _parseDouble(json['gainloss'])
              : json['gain'] != null
              ? _parseDouble(json['gain'])
              : json['totalgain'] != null
              ? _parseDouble(json['totalgain'])
              : null,
      investedvalue:
          json['investedvalue'] != null
              ? _parseDouble(json['investedvalue'])
              : json['investedamount'] != null
              ? _parseDouble(json['investedamount'])
              : null,
      averageholdingprice:
          json['averageholdingprice'] != null
              ? _parseDouble(json['averageholdingprice'])
              : json['avgbuyprice'] != null
              ? _parseDouble(json['avgbuyprice'])
              : null,
      currentmarketprice:
          json['currentmarketprice'] == null
              ? null
              : _parseDouble(json['currentmarketprice']),
      lasttransactiondate: json['lasttransactiondate'],
      xirr: json['xirr'] == null ? null : _parseDouble(json['xirr']),
      count: _parseSafeInt(json['count']),
      logourl: json['logourl'] ?? json['logo'] ?? json['icon'],
      broker: json['broker'] ?? json['fipid'] ?? json['fipname'],
      brokername: json['brokername'] ?? json['fipname'] ?? json['fipid'],
      fipid: json['fipid'],
      fipname: json['fipname'],
    );
  }
}

class Stock {
  dynamic id;
  String guid;
  String? isin;
  String name;
  String? icon;
  double currentMarketValue;
  double? costValue;
  double? gainLoss;
  double? gainLossPercentage;
  DateTime? lastUpdatedDate;
  double quantity;
  double? rate;
  Type type;
  String? buydate;
  double? delta;
  double? deltaValue;
  double? averageholdingprice;
  String? navdate;
  double? xirr;
  double? deltapercentage;
  String? issuername;
  String? lasttransactiondate;
  int? count;
  String? logourl;
  String? broker;
  String? brokername;
  String? fipid;
  String? fipname;

  Stock({
    this.id,
    required this.guid,
    this.icon,
    this.isin,
    required this.name,
    required this.currentMarketValue,
    this.costValue,
    this.gainLoss,
    this.gainLossPercentage,
    this.lastUpdatedDate,
    required this.quantity,
    this.rate,
    required this.type,
    this.buydate,
    this.delta,
    this.deltaValue,
    this.averageholdingprice,
    this.navdate,
    this.xirr,
    this.deltapercentage,
    this.issuername,
    this.lasttransactiondate,
    this.count,
    this.logourl,
    this.broker,
    this.brokername,
    this.fipid,
    this.fipname,
  });

  Stock copyWith({
    dynamic id,
    String? guid,
    String? isin,
    String? name,
    String? icon,
    double? currentMarketValue,
    double? costValue,
    double? gainLoss,
    double? gainLossPercentage,
    DateTime? lastUpdatedDate,
    double? quantity,
    double? rate,
    Type? type,
    String? buydate,
    double? delta,
    double? deltaValue,
    double? averageholdingprice,
    String? navdate,
    double? xirr,
    double? deltapercentage,
    String? issuername,
    String? lasttransactiondate,
    int? count,
    String? logourl,
    String? broker,
    String? brokername,
    String? fipid,
    String? fipname,
  }) {
    return Stock(
      id: id ?? this.id,
      guid: guid ?? this.guid,
      isin: isin ?? this.isin,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      currentMarketValue: currentMarketValue ?? this.currentMarketValue,
      costValue: costValue ?? this.costValue,
      gainLoss: gainLoss ?? this.gainLoss,
      gainLossPercentage: gainLossPercentage ?? this.gainLossPercentage,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      type: type ?? this.type,
      buydate: buydate ?? this.buydate,
      delta: delta ?? this.delta,
      deltaValue: deltaValue ?? this.deltaValue,
      averageholdingprice: averageholdingprice ?? this.averageholdingprice,
      navdate: navdate ?? this.navdate,
      xirr: xirr ?? this.xirr,
      deltapercentage: deltapercentage ?? this.deltapercentage,
      issuername: issuername ?? this.issuername,
      lasttransactiondate: lasttransactiondate ?? this.lasttransactiondate,
      count: count ?? this.count,
      logourl: logourl ?? this.logourl,
      broker: broker ?? this.broker,
      brokername: brokername ?? this.brokername,
      fipid: fipid ?? this.fipid,
      fipname: fipname ?? this.fipname,
    );
  }

  // Helper to parse numeric values that can be strings or numbers
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    // Support both 'currentvalue' (from data.details) and 'currentmktvalue' (legacy)
    final double currentMktValue = _parseDouble(
      json['currentvalue'] ?? json['currentmktvalue'],
    );
    final double qty = _parseDouble(json['quantity']);

    print(
      'Stock.fromJson: ISIN=${json['isin']}, name=${json['name']}, count from json=${json['count']}',
    );

    return Stock(
      id: json['id'],
      guid: json['guid'] ?? json['accountguid'] ?? '',
      icon: json['icon'] ?? '',
      isin: json['isin'],
      name: json['name'] ?? '',
      currentMarketValue: currentMktValue,
      costValue:
          json['costvalue'] != null
              ? _parseDouble(json['costvalue'])
              : json['investedamount'] != null
              ? _parseDouble(json['investedamount'])
              : null,
      gainLoss:
          json['gainloss'] != null
              ? _parseDouble(json['gainloss'])
              : json['gain'] != null
              ? _parseDouble(json['gain'])
              : null,
      gainLossPercentage:
          json['gainlosspercentage'] != null
              ? _parseDouble(json['gainlosspercentage'])
              : json['gainpercentage'] != null
              ? _parseDouble(json['gainpercentage'])
              : null,
      lastUpdatedDate:
          json['lastupdateddate'] != null
              ? _parseSafeDate(json['lastupdateddate'])
              : null,
      quantity: _parseDouble(json["quantity"]),
      rate: json['rate'] != null ? _parseDouble(json['rate']) : null,
      issuername: json['issuername'] ?? '',
      type: Type.STOCKS,
      buydate: json['buydate'],
      delta: json['delta'] != null ? _parseDouble(json['delta']) : null,
      deltaValue:
          json['deltavalue'] != null ? _parseDouble(json['deltavalue']) : null,
      averageholdingprice:
          json['averageholdingprice'] != null
              ? _parseDouble(json['averageholdingprice'])
              : json['avgbuyprice'] != null
              ? _parseDouble(json['avgbuyprice'])
              : null,
      navdate: json['navdate'],
      xirr: json['xirr'] != null ? _parseDouble(json['xirr']) : null,
      deltapercentage:
          json['deltapercentage'] != null
              ? _parseDouble(json['deltapercentage'])
              : null,
      lasttransactiondate: json['lasttransactiondate'],
      count: _parseSafeInt(json['count']),
      logourl: json['logourl'] ?? json['logo'] ?? json['icon'],
      broker: json['broker'] ?? json['fipid'] ?? json['fipname'],
      brokername: json['brokername'] ?? json['fipname'] ?? json['fipid'],
      fipid: json['fipid'],
      fipname: json['fipname'],
    );
  }
}

class InvestmentProfile {
  // String guid;
  // String userguid;
  // String accountguid;
  // String name;
  // String dob;
  // String mobile;
  String nominee;
  // String? landline;
  // String address;
  // String email;
  // String pan;
  // String? dematid;
  // String? foliono;
  // bool kyccompliance;
  // DateTime createdat;
  // DateTime updatedat;
  // String fipid;
  String fipname;
  String type;

  InvestmentProfile({
    // required this.guid,
    // required this.userguid,
    // required this.accountguid,
    // required this.name,
    // required this.dob,
    // required this.mobile,
    required this.nominee,
    // this.landline,
    // required this.address,
    // required this.email,
    // required this.pan,
    // this.dematid,
    // this.foliono,
    // required this.kyccompliance,
    // required this.createdat,
    // required this.updatedat,
    // required this.fipid,
    required this.fipname,
    required this.type,
  });

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) =>
      InvestmentProfile(
        // guid: json["guid"],
        // userguid: json["userguid"],
        // accountguid: json["accountguid"],
        // name: json["name"],
        // dob: json["dob"],
        // mobile: json["mobile"],
        nominee: json["nominee"] ?? '',
        // landline: json["landline"],
        // address: json["address"],
        // email: json["email"],
        // pan: json["pan"],
        // dematid: json["dematid"],
        // foliono: json["foliono"],
        // kyccompliance: json["kyccompliance"],
        // createdat: DateTime.parse(json["createdat"]),
        // updatedat: DateTime.parse(json["updatedat"]),
        // fipid: json["fipid"],
        fipname: json["fipname"] ?? '',
        type: json["type"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    // "guid": guid,
    // "userguid": userguid,
    // "accountguid": accountguid,
    // "name": name,
    // "dob": dob,
    // "mobile": mobile,
    "nominee": nominee,
    // "landline": landline,
    // "address": address,
    // "email": email,
    // "pan": pan,
    // "dematid": dematid,
    // "foliono": foliono,
    // "kyccompliance": kyccompliance,
    // "createdat": createdat.toIso8601String(),
    // "updatedat": updatedat.toIso8601String(),
    // "fipid": fipid,
    "fipname": fipname,
    "type": type,
  };
}
