import 'dart:convert';

EventBadge eventBadgeFromJson(String str) =>
    EventBadge.fromJson(json.decode(str));

String eventBadgeToJson(EventBadge data) => json.encode(data.toJson());

class EventBadge {
  String eventId;
  String eventName;
  DateTime eventDate;
  int finalScore;
  int rank;
  String assetPath;

  EventBadge({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.finalScore,
    required this.rank,
    required this.assetPath,
  });

  EventBadge copyWith({
    String? eventId,
    String? eventName,
    DateTime? eventDate,
    int? finalScore,
    int? rank,
    String? assetPath,
  }) => EventBadge(
    eventId: eventId ?? this.eventId,
    eventName: eventName ?? this.eventName,
    eventDate: eventDate ?? this.eventDate,
    finalScore: finalScore ?? this.finalScore,
    rank: rank ?? this.rank,
    assetPath: assetPath ?? this.assetPath,
  );

  factory EventBadge.fromJson(Map<String, dynamic> json) => EventBadge(
    eventId: json["eventId"] ?? "",
    eventName: json["eventName"] ?? "",
    eventDate: DateTime.parse(json["eventDate"]),
    finalScore: json["finalScore"] ?? 0,
    rank: json["rank"] ?? 0,
    assetPath: json["assetPath"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "eventId": eventId,
    "eventName": eventName,
    "eventDate": eventDate.toIso8601String(),
    "finalScore": finalScore,
    "rank": rank,
    "assetPath": assetPath,
  };
}
