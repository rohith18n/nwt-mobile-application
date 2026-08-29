class UccStatusResponse {
  String? status;
  UccStatusData? data;
  dynamic messages;
  String? error;
  int? statusCode;

  UccStatusResponse({this.status, this.data, this.messages, this.error, this.statusCode});

  UccStatusResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'] != null ? UccStatusData.fromJson(json['data']) : null;
    messages = json['messages'];
    error = json['error'];
    statusCode = json['status_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['messages'] = messages;
    data['error'] = error;
    data['status_code'] = statusCode;
    return data;
  }

  bool get isUccNotFound => error == "UCC not found for user" || statusCode == 404;
}

class UccStatusData {
  Member? member;
  Investor? investor;
  String? holdingNature;
  String? taxStatus;
  String? taxCode;
  String? rdmpIdcwPayMode;
  bool? isClientPhysical;
  bool? isClientDemat;
  bool? isNominationOpted;
  bool? nomineeSoa;
  String? nominationAuthMode;
  String? commMode;
  String? onboarding;
  String? uccStatus;
  List<Holder>? holder;
  dynamic commAddr;
  ForeignAddr? foreignAddr;
  List<BankAccount>? bankAccount;
  List<Fatca>? fatca;
  List<dynamic>? identifiers;
  UccStatusObject? uccStatusObject;

  UccStatusData({
    this.member,
    this.investor,
    this.holdingNature,
    this.taxStatus,
    this.taxCode,
    this.rdmpIdcwPayMode,
    this.isClientPhysical,
    this.isClientDemat,
    this.isNominationOpted,
    this.nomineeSoa,
    this.nominationAuthMode,
    this.commMode,
    this.onboarding,
    this.uccStatus,
    this.holder,
    this.commAddr,
    this.foreignAddr,
    this.bankAccount,
    this.fatca,
    this.identifiers,
    this.uccStatusObject,
  });

  UccStatusData.fromJson(Map<String, dynamic> json) {
    member = json['member'] != null ? Member.fromJson(json['member']) : null;
    investor = json['investor'] != null ? Investor.fromJson(json['investor']) : null;
    holdingNature = json['holding_nature'];
    taxStatus = json['tax_status'];
    taxCode = json['tax_code'];
    rdmpIdcwPayMode = json['rdmp_idcw_pay_mode'];
    isClientPhysical = json['is_client_physical'];
    isClientDemat = json['is_client_demat'];
    isNominationOpted = json['is_nomination_opted'];
    nomineeSoa = json['nominee_soa'];
    nominationAuthMode = json['nomination_auth_mode'];
    commMode = json['comm_mode'];
    onboarding = json['onboarding'];
    uccStatus = json['ucc_status'];
    if (json['holder'] != null) {
      holder = <Holder>[];
      json['holder'].forEach((v) {
        holder!.add(Holder.fromJson(v));
      });
    }
    commAddr = json['comm_addr'];
    foreignAddr = json['foreign_addr'] != null ? ForeignAddr.fromJson(json['foreign_addr']) : null;
    if (json['bank_account'] != null) {
      bankAccount = <BankAccount>[];
      json['bank_account'].forEach((v) {
        bankAccount!.add(BankAccount.fromJson(v));
      });
    }
    if (json['fatca'] != null) {
      fatca = <Fatca>[];
      json['fatca'].forEach((v) {
        fatca!.add(Fatca.fromJson(v));
      });
    }
    if (json['identifiers'] != null) {
      identifiers = <dynamic>[];
      json['identifiers'].forEach((v) {
        identifiers!.add(v);
      });
    }
    uccStatusObject = json['ucc_status_object'] != null ? UccStatusObject.fromJson(json['ucc_status_object']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (member != null) data['member'] = member!.toJson();
    if (investor != null) data['investor'] = investor!.toJson();
    data['holding_nature'] = holdingNature;
    data['tax_status'] = taxStatus;
    data['tax_code'] = taxCode;
    data['rdmp_idcw_pay_mode'] = rdmpIdcwPayMode;
    data['is_client_physical'] = isClientPhysical;
    data['is_client_demat'] = isClientDemat;
    data['is_nomination_opted'] = isNominationOpted;
    data['nominee_soa'] = nomineeSoa;
    data['nomination_auth_mode'] = nominationAuthMode;
    data['comm_mode'] = commMode;
    data['onboarding'] = onboarding;
    data['ucc_status'] = uccStatus;
    if (holder != null) {
      data['holder'] = holder!.map((v) => v.toJson()).toList();
    }
    data['comm_addr'] = commAddr;
    if (foreignAddr != null) data['foreign_addr'] = foreignAddr!.toJson();
    if (bankAccount != null) {
      data['bank_account'] = bankAccount!.map((v) => v.toJson()).toList();
    }
    if (fatca != null) {
      data['fatca'] = fatca!.map((v) => v.toJson()).toList();
    }
    if (identifiers != null) {
      data['identifiers'] = identifiers;
    }
    if (uccStatusObject != null) {
      data['ucc_status_object'] = uccStatusObject!.toJson();
    }
    return data;
  }
}

class Member {
  String? memberId;

