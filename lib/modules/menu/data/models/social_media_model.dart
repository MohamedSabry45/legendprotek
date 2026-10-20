class SocialMediaItemModel {
  final int id;
  final String name;
  final String iconUrl;
  final String link;

  const SocialMediaItemModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.link,
  });

  factory SocialMediaItemModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }
}
