import 'package:app_events/domain/models/spin_json_helpers.dart';

/// Attendee star rating (1..5) and optional feedback for a talk.
class TalkRating {
  final String uid;
  final int stars;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TalkRating({
    required this.uid,
    required this.stars,
    this.comment = '',
    this.createdAt,
    this.updatedAt,
  });

  TalkRating copyWith({
    String? uid,
    int? stars,
    String? comment,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) => TalkRating(
    uid: uid ?? this.uid,
    stars: stars ?? this.stars,
    comment: comment ?? this.comment,
    createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
  );

  factory TalkRating.fromJson(Map<String, dynamic> json) => TalkRating(
    uid: parseString(json['uid']),
    stars: parseInt(json['stars']),
    comment: parseString(json['comment']),
    createdAt: parseDateTime(json['createdAt']),
    updatedAt: parseDateTime(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'stars': stars,
    'comment': comment,
    'createdAt': toIsoStringOrNull(createdAt),
    'updatedAt': toIsoStringOrNull(updatedAt),
  };
}

/// Result returned by `spinSubmitTalkRating`.
class TalkRatingSubmitResult {
  final bool saved;
  final bool missionRewarded;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String? ticketSerial;

  const TalkRatingSubmitResult({
    this.saved = false,
    this.missionRewarded = false,
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial,
  });

  factory TalkRatingSubmitResult.fromJson(Map<String, dynamic> json) =>
      TalkRatingSubmitResult(
        saved: parseBool(json['saved']),
        missionRewarded: parseBool(json['missionRewarded']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseNullableString(json['ticketSerial']),
      );

  Map<String, dynamic> toJson() => {
    'saved': saved,
    'missionRewarded': missionRewarded,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
  };
}
