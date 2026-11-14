
import 'package:equatable/equatable.dart';

class SeasonListEntity extends Equatable {
  final bool status;
  final String message;
  final List<SeasonItemEntity> result;

  const SeasonListEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [
        status,
        message,
        result,
      ];
}

class SeasonItemEntity extends Equatable {
  final String seasonId;
  final String seasonName;

  const SeasonItemEntity({
    required this.seasonId,
    required this.seasonName,
  });

  @override
  List<Object?> get props => [
        seasonId,
        seasonName,
      ];
}
