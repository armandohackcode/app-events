import 'dart:convert';

Speaker speakerFromJson(String str) => Speaker.fromJson(json.decode(str));

String speakerToJson(Speaker data) => json.encode(data.toJson());

class Speaker {
  String uuid;
  String title;
  String description;
  String name;
  String profession;
  String aboutMe;
  String photoUrl;
  String technologyType;
  String type;
  String color;
  String schedule;
  int position;
  int current;
  int limit;
  String? openDate;
  List<SocialNetwork> socialNetwork;

  Speaker({
    required this.uuid,
    required this.title,
    required this.description,
    required this.name,
    required this.profession,
    required this.aboutMe,
    required this.photoUrl,
    required this.technologyType,
    required this.type,
    required this.color,
    required this.schedule,
    required this.position,
    required this.socialNetwork,
    this.openDate,
    this.current = 0,
    this.limit = 0,
  });

  Speaker copyWith({
    String? uuid,
    String? title,
    String? description,
    String? name,
    String? profession,
    String? aboutMe,
    String? photoUrl,
    String? technologyType,
    String? type,
    String? color,
    String? schedule,
    int? limit,
    int? current,
    int? position,
    String? openDate,
    List<SocialNetwork>? socialNetwork,
  }) => Speaker(
    limit: limit ?? this.limit,
    current: current ?? this.current,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description ?? this.description,
    name: name ?? this.name,
    profession: profession ?? this.profession,
    aboutMe: aboutMe ?? this.aboutMe,
    photoUrl: photoUrl ?? this.photoUrl,
    technologyType: technologyType ?? this.technologyType,
    type: type ?? this.type,
    color: color ?? this.color,
    schedule: schedule ?? this.schedule,
    position: position ?? this.position,
    openDate: openDate ?? this.openDate,
    socialNetwork: socialNetwork ?? this.socialNetwork,
  );

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
    limit: json["limit"] ?? 0,
    current: json["current"] ?? 0,
    uuid: json["uuid"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    name: json["name"] ?? "",
    profession: json["profession"] ?? "",
    aboutMe: json["aboutMe"] ?? "",
    photoUrl: json["photoUrl"] ?? "",
    technologyType: json["technologyType"] ?? "",
    type: json["type"] ?? "",
    color: json["color"] ?? "",
    schedule: json["schedule"] ?? "",
    position: json["position"] ?? 0,
    openDate: json["openDate"] ?? "",
    socialNetwork: List<SocialNetwork>.from(
      json["SocialNetwork"].map((x) => SocialNetwork.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "limit": limit,
    "current": current,
    "title": title,
    "description": description,
    "name": name,
    "profession": profession,
    "aboutMe": aboutMe,
    "photoUrl": photoUrl,
    "technologyType": technologyType,
    "type": type,
    "color": color,
    "schedule": schedule,
    "position": position,
    "openDate": openDate,
    "SocialNetwork": List<dynamic>.from(socialNetwork.map((x) => x.toJson())),
  };
}

class SocialNetwork {
  String type;
  String link;

  SocialNetwork({required this.type, required this.link});

  SocialNetwork copyWith({String? type, String? link}) =>
      SocialNetwork(type: type ?? this.type, link: link ?? this.link);

  factory SocialNetwork.fromJson(Map<String, dynamic> json) =>
      SocialNetwork(type: json["type"] ?? "", link: json["link"] ?? "");

  Map<String, dynamic> toJson() => {"type": type, "link": link};
}

enum EventTypeSpeaker {
  conference,
  workshop,
  panel,
  unknown;

  static const Map<EventTypeSpeaker, String> _fromValue = {
    EventTypeSpeaker.conference: 'conference',
    EventTypeSpeaker.workshop: 'workshop',
    EventTypeSpeaker.panel: 'panel',
    EventTypeSpeaker.unknown: 'unknown',
  };

  static final Map<String, EventTypeSpeaker> _toString = {
    for (var entry in _fromValue.entries) entry.value: entry.key,
  };

  String get value => _fromValue[this] ?? 'unknown';

  static EventTypeSpeaker fromValue(String? text) =>
      _toString[text?.toLowerCase() ?? ''] ?? EventTypeSpeaker.unknown;
}
