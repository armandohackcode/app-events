import 'dart:convert';

List<Organizer> organizerFromJson(String str) =>
    List<Organizer>.from(json.decode(str).map((x) => Organizer.fromJson(x)));

String organizerToJson(List<Organizer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Organizer {
  String? id;
  String name;
  int type;
  String photoUrl;
  String link;
  List<String> team;

  Organizer({
    this.id,
    required this.type,
    required this.name,
    required this.photoUrl,
    required this.link,
    required this.team,
  });

  Organizer copyWith({
    required String? id,
    int? type,
    String? name,
    String? photoUrl,
    String? link,
    List<String>? team,
  }) => Organizer(
    id: id,
    type: type ?? this.type,
    name: name ?? this.name,
    photoUrl: photoUrl ?? this.photoUrl,
    link: link ?? this.link,
    team: team ?? this.team,
  );

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
    id: json["id"],
    type: json["type"],
    name: json["name"],
    photoUrl: json["photoUrl"],
    link: json["link"] ?? "",
    team: List<String>.from(json["team"] ?? []),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "name": name,
    "photoUrl": photoUrl,
    "link": link,
    "team": team,
  };
}
