class AboutUsModel {
  final String aboutUs;
  final String aboutUsAr;

  const AboutUsModel({required this.aboutUs, required this.aboutUsAr});

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      aboutUs: json['about_us']?.toString() ?? '',
      aboutUsAr: json['aboutus_ar']?.toString() ?? '',
    );
  }

  String localized(String languageCode) {
    if (languageCode == 'ar' && aboutUsAr.trim().isNotEmpty) return aboutUsAr;
    return aboutUs;
  }
}
