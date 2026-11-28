import 'package:app_events/domain/models/spin_json_helpers.dart';

/// Supported mission types in GDG SPIN Phase 2.
enum SpinMissionType {
  profileComplete('profile_complete'),
  workshopRegister('workshop_register'),
  askSpeaker('ask_speaker'),
  rateTalk('rate_talk'),
  trivia('trivia');

  final String value;
  const SpinMissionType(this.value);

  static SpinMissionType fromValue(String? text) {
    for (final missionType in values) {
      if (missionType.value == text) return missionType;
    }
    return SpinMissionType.profileComplete;
  }
}

/// Mission or live trivia challenge that grants spin tickets when completed.
class SpinMission {
  final String id;
  final SpinMissionType type;
  final String title;
  final String description;
  final int reward;
  final int targetCount;
  final int maxCompletionsPerUser;
  final bool done;
  final int completions;
  final String? actionLabel;
  final bool active;
  final int order;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? triviaQuestion;
  final List<String> triviaOptions;
  final int? minAboutMeLength;
  final DateTime? updatedAt;

  const SpinMission({
    required this.id,
    required this.title,
    required this.reward,
    this.done = false,
    this.actionLabel,
    bool isTrivia = false,
    SpinMissionType? type,
    this.description = '',
    this.targetCount = 1,
    this.maxCompletionsPerUser = 1,
    this.completions = 0,
    this.active = true,
    this.order = 0,
    this.startsAt,
    this.endsAt,
    this.triviaQuestion,
    this.triviaOptions = const [],
    this.minAboutMeLength,
    this.updatedAt,
  }) : type =
           type ??
           (isTrivia
               ? SpinMissionType.trivia
               : SpinMissionType.profileComplete);

  bool get isTrivia => type == SpinMissionType.trivia;

  int get rewardTickets => reward;

  SpinMission copyWith({
    String? id,
    SpinMissionType? type,
    bool? isTrivia,
    String? title,
    String? description,
    int? reward,
    int? targetCount,
    int? maxCompletionsPerUser,
    bool? done,
    int? completions,
    String? actionLabel,
    bool clearActionLabel = false,
    bool? active,
    int? order,
    DateTime? startsAt,
    bool clearStartsAt = false,
    DateTime? endsAt,
    bool clearEndsAt = false,
    String? triviaQuestion,
    bool clearTriviaQuestion = false,
    List<String>? triviaOptions,
    int? minAboutMeLength,
    bool clearMinAboutMeLength = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    final nextType =
        type ??
        (isTrivia == null
            ? this.type
            : (isTrivia
                  ? SpinMissionType.trivia
                  : SpinMissionType.profileComplete));
    return SpinMission(
      id: id ?? this.id,
      type: nextType,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      targetCount: targetCount ?? this.targetCount,
      maxCompletionsPerUser:
          maxCompletionsPerUser ?? this.maxCompletionsPerUser,
      done: done ?? this.done,
      completions: completions ?? this.completions,
      actionLabel: clearActionLabel ? null : (actionLabel ?? this.actionLabel),
      active: active ?? this.active,
      order: order ?? this.order,
      startsAt: clearStartsAt ? null : (startsAt ?? this.startsAt),
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      triviaQuestion: clearTriviaQuestion
          ? null
          : (triviaQuestion ?? this.triviaQuestion),
      triviaOptions: triviaOptions ?? this.triviaOptions,
      minAboutMeLength: clearMinAboutMeLength
          ? null
          : (minAboutMeLength ?? this.minAboutMeLength),
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }

  factory SpinMission.fromJson(Map<String, dynamic> json) {
    final hasType =
        json['type'] is String && (json['type'] as String).isNotEmpty;
    final parsedType = hasType
        ? SpinMissionType.fromValue(json['type'] as String?)
        : (json['isTrivia'] == true
              ? SpinMissionType.trivia
              : SpinMissionType.profileComplete);

    final config = parseDynamicMap(json['config']);
    final triviaQuestion = parseNullableString(
      config['question'] ?? json['triviaQuestion'],
    );
    final triviaOptions = config.containsKey('options')
        ? parseStringList(config['options'])
        : parseStringList(json['triviaOptions']);
    final minAboutMeLength = parseNullableInt(
      config['minAboutMeLength'] ?? json['minAboutMeLength'],
    );

    return SpinMission(
      id: parseString(json['id']),
      type: parsedType,
      title: parseString(json['title']),
      description: parseString(json['description']),
      reward: parseInt(json['rewardTickets'] ?? json['reward']),
      targetCount: parseInt(json['targetCount'], fallback: 1),
      maxCompletionsPerUser: parseInt(
        json['maxCompletionsPerUser'],
        fallback: 1,
      ),
      done: parseBool(json['done']),
      completions: parseInt(json['completions']),
      actionLabel: parseNullableString(json['actionLabel']),
      active: parseBool(json['active'], fallback: true),
      order: parseInt(json['order']),
      startsAt: parseDateTime(json['startsAt']),
      endsAt: parseDateTime(json['endsAt']),
      triviaQuestion: triviaQuestion,
      triviaOptions: triviaOptions,
      minAboutMeLength: minAboutMeLength,
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'title': title,
    'description': description,
    'rewardTickets': reward,
    'targetCount': targetCount,
    'maxCompletionsPerUser': maxCompletionsPerUser,
    'done': done,
    'completions': completions,
    'actionLabel': actionLabel,
    'active': active,
    'order': order,
    'startsAt': toIsoStringOrNull(startsAt),
    'endsAt': toIsoStringOrNull(endsAt),
    'config': {
      if (triviaQuestion != null) 'question': triviaQuestion,
      if (triviaOptions.isNotEmpty) 'options': triviaOptions,
      if (minAboutMeLength != null) 'minAboutMeLength': minAboutMeLength,
    },
    'updatedAt': toIsoStringOrNull(updatedAt),
  };
}
