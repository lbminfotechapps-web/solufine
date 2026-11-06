class DsiRecord {
  final String id;
  final String date;
  final String effectiveness;
  final String description;
  final String saveTime;
  final String saveMoney;
  final String imageUrl;
  final String employeeName;

  const DsiRecord({
    required this.id,
    required this.date,
    required this.effectiveness,
    required this.description,
    required this.saveTime,
    required this.saveMoney,
    required this.imageUrl,
    required this.employeeName,
  });
}

class DsiFilter {
  final String userId;
  final String searchText;
  final String fromDate;
  final String toDate;
  final int startLimit;

  const DsiFilter({
    required this.userId,
    this.searchText = '',
    this.fromDate = '',
    this.toDate = '',
    this.startLimit = 0,
  });
}

class AddDsiEntity {
  final String userId;
  final String date;
  final String effectiveness;
  final String description;
  final String saveTime;
  final String saveMoney;
  final String? photoPath;

  const AddDsiEntity({
    required this.userId,
    required this.date,
    required this.effectiveness,
    required this.description,
    this.saveTime = '',
    this.saveMoney = '',
    this.photoPath,
  });
}

class DsiEffectiveness {
  static const addOptions = [
    'Time',
    'Money',
    'Skill Develop',
    'Quality',
    'Both(Time+Money)',
    'Other',
  ];

  static const listOptions = [
    'Time',
    'Money',
    'Skill Develop',
    'Quality',
    'Both(Time+Money)',
    'Other',
  ];
}
