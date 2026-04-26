import 'dart:convert';

Event eventFromJson(String str) => Event.fromJson(json.decode(str));

String eventToJson(Event data) => json.encode(data.toJson());

class Event {
  String id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  String locationUrl;
  String imageUrl;
  EventStatus status;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.locationUrl,
    required this.imageUrl,
    required this.status,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? locationUrl,
    String? imageUrl,
    EventStatus? status,
  }) => Event(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    locationUrl: locationUrl ?? this.locationUrl,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
  );

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    locationUrl: json["locationUrl"] ?? "",
    imageUrl: json["imageUrl"] ?? "",
    status: EventStatus.fromValue(json["status"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "locationUrl": locationUrl,
    "imageUrl": imageUrl,
    "status": status.value,
  };
}

enum EventStatus {
  upcoming,
  active,
  finished;

  static const Map<EventStatus, String> _values = {
    EventStatus.upcoming: 'upcoming',
    EventStatus.active: 'active',
    EventStatus.finished: 'finished',
  };

  static final Map<String, EventStatus> _fromString = {
    for (var e in _values.entries) e.value: e.key,
  };

  String get value => _values[this] ?? 'upcoming';

  static EventStatus fromValue(String? text) =>
      _fromString[text ?? ''] ?? EventStatus.upcoming;
}