  Member({this.memberId});

  Member.fromJson(Map<String, dynamic> json) {
    memberId = json['member_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['member_id'] = memberId;
    return data;
  }
}

class Investor {
  String? clientCode;

  Investor({this.clientCode});

  Investor.fromJson(Map<String, dynamic> json) {
    clientCode = json['client_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['client_code'] = clientCode;
    return data;
  }
}

class Holder {
  String? holderRank;
  String? occCode;
  String? authMode;
  bool? isPanExempt;
  String? panExemptCategory;
  bool? isPanVerified;
  List<Identifier>? identifier;
  String? kycType;
  Person? person;
  List<Contact>? contact;
  List<Nomination>? nomination;

  Holder({
    this.holderRank,
    this.occCode,
    this.authMode,
    this.isPanExempt,
    this.panExemptCategory,
    this.isPanVerified,
    this.identifier,
    this.kycType,
    this.person,
    this.contact,
    this.nomination,
  });

  Holder.fromJson(Map<String, dynamic> json) {
    holderRank = json['holder_rank'];
    occCode = json['occ_code'];
    authMode = json['auth_mode'];
    isPanExempt = json['is_pan_exempt'];
    panExemptCategory = json['pan_exempt_category'];
    isPanVerified = json['is_pan_verified'];
    if (json['identifier'] != null) {
      identifier = <Identifier>[];
      json['identifier'].forEach((v) {
        identifier!.add(Identifier.fromJson(v));
      });
    }
    kycType = json['kyc_type'];
    person = json['person'] != null ? Person.fromJson(json['person']) : null;
    if (json['contact'] != null) {
      contact = <Contact>[];
      json['contact'].forEach((v) {
        contact!.add(Contact.fromJson(v));
      });
    }
    if (json['nomination'] != null) {
      nomination = <Nomination>[];
      json['nomination'].forEach((v) {
        nomination!.add(Nomination.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['holder_rank'] = holderRank;
    data['occ_code'] = occCode;
    data['auth_mode'] = authMode;
    data['is_pan_exempt'] = isPanExempt;
    data['pan_exempt_category'] = panExemptCategory;
    data['is_pan_verified'] = isPanVerified;
    if (identifier != null) {
      data['identifier'] = identifier!.map((v) => v.toJson()).toList();
    }
    data['kyc_type'] = kycType;
    if (person != null) data['person'] = person!.toJson();
    if (contact != null) {
      data['contact'] = contact!.map((v) => v.toJson()).toList();
    }
    if (nomination != null) {
      data['nomination'] = nomination!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Identifier {
  String? identifierType;
  int? identifierTypeId;
  String? identifierNumber;
  bool? isActive;

  Identifier({
    this.identifierType,
    this.identifierTypeId,
    this.identifierNumber,
    this.isActive,
  });

  Identifier.fromJson(Map<String, dynamic> json) {
    identifierType = json['identifier_type'];
    identifierTypeId = json['identifier_type_id'];
    identifierNumber = json['identifier_number'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['identifier_type'] = identifierType;
    data['identifier_type_id'] = identifierTypeId;
    data['identifier_number'] = identifierNumber;
    data['is_active'] = isActive;
    return data;
  }
}

class Person {
  String? firstName;
  String? middleName;
  String? lastName;
  String? dob;
  String? gender;

  Person({this.firstName, this.middleName, this.lastName, this.dob, this.gender});

  Person.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    middleName = json['middle_name'];
    lastName = json['last_name'];
    dob = json['dob'];
    gender = json['gender'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['middle_name'] = middleName;
    data['last_name'] = lastName;
    data['dob'] = dob;
    data['gender'] = gender;
    return data;
  }
}

class Contact {
  String? contactNumber;
  String? countryCode;
  String? whoseContactNumber;
  String? emailAddress;
  String? whoseEmailAddress;
  String? contactType;
  bool? isForeign;

  Contact({
    this.contactNumber,
    this.countryCode,
    this.whoseContactNumber,
    this.emailAddress,
    this.whoseEmailAddress,
    this.contactType,
    this.isForeign,
  });

  Contact.fromJson(Map<String, dynamic> json) {
    contactNumber = json['contact_number'];
    countryCode = json['country_code'];
    whoseContactNumber = json['whose_contact_number'];
    emailAddress = json['email_address'];
    whoseEmailAddress = json['whose_email_address'];
    contactType = json['contact_type'];
    isForeign = json['is_foreign'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['contact_number'] = contactNumber;
    data['country_code'] = countryCode;
    data['whose_contact_number'] = whoseContactNumber;
    data['email_address'] = emailAddress;
    data['whose_email_address'] = whoseEmailAddress;
    data['contact_type'] = contactType;
    data['is_foreign'] = isForeign;
    return data;
  }
}

class Nomination {
  Person? person;
  int? nominationPercent;
  String? nominationRelation;
  bool? isPanExempt;
  bool? isMinor;
  List<NominationIdentifier>? identifier;
  NominationContact? contact;
  CommAddr? commAddr;
  dynamic guardian;

  Nomination({
    this.person,
    this.nominationPercent,
    this.nominationRelation,
    this.isPanExempt,
    this.isMinor,
    this.identifier,
    this.contact,
    this.commAddr,
    this.guardian,
  });

  Nomination.fromJson(Map<String, dynamic> json) {
    person = json['person'] != null ? Person.fromJson(json['person']) : null;
    nominationPercent = json['nomination_percent'];
    nominationRelation = json['nomination_relation'];
    isPanExempt = json['is_pan_exempt'];
    isMinor = json['is_minor'];
    if (json['identifier'] != null) {
      identifier = <NominationIdentifier>[];
      json['identifier'].forEach((v) {
        identifier!.add(NominationIdentifier.fromJson(v));
      });
    }
    contact = json['contact'] != null ? NominationContact.fromJson(json['contact']) : null;
    commAddr = json['comm_addr'] != null ? CommAddr.fromJson(json['comm_addr']) : null;
    guardian = json['guardian'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (person != null) data['person'] = person!.toJson();
    data['nomination_percent'] = nominationPercent;
    data['nomination_relation'] = nominationRelation;
    data['is_pan_exempt'] = isPanExempt;
    data['is_minor'] = isMinor;
    if (identifier != null) {
      data['identifier'] = identifier!.map((v) => v.toJson()).toList();
    }
    if (contact != null) data['contact'] = contact!.toJson();
    if (commAddr != null) data['comm_addr'] = commAddr!.toJson();
    data['guardian'] = guardian;
    return data;
  }
}

class NominationIdentifier {
  String? identifierType;
  String? identifierNumber;

  NominationIdentifier({this.identifierType, this.identifierNumber});

  NominationIdentifier.fromJson(Map<String, dynamic> json) {
    identifierType = json['identifier_type'];
    identifierNumber = json['identifier_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['identifier_type'] = identifierType;
    data['identifier_number'] = identifierNumber;
    return data;
  }
}

class NominationContact {
  String? contactNumber;
  String? comRefWhoseNumber;
  String? emailAddress;
  String? comRefWhoseEmail;
  String? contactType;

  NominationContact({
    this.contactNumber,
    this.comRefWhoseNumber,
    this.emailAddress,
    this.comRefWhoseEmail,
    this.contactType,
  });

  NominationContact.fromJson(Map<String, dynamic> json) {
    contactNumber = json['contact_number'];
    comRefWhoseNumber = json['com_ref_whose_number'];
    emailAddress = json['email_address'];
    comRefWhoseEmail = json['com_ref_whose_email'];
    contactType = json['contact_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['contact_number'] = contactNumber;
    data['com_ref_whose_number'] = comRefWhoseNumber;
    data['email_address'] = emailAddress;
    data['com_ref_whose_email'] = comRefWhoseEmail;
    data['contact_type'] = contactType;
    return data;
  }
}

class CommAddr {
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? state;
  String? country;

  CommAddr({this.addressLine1, this.addressLine2, this.city, this.state, this.country});

  CommAddr.fromJson(Map<String, dynamic> json) {
    addressLine1 = json['address_line_1'];
    addressLine2 = json['address_line_2'];
    city = json['city'];
    state = json['state'];
    country = json['country'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address_line_1'] = addressLine1;
    data['address_line_2'] = addressLine2;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    return data;
  }
}

class ForeignAddr {
  String? addressLine1;
  String? city;
  String? state;
  dynamic country;
  String? postalcode;
  String? countryName;

  ForeignAddr({
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.postalcode,
    this.countryName,
  });

  ForeignAddr.fromJson(Map<String, dynamic> json) {
    addressLine1 = json['address_line_1'];
    city = json['city'];
    state = json['state'];
    country = json['country'];
    postalcode = json['postalcode'];
    countryName = json['country_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address_line_1'] = addressLine1;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['postalcode'] = postalcode;
    data['country_name'] = countryName;
    return data;
  }
}

class BankAccount {
  String? ifscCode;
  String? bankAccNum;
  String? bankAccType;
  String? accountOwner;
  bool? isVerified;

  BankAccount({
    this.ifscCode,
    this.bankAccNum,
    this.bankAccType,
    this.accountOwner,
    this.isVerified,
  });

  BankAccount.fromJson(Map<String, dynamic> json) {
    ifscCode = json['ifsc_code'];
    bankAccNum = json['bank_acc_num'];
    bankAccType = json['bank_acc_type'];
    accountOwner = json['account_owner'];
    isVerified = json['is_verified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ifsc_code'] = ifscCode;
    data['bank_acc_num'] = bankAccNum;
    data['bank_acc_type'] = bankAccType;
    data['account_owner'] = accountOwner;
    data['is_verified'] = isVerified;
    return data;
  }
}

class Fatca {
  String? addressType;
  String? clientName;
  String? countryOfBirth;
  String? dataSource;
  String? dob;
  FatcaIdentifier? identifier;
  String? incomeSlab;
  String? investorType;
  bool? isSelfDeclared;
  Npo? npo;
  String? occCode;
  String? occType;
  String? placeOfBirth;
  String? politicallyExposed;
  List<TaxResidency>? taxResidency;
  String? taxStatus;
  dynamic ubo;
  String? wealthSource;

  Fatca({
    this.addressType,
    this.clientName,
    this.countryOfBirth,
    this.dataSource,
    this.dob,
    this.identifier,
    this.incomeSlab,
    this.investorType,
    this.isSelfDeclared,
    this.npo,
    this.occCode,
    this.occType,
    this.placeOfBirth,
    this.politicallyExposed,
    this.taxResidency,
    this.taxStatus,
    this.ubo,
    this.wealthSource,
  });

  Fatca.fromJson(Map<String, dynamic> json) {
    addressType = json['address_type'];
    clientName = json['client_name'];
    countryOfBirth = json['country_of_birth'];
    dataSource = json['data_source'];
    dob = json['dob'];
    identifier = json['identifier'] != null ? FatcaIdentifier.fromJson(json['identifier']) : null;
    incomeSlab = json['income_slab'];
    investorType = json['investor_type'];
    isSelfDeclared = json['is_self_declared'];
    npo = json['npo'] != null ? Npo.fromJson(json['npo']) : null;
    occCode = json['occ_code'];
    occType = json['occ_type'];
    placeOfBirth = json['place_of_birth'];
    politicallyExposed = json['politically_exposed'];
    if (json['tax_residency'] != null) {
      taxResidency = <TaxResidency>[];
      json['tax_residency'].forEach((v) {
        taxResidency!.add(TaxResidency.fromJson(v));
      });
    }
    taxStatus = json['tax_status'];
    ubo = json['ubo'];
    wealthSource = json['wealth_source'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address_type'] = addressType;
    data['client_name'] = clientName;
    data['country_of_birth'] = countryOfBirth;
    data['data_source'] = dataSource;
    data['dob'] = dob;
    if (identifier != null) data['identifier'] = identifier!.toJson();
    data['income_slab'] = incomeSlab;
    data['investor_type'] = investorType;
    data['is_self_declared'] = isSelfDeclared;
    if (npo != null) data['npo'] = npo!.toJson();
    data['occ_code'] = occCode;
    data['occ_type'] = occType;
    data['place_of_birth'] = placeOfBirth;
    data['politically_exposed'] = politicallyExposed;
    if (taxResidency != null) {
      data['tax_residency'] = taxResidency!.map((v) => v.toJson()).toList();
    }
    data['tax_status'] = taxStatus;
    data['ubo'] = ubo;
    data['wealth_source'] = wealthSource;
    return data;
  }
}

class FatcaIdentifier {
  String? entitySubState;
  String? identifierNumber;
  String? identifierType;

  FatcaIdentifier({this.entitySubState, this.identifierNumber, this.identifierType});

  FatcaIdentifier.fromJson(Map<String, dynamic> json) {
    entitySubState = json['entity_sub_state'];
    identifierNumber = json['identifier_number'];
    identifierType = json['identifier_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['entity_sub_state'] = entitySubState;
    data['identifier_number'] = identifierNumber;
    data['identifier_type'] = identifierType;
    return data;
  }
}

class Npo {
  dynamic npoRgNo;

  Npo({this.npoRgNo});

  Npo.fromJson(Map<String, dynamic> json) {
    npoRgNo = json['npo_rg_no'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['npo_rg_no'] = npoRgNo;
    return data;
  }
}

class TaxResidency {
  String? country;
  String? taxIdNo;
  String? taxIdType;

  TaxResidency({this.country, this.taxIdNo, this.taxIdType});

  TaxResidency.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    taxIdNo = json['tax_id_no'];
    taxIdType = json['tax_id_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    data['tax_id_no'] = taxIdNo;
    data['tax_id_type'] = taxIdType;
    return data;
  }
}

class UccStatusObject {
  List<UccStatusBankAccount>? bankAccount;
  String? clientCode;
  List<dynamic>? depository;
  List<UccStatusHolder>? holders;
  String? memberCode;
  List<TransactionReady>? transactionReady;

  UccStatusObject({
    this.bankAccount,
    this.clientCode,
    this.depository,
    this.holders,
    this.memberCode,
    this.transactionReady,
  });

  UccStatusObject.fromJson(Map<String, dynamic> json) {
    if (json['bank_account'] != null) {
      bankAccount = <UccStatusBankAccount>[];
      json['bank_account'].forEach((v) {
        bankAccount!.add(UccStatusBankAccount.fromJson(v));
      });
    }
    clientCode = json['client_code'];
    if (json['depository'] != null) {
      depository = <dynamic>[];
      json['depository'].forEach((v) {
        depository!.add(v);
      });
    }
    if (json['holders'] != null) {
      holders = <UccStatusHolder>[];
      json['holders'].forEach((v) {
        holders!.add(UccStatusHolder.fromJson(v));
      });
    }
    memberCode = json['member_code'];
    if (json['transaction_ready'] != null) {
      transactionReady = <TransactionReady>[];
      json['transaction_ready'].forEach((v) {
        transactionReady!.add(TransactionReady.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bankAccount != null) {
      data['bank_account'] = bankAccount!.map((v) => v.toJson()).toList();
    }
    data['client_code'] = clientCode;
    if (depository != null) {
      data['depository'] = depository;
    }
    if (holders != null) {
      data['holders'] = holders!.map((v) => v.toJson()).toList();
    }
    data['member_code'] = memberCode;
    if (transactionReady != null) {
      data['transaction_ready'] = transactionReady!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UccStatusBankAccount {
  String? bankAccNum;
  String? createdAt;
  String? ifscCode;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  UccStatusBankAccount({
    this.bankAccNum,
    this.createdAt,
    this.ifscCode,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  UccStatusBankAccount.fromJson(Map<String, dynamic> json) {
    bankAccNum = json['bank_acc_num'];
    createdAt = json['created_at'];
    ifscCode = json['ifsc_code'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bank_acc_num'] = bankAccNum;
    data['created_at'] = createdAt;
    data['ifsc_code'] = ifscCode;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class UccStatusHolder {
  dynamic aof;
  dynamic aofRia;
  Elog? elog;
  List<FatcaStatus>? fatcaStatus;
  String? holderPan;
  String? holderRank;
  KycStatus? kycStatus;
  Nominee2fa? nominee2fa;
  PanVerification? panVerification;

  UccStatusHolder({
    this.aof,
    this.aofRia,
    this.elog,
    this.fatcaStatus,
    this.holderPan,
    this.holderRank,
    this.kycStatus,
    this.nominee2fa,
    this.panVerification,
  });

  UccStatusHolder.fromJson(Map<String, dynamic> json) {
    aof = json['aof'];
    aofRia = json['aof_ria'];
    elog = json['elog'] != null ? Elog.fromJson(json['elog']) : null;
    if (json['fatca_status'] != null) {
      fatcaStatus = <FatcaStatus>[];
      json['fatca_status'].forEach((v) {
        fatcaStatus!.add(FatcaStatus.fromJson(v));
      });
    }
    holderPan = json['holder_pan'];
    holderRank = json['holder_rank'];
    kycStatus = json['kyc_status'] != null ? KycStatus.fromJson(json['kyc_status']) : null;
    nominee2fa = json['nominee_2fa'] != null ? Nominee2fa.fromJson(json['nominee_2fa']) : null;
    panVerification = json['pan_verification'] != null ? PanVerification.fromJson(json['pan_verification']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['aof'] = aof;
    data['aof_ria'] = aofRia;
    if (elog != null) data['elog'] = elog!.toJson();
    if (fatcaStatus != null) {
      data['fatca_status'] = fatcaStatus!.map((v) => v.toJson()).toList();
    }
    data['holder_pan'] = holderPan;
    data['holder_rank'] = holderRank;
    if (kycStatus != null) data['kyc_status'] = kycStatus!.toJson();
    if (nominee2fa != null) data['nominee_2fa'] = nominee2fa!.toJson();
    if (panVerification != null) data['pan_verification'] = panVerification!.toJson();
    return data;
  }
}

class Elog {
  String? acceptedAt;
  String? ip;
  List<RtaVerification>? rtaVerification;
  String? status;

  Elog({this.acceptedAt, this.ip, this.rtaVerification, this.status});

  Elog.fromJson(Map<String, dynamic> json) {
    acceptedAt = json['accepted_at'];
    ip = json['ip'];
    if (json['rta_verification'] != null) {
      rtaVerification = <RtaVerification>[];
      json['rta_verification'].forEach((v) {
        rtaVerification!.add(RtaVerification.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accepted_at'] = acceptedAt;
    data['ip'] = ip;
    if (rtaVerification != null) {
      data['rta_verification'] = rtaVerification!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    return data;
  }
}

class RtaVerification {
  String? createdAt;
  String? rtaType;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  RtaVerification({
    this.createdAt,
    this.rtaType,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  RtaVerification.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    rtaType = json['rta_type'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['rta_type'] = rtaType;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class FatcaStatus {
  String? createdAt;
  String? rtaType;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  FatcaStatus({
    this.createdAt,
    this.rtaType,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  FatcaStatus.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    rtaType = json['rta_type'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['rta_type'] = rtaType;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class KycStatus {
  String? createdAt;
  String? kycType;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  KycStatus({
    this.createdAt,
    this.kycType,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  KycStatus.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    kycType = json['kyc_type'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['kyc_type'] = kycType;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class Nominee2fa {
  String? createdAt;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  Nominee2fa({
    this.createdAt,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  Nominee2fa.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class PanVerification {
  String? createdAt;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  PanVerification({
    this.createdAt,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  PanVerification.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}

class TransactionReady {
  String? createdAt;
  String? mode;
  String? verificationFailedReason;
  String? verifiedAt;
  String? verifiedStatus;

  TransactionReady({
    this.createdAt,
    this.mode,
    this.verificationFailedReason,
    this.verifiedAt,
    this.verifiedStatus,
  });

  TransactionReady.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    mode = json['mode'];
    verificationFailedReason = json['verification_failed_reason'];
    verifiedAt = json['verified_at'];
    verifiedStatus = json['verified_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['mode'] = mode;
    data['verification_failed_reason'] = verificationFailedReason;
    data['verified_at'] = verifiedAt;
    data['verified_status'] = verifiedStatus;
    return data;
  }
}
