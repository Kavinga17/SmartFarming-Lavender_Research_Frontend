enum GrowthStage {
  germination,
  seedling,
  vegetative,
  flowering,
  oilMaturation,
}

class LightingState {
  final int red;
  final int blue;
  final int white;
  final GrowthStage stage;
  final bool isScheduleEnabled;
  final DateTime? scheduleStart;
  final DateTime? scheduleEnd;

  LightingState({
    required this.red,
    required this.blue,
    required this.white,
    required this.stage,
    this.isScheduleEnabled = false,
    this.scheduleStart,
    this.scheduleEnd,
  });

  factory LightingState.initial() {
    return LightingState(
      red: 0,
      blue: 0,
      white: 0,
      stage: GrowthStage.germination,
    );
  }

  LightingState copyWith({
    int? red,
    int? blue,
    int? white,
    GrowthStage? stage,
    bool? isScheduleEnabled,
    DateTime? scheduleStart,
    DateTime? scheduleEnd,
  }) {
    return LightingState(
      red: red ?? this.red,
      blue: blue ?? this.blue,
      white: white ?? this.white,
      stage: stage ?? this.stage,
      isScheduleEnabled: isScheduleEnabled ?? this.isScheduleEnabled,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'red': red,
      'blue': blue,
      'white': white,
      'stage': stage.index,
      'schedule': isScheduleEnabled
          ? {
              'start': scheduleStart?.toIso8601String(),
              'end': scheduleEnd?.toIso8601String(),
            }
          : null,
    };
  }
}