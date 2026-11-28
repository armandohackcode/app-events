import 'package:app_events/domain/models/spin_json_helpers.dart';

/// Attendee question submitted to a speaker talk.
class TalkQuestion {
  final String id;
  final String uid;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final bool answered;
  final bool hidden;
  final DateTime? createdAt;

  const TalkQuestion({
    required this.id,
    required this.uid,
    required this.text,
    this.authorName = '',
    this.authorPhotoUrl = '',
    this.answered = false,
    this.hidden = false,
    this.createdAt,
  });

  TalkQuestion copyWith({
    String? id,
    String? uid,
    String? authorName,
    String? authorPhotoUrl,
    String? text,
    bool? answered,
    bool? hidden,
    DateTime? createdAt,
    bool clearCreatedAt = false,
  }) => TalkQuestion(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    authorName: authorName ?? this.authorName,
    authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
    text: text ?? this.text,
    answered: answered ?? this.answered,
    hidden: hidden ?? this.hidden,
    createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
  );

  factory TalkQuestion.fromJson(Map<String, dynamic> json) => TalkQuestion(
    id: parseString(json['id']),
    uid: parseString(json['uid']),
    authorName: parseString(json['authorName']),
    authorPhotoUrl: parseString(json['authorPhotoUrl']),
    text: parseString(json['text']),
    answered: parseBool(json['answered']),
    hidden: parseBool(json['hidden']),
    createdAt: parseDateTime(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'text': text,
    'answered': answered,
    'hidden': hidden,
    'createdAt': toIsoStringOrNull(createdAt),
  };
}

/// Result returned by `spinSubmitTalkQuestion`.
class TalkQuestionSubmitResult {
  final String questionId;
  final bool missionRewarded;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String? ticketSerial;

  const TalkQuestionSubmitResult({
    this.questionId = '',
    this.missionRewarded = false,
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial,
  });

  factory TalkQuestionSubmitResult.fromJson(Map<String, dynamic> json) =>
      TalkQuestionSubmitResult(
        questionId: parseString(json['questionId']),
        missionRewarded: parseBool(json['missionRewarded']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseNullableString(json['ticketSerial']),
      );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'missionRewarded': missionRewarded,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
  };
}
