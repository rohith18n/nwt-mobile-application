import 'package:nwt_app/services/remote_config/remote_config_service.dart';

/// Onboarding flow type selected in "What brings you here?".
/// Values match backend: track_my_investments | explore_mutual_funds | complete_kyc | get_me_in.
enum OnboardingFlowType {
  trackMyInvestments,
  exploreMutualFunds,
  completeKyc,
  getMeIn;

  /// String value sent to / received from the API.
  String get apiValue {
    switch (this) {
      case OnboardingFlowType.trackMyInvestments:
        return 'track_my_investments';
      case OnboardingFlowType.exploreMutualFunds:
        return 'explore_mutual_funds';
      case OnboardingFlowType.completeKyc:
        return 'complete_kyc';
      case OnboardingFlowType.getMeIn:
        return 'get_me_in';
    }
  }

  static OnboardingFlowType? fromApi(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'track_my_investments':
        return OnboardingFlowType.trackMyInvestments;
      case 'explore_mutual_funds':
        return OnboardingFlowType.exploreMutualFunds;
      case 'complete_kyc':
        return OnboardingFlowType.completeKyc;
      case 'get_me_in':
        return OnboardingFlowType.getMeIn;
      default:
        return null;
    }
  }
}

class UserDataResponse {
  bool success;
  String message;
  String? onboardingStatus;
  User? user; // This will hold the direct fields from 'data'
  Map<String, dynamic>?
  data; // Hold the raw data for other fields like profile_issues
  int? statusCode;

  UserDataResponse({
    required this.success,
    required this.message,
    this.onboardingStatus,
    this.user,
    this.data,
    this.statusCode,
  });

  factory UserDataResponse.fromJson(Map<String, dynamic> json) {
    final success = json["success"] ?? false;
    final message = json["message"] ?? "";
    final onboardingStatus = json["onboarding_status"];
    final data = json["data"];

    User? user;
    if (data != null && data is Map<String, dynamic>) {
      user = User.fromJson(data);
    }

    return UserDataResponse(
      success: success,
      message: message,
      onboardingStatus: onboardingStatus,
      user: user,
      data: data,
      statusCode: json["statusCode"],
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "onboarding_status": onboardingStatus,
    "data": data,
  };

  // Deprecated status field for backward compatibility
  int get status => success ? 200 : 400;
}

// Removed DataResponse as the new API flattens the user object under 'data'

class OnboardingStatusResponse {
  bool success;
  String status;
  int? statusCode;

  OnboardingStatusResponse({
    required this.success,
    required this.status,
    this.statusCode,
  });

  factory OnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json["data"];
    String status = json["status"] ?? json["onboarding_status"] ?? "";
    if (status.isEmpty && data != null && data is Map) {
      status = data["status"] ?? "";
    }

    return OnboardingStatusResponse(
      success: json["success"] ?? false,
      status: status,
      statusCode: json["statusCode"],
    );
  }

  Map<String, dynamic> toJson() => {"success": success, "status": status};
}

class User {
  String id;
  String? phonenumber;
  String? panphonenumber;
  String? guid;
  String? firstname;
  String? lastname;
  String? email;
  dynamic createdat;
  bool isverified;
  DateTime? dob;
  bool isonboardingcompleted;
  bool ispanverified;
  String? gender;
  bool ismfverified; // This is mapped from 'ismffetched' in the API response
  int? yearsuntilretirement; // Years remaining until retirement age
  dynamic mfcstatus; // Status of MF fetching process with substeps
  bool isfamily;
  bool? skipmfc;
  bool isfpquestionanswered;
  bool istestaccount;
  bool? isNri;
  bool? nri_phone_exists;
  String? secondaryphonenumber;
  String? pannumber;

  /// AA provider: SAAFE (Saafe) or FINARKEIN; null/empty treated as SAAFE
  String? aaProvider;

  /// Selected onboarding flow from "What brings you here?"
  OnboardingFlowType? onboardingFlowType;

  /// Per-flow status map from backend
  Map<String, dynamic>? onboardingFlowStatus;

  /// UCC profile data containing address and bank info
  Map<String, dynamic>? uccProfile;

  /// Full raw data map from the API response
  Map<String, dynamic>? rawData;

  /// True when aa_provider is FINARKEIN; otherwise Saafe (SAAFE).
  bool get isFinarkeinAa => true;
  // bool get isFinarkeinAa =>
  // (aaProvider ?? '').toString().toUpperCase() == 'FINARKEIN';

