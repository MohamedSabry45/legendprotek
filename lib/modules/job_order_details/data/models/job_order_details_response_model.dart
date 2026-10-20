import 'job_order_car_info_model.dart';
import 'job_order_media_model.dart';
import 'job_order_spare_part_model.dart';

class JobOrderDetailsResponseModel {
  final String success;
  final JobOrderCarInfoModel? carInfo;
  final String bookingStart;
  final String jobSheetNo;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int statusId;
  final List<JobOrderSparePartModel> jobOrder;
  final List<JobOrderMediaModel> media;
  final String? token;

  const JobOrderDetailsResponseModel({
    required this.success,
    required this.carInfo,
    required this.bookingStart,
    required this.jobSheetNo,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.statusId,
    required this.jobOrder,
    required this.media,
    required this.token,
  });

  factory JobOrderDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    final carJson = json['dataofcar'];

    final jobOrderJson = json['job_order'];
    final jobOrder = <JobOrderSparePartModel>[];
    if (jobOrderJson is List) {
      for (final item in jobOrderJson) {
        if (item is Map<String, dynamic>) {
          jobOrder.add(JobOrderSparePartModel.fromJson(item));
        }
      }
    }

    final media = <JobOrderMediaModel>[
      ..._parseMediaList(json['tagged_images'], isVideo: false),
      ..._parseMediaList(json['booking_images'], isVideo: false),
      ..._parseMediaList(json['videos'], isVideo: true),
    ];

    return JobOrderDetailsResponseModel(
      success: json['success']?.toString() ?? '',
      carInfo: carJson is Map<String, dynamic>
          ? JobOrderCarInfoModel.fromJson(carJson)
          : null,
      bookingStart: json['booking_start']?.toString() ?? '',
      jobSheetNo: json['job_sheet_no']?.toString() ?? '',
      days: json['days'] is int
          ? json['days'] as int
          : int.tryParse(json['days']?.toString() ?? '') ?? 0,
      hours: json['hours'] is int
          ? json['hours'] as int
          : int.tryParse(json['hours']?.toString() ?? '') ?? 0,
      minutes: json['minutes'] is int
          ? json['minutes'] as int
          : int.tryParse(json['minutes']?.toString() ?? '') ?? 0,
      seconds: json['seconds'] is int
          ? json['seconds'] as int
          : int.tryParse(json['seconds']?.toString() ?? '') ?? 0,
      statusId: json['status_id'] is int
          ? json['status_id'] as int
          : int.tryParse(json['status_id']?.toString() ?? '') ?? 0,
      jobOrder: jobOrder,
      media: media,
      token: json['token']?.toString(),
    );
  }

  static List<JobOrderMediaModel> _parseMediaList(
    Object? raw, {
    required bool isVideo,
  }) {
    if (raw is! List) return const <JobOrderMediaModel>[];
    return raw
        .whereType<Map>()
        .map(
          (e) => JobOrderMediaModel.fromJson(
            Map<String, dynamic>.from(e),
            isVideo: isVideo,
          ),
        )
        .where((m) => m.url.trim().isNotEmpty)
        .toList();
  }
}
