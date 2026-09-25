class InvitationResponse {
  final int statusCode;
  final String message;
  final InvitationData? data;

  InvitationResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? 'No message provided',
      data: json['data'] != null ? InvitationData.fromJson(json['data']) : null,
    );
  }
}

class InvitationData {
  final String invitationId;
  final String familyId;
  final String memberGuid;
  final String memberFirstName;
  final String memberLastName;
  final String memberPhoneNumber;
  final String userGuid;
  final String userFirstName;
  final String userLastName;
  final String userPhoneNumber;
  final String status;
  final String familyName;
  final String invitedAt;
  final String expiresAt;

  InvitationData({
    required this.invitationId,
    required this.familyId,
    required this.memberGuid,
    required this.memberFirstName,
    required this.memberLastName,
    required this.memberPhoneNumber,
    required this.userGuid,
    required this.userFirstName,
    required this.userLastName,
    required this.userPhoneNumber,
    required this.status,
    required this.familyName,
    required this.invitedAt,
    required this.expiresAt,
  });

  factory InvitationData.fromJson(Map<String, dynamic> json) {
    return InvitationData(
      invitationId: json['invitationid'] ?? '',
      familyId: json['familyid'] ?? '',
      memberGuid: json['memberguid'] ?? '',
      memberFirstName: json['memberfirstname'] ?? '',
      memberLastName: json['memberlastname'] ?? '',
      memberPhoneNumber: json['memberphonenumber'] ?? '',
      userGuid: json['userguid'] ?? '',
      userFirstName: json['userfirstname'] ?? '',
      userLastName: json['userlastname'] ?? '',
      userPhoneNumber: json['userphonenumber'] ?? '',
      status: json['status'] ?? '',
      familyName: json['familyname'] ?? '',
      invitedAt: json['invitedat'] ?? '',
      expiresAt: json['expiresat'] ?? '',
    );
  }
}