  User({
    required this.id,
    this.phonenumber,
    this.panphonenumber,
    this.guid,
    this.firstname,
    this.lastname,
    this.email,
    required this.createdat,
    required this.isverified,
    this.dob,
    required this.isonboardingcompleted,
    required this.ispanverified,
    this.gender,
    required this.ismfverified,
    this.yearsuntilretirement,
    this.mfcstatus,
    required this.isfamily,
    this.skipmfc,
    required this.isfpquestionanswered,
    required this.istestaccount,
    this.isNri,
    this.nri_phone_exists,
    this.secondaryphonenumber,
    this.pannumber,
    this.aaProvider,
    this.onboardingFlowType,
    this.onboardingFlowStatus,
    this.uccProfile,
    this.rawData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? firstname = json["firstname"];
    String? lastname = json["lastname"];
    if ((firstname == null || firstname.isEmpty) && json["name"] != null) {
      final nameParts = (json["name"] as String).split(' ');
      firstname = nameParts.first;
      if (nameParts.length > 1) {
        lastname = nameParts.sublist(1).join(' ');
      }
    }

    return User(
      id: json["id"]?.toString() ?? "",
      phonenumber: json["phonenumber"] ?? json["phone_number"],
      panphonenumber: json["panphonenumber"] ?? json["pan_phone_number"],
      guid: json["guid"],
      firstname: firstname,
      lastname: lastname,
      email: json["email"],
      createdat: json["createdat"] ?? "",
      isverified: json["isverified"] ?? false,
      dob: json["dob"] != null ? DateTime.parse(json["dob"]) : null,
      isonboardingcompleted: json["isonboardingcompleted"] ?? false,
      ispanverified:
          json["ispanverified"] ??
          json["kyc_done"] ??
          (json["kyc"]?["status"] == "VALID") ??
          false,
      gender: json["gender"],
      ismfverified: json["ismffetched"] ?? false,
      mfcstatus: json["mfcstatus"],
      yearsuntilretirement:
          json["dob"] != null
              ? _calculateYearsUntilRetirement(DateTime.parse(json["dob"]))
              : 40,
      isfamily: json["isfamily"] ?? false,
      skipmfc: json["skipmfc"] ?? false,
      isfpquestionanswered: json["isfpquestionanswered"] ?? false,
      istestaccount: RemoteConfigService.to.testAccounts.value
          .split(',')
          .contains(json["phonenumber"] ?? ""),
      isNri: json["is_nri"] ?? false,
      nri_phone_exists: json["nri_phone_exists"] ?? false,
      secondaryphonenumber: json["secondaryphonenumber"] ?? "",
      pannumber: json["pannumber"] ?? json["pan_number"] ?? "",
      aaProvider: json["aa_provider"] ?? json["aaProvider"],
      onboardingFlowType: OnboardingFlowType.fromApi(
        json["onboarding_flow_type"],
      ),
      onboardingFlowStatus:
          json["onboarding_flow_status"] != null
              ? Map<String, dynamic>.from(json["onboarding_flow_status"] as Map)
              : null,
      uccProfile:
          json["ucc_profile"] != null
              ? Map<String, dynamic>.from(json["ucc_profile"] as Map)
              : null,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "phonenumber": phonenumber,
    "panphonenumber": panphonenumber,
    "guid": guid,
    "firstname": firstname,
    "lastname": lastname,
    "email": email,
    "createdat": createdat,
    "isverified": isverified,
    "dob":
        dob != null
            ? "${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}"
            : null,
    "isonboardingcompleted": isonboardingcompleted,
    "ispanverified": ispanverified,
    "gender": gender,
    "ismfverified": ismfverified,
    "mfcstatus": mfcstatus,
    "ageto60": yearsuntilretirement,
    "isfamily": isfamily,
    "skipmfc": skipmfc,
    "isfpquestionanswered": isfpquestionanswered,
    "istestaccount": istestaccount,
    "isNri": isNri,
    "nri_phone_exists": nri_phone_exists,
    "secondaryphonenumber": secondaryphonenumber,
    "aa_provider": aaProvider,
    "onboarding_flow_type": onboardingFlowType?.apiValue,
    "onboarding_flow_status": onboardingFlowStatus,
    "ucc_profile": uccProfile,
    "rawData": rawData,
  };

  static int _calculateYearsUntilRetirement(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;

    // Adjust if birthday hasn't occurred yet this year
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }

    try {
      // Get retirement age from remote config or default to 70
      final retirementAge =
          RemoteConfigService.to.ageTillRetirement.value > 0
              ? RemoteConfigService.to.ageTillRetirement.value
              : 70;

      // Calculate years until retirement age
      final yearsUntilRetirement = retirementAge - years;

      // Return at least 1 year if already over retirement age
      return yearsUntilRetirement > 0 ? yearsUntilRetirement : 1;
    } catch (e) {
      // Fallback to default retirement age of 70 if remote config is not available
      final yearsUntil70 = 70 - years;
      return yearsUntil70 > 0 ? yearsUntil70 : 1;
    }
  }
}

class SetPinResponse {
  int statusCode;
  String message;

  SetPinResponse({required this.statusCode, required this.message});

  factory SetPinResponse.fromJson(Map<String, dynamic> json) =>
      SetPinResponse(statusCode: json["statusCode"], message: json["message"]);

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
  };
}
