class SelectedCropDetail {
  final String cropId;
  final String cropName;
  final DateTime date;
  final String acre;
  final String irrigationId;
  final String irrigationName;

  SelectedCropDetail({
    required this.cropId,
    required this.cropName,
    required this.date,
    required this.acre,
    required this.irrigationId,
    required this.irrigationName,
  });

  Map<String, dynamic> toJson() => {
    'cropId': cropId,
    'cropName': cropName,
    'date': date.toIso8601String(),
    'acre': acre,
    'irrigationId': irrigationId,
    'irrigationName': irrigationName,
  };
}