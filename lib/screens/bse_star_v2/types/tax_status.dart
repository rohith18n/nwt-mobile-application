class TaxStatus {
  final String code;
  final String status;
  final String type;
  final bool isResident;
  final bool isMinor;

  const TaxStatus({
    required this.code,
    required this.status,
    required this.type,
    required this.isResident,
    required this.isMinor,
  });

  static List<TaxStatus> get all => const [
    TaxStatus(
      code: '01',
      status: 'Individual',
      type: 'Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '02',
      status: 'On behalf of minor',
      type: 'Individual',
      isResident: true,
      isMinor: true,
    ),
    TaxStatus(
      code: '03',
      status: 'HUF',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '04',
      status: 'Company',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '05',
      status: 'AOP',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '06',
      status: 'Partnership Firm',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '07',
      status: 'Body Corporate',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '08',
      status: 'Trust',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '09',
      status: 'Society',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '10',
      status: 'Others',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '11',
      status: 'NRI-Others',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '12',
      status: 'DFI',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '13',
      status: 'Sole Proprietorship',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '21',
      status: 'NRE',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '22',
      status: 'OCB',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '23',
      status: 'FII',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '24',
      status: 'NRO',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '25',
      status: 'Overseas Corp. Body - Others',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '26',
      status: 'NRI Child',
      type: 'Individual',
      isResident: false,
      isMinor: true,
    ),
    TaxStatus(
      code: '27',
      status: 'NRI - HUF (NRO)',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '28',
      status: 'NRI - Minor (NRO)',
      type: 'Individual',
      isResident: false,
      isMinor: true,
    ),
    TaxStatus(
      code: '29',
      status: 'NRI - HUF (NRE)',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '31',
      status: 'Provident Fund',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '32',
      status: 'Super Annuation Fund',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '33',
      status: 'Gratuity Fund',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '34',
      status: 'Pension Fund',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '36',
      status: 'Mutual Funds FOF Schemes',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '37',
      status: 'NPS Trust',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '38',
      status: 'Global Development Network',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '39',
      status: 'FCRA',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '41',
      status: 'QFI - Individual',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '42',
      status: 'QFI - Minors',
      type: 'Individual',
      isResident: false,
      isMinor: true,
    ),
    TaxStatus(
      code: '43',
      status: 'QFI - Corporate',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '44',
      status: 'QFI - Pension Funds',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '45',
      status: 'QFI - Hedge Funds',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '46',
      status: 'QFI - Mutual Funds',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '47',
      status: 'LLP',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '48',
      status: 'Non-Profit organization [NPO]',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '51',
      status: 'Public Limited Company',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '52',
      status: 'Private Limited Company',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '53',
      status: 'Unlisted Company',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '54',
      status: 'Mutual Funds',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '55',
      status: 'FPI - Category I',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '56',
      status: 'FPI - Category II',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '57',
      status: 'FPI - Category III',
      type: 'Non-Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '58',
      status: 'Financial Institutions',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '59',
      status: 'Body of Individuals',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '60',
      status: 'Insurance Company',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '61',
      status: 'OCI - Repatriation',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '62',
      status: 'OCI - Non Repatriation',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '70',
      status: 'Person of Indian Origin',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '72',
      status: 'Government Body',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '73',
      status: 'Defense Establishment',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '74',
      status: 'Non - Government Organisation',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '75',
      status: 'Bank/Co-Operative Bank',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '76',
      status: 'Artificial Juridical person',
      type: 'Non-Individual',
      isResident: true,
      isMinor: false,
    ),
    TaxStatus(
      code: '77',
      status: 'Seafarer NRE',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
    TaxStatus(
      code: '78',
      status: 'Seafarer NRO',
      type: 'Individual',
      isResident: false,
      isMinor: false,
    ),
  ];

  static List<TaxStatus> get individuals =>
      all.where((status) => status.type == 'Individual').toList();

  static List<TaxStatus> get bseOptions => [
        all.firstWhere((e) => e.code == '01'),
        all.firstWhere((e) => e.code == '21'),
        all.firstWhere((e) => e.code == '24'),
      ];

  String get bseDescription {
    if (code == '21') {
      return 'Non-Resident External (Repatriable - Funds can be moved abroad)';
    }
    if (code == '24') {
      return 'Non-Resident Ordinary (Non-Repatriable - Funds for use in India)';
    }
    if (code == '01') {
      return 'Resident Indian Individual';
    }
    return '';
  }
}
