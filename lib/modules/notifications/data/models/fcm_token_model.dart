class FcmTokenModel {
  FcmTokenModel({
    required this.success,
    required this.message,
    this.tokenId,
    this.userId,
  });

  final bool success;
  final String message;
  final int? tokenId;
  final int? userId;

  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return FcmTokenModel(
      success: json['success'] == true || json['success']?.toString() == 'true',
      message: json['message']?.toString() ?? '',
      tokenId: toInt(json['token_id']),
      userId: toInt(json['user_id']),
    );
  }
}
