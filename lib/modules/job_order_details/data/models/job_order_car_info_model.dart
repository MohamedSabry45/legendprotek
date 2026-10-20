class JobOrderCarInfoModel {
  final String name;
  final String mobile;
  final String color;
  final String plateNumber;
  final String number;
  final String chassisNumber;
  final String year;
  final String model;
  final String catname;
  final String service;
  final int status;
  final String entryDate;
  final String dueDate;
  final String bookingStart;
  final String jobSheetNo;

  const JobOrderCarInfoModel({
    required this.name,
    required this.mobile,
    required this.color,
    required this.plateNumber,
    required this.number,
    required this.chassisNumber,
    required this.year,
    required this.model,
    required this.catname,
    required this.service,
    required this.status,
    required this.entryDate,
    required this.dueDate,
    required this.bookingStart,
    required this.jobSheetNo,
  });

  factory JobOrderCarInfoModel.fromJson(Map<String, dynamic> json) {
    return JobOrderCarInfoModel(
      name: json['name']?.toString() ?? '',
      mobile: (json['mobile'] ?? json['mobile '])?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      chassisNumber: json['chassisNumber']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      catname: json['catname']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '') ?? 0,
      entryDate: json['entry_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      bookingStart: json['booking_start']?.toString() ?? '',
      jobSheetNo: json['job_sheet_no']?.toString() ?? '',
    );
  }
}
