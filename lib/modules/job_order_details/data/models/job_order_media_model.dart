class JobOrderMediaModel {
  final int id;
  final String url;
  final String? tag;
  final bool isVideo;

  const JobOrderMediaModel({
    required this.id,
    required this.url,
    required this.tag,
    required this.isVideo,
  });

  factory JobOrderMediaModel.fromJson(
    Map<String, dynamic> json, {
    required bool isVideo,
  }) {
    final rawTag = json['tag'];
    final tag = rawTag == null ? null : rawTag.toString();
    return JobOrderMediaModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      url: json['url']?.toString() ?? '',
      tag: (tag == null || tag.trim().isEmpty) ? null : tag.trim(),
      isVideo: isVideo,
    );
  }
}
