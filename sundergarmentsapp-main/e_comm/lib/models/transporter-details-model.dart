// ignore_for_file: file_names

class TransporterDetailsModel {
  final String transporterName;
  final String awbNumber;
  final String consignmentNumber;
  final String? lrNumber;
  final String transportCompany;
  final DateTime dispatchDate;
  final DateTime? estimatedDeliveryDate;
  final String? trackingUrl;
  final String? remarks;

  TransporterDetailsModel({
    required this.transporterName,
    required this.awbNumber,
    required this.consignmentNumber,
    this.lrNumber,
    required this.transportCompany,
    required this.dispatchDate,
    this.estimatedDeliveryDate,
    this.trackingUrl,
    this.remarks,
  });

  factory TransporterDetailsModel.fromMap(Map<String, dynamic> json) {
    return TransporterDetailsModel(
      transporterName: json['transporterName']?.toString() ?? '',
      awbNumber: json['awbNumber']?.toString() ?? '',
      consignmentNumber: json['consignmentNumber']?.toString() ?? '',
      lrNumber: json['lrNumber']?.toString(),
      transportCompany: json['transportCompany']?.toString() ?? '',
      dispatchDate: _toDateTime(json['dispatchDate']) ?? DateTime.now(),
      estimatedDeliveryDate: _toDateTime(json['estimatedDeliveryDate']),
      trackingUrl: json['trackingUrl']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }
}
