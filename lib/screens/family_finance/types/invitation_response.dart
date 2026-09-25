class FamilyInvitationResponse {
  final int statusCode;
  final String message;

  FamilyInvitationResponse({required this.statusCode, required this.message});

  factory FamilyInvitationResponse.fromJson(Map<String, dynamic> json) {
    return FamilyInvitationResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'statusCode': statusCode, 'message': message};
  }

  bool get isSuccess => statusCode == 200 || statusCode == 201;
  bool get isAlreadyAccepted =>
      statusCode == 400 && message.toLowerCase().contains('expired');
}
