import 'dart:convert';

List<Organizer> sponsorFromJson(String str) =>
    List<Organizer>.from(json.decode(str).map((x) => Organizer.fromJson(x)));

String sponsorToJson(List<Organizer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Organizer {
  int id;
  String name;
  int type;
  String photoUrl;
  String link;
  List<String> team;
  bool lead;

  Organizer({
    required this.id,
    required this.type,
    required this.name,
    required this.photoUrl,
    required this.link,
    required this.team,
    required this.lead,
  });

  Organizer copyWith({
    required int id,
    int? type,
    String? name,
    String? photoUrl,
    String? link,
    List<String>? team,
    bool? lead,
  }) => Organizer(
    id: id,
    type: type ?? this.type,
    name: name ?? this.name,
    photoUrl: photoUrl ?? this.photoUrl,
    link: link ?? this.link,
    team: team ?? this.team,
    lead: lead ?? this.lead,
  );

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
        id: json["id"],
        type: json["type"],
        name: json["name"],
        photoUrl: json["photoUrl"],
        link: json["link"] ?? "",
        team: List<String>.from(json["team"] ?? []),
        lead: json["lead"] ?? false,
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "name": name,
    "photoUrl": photoUrl,
    "link": link,
    "team": team,
    "lead": lead,
  };
}
