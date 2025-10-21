import 'dart:convert';

List<Organizer> sponsorFromJson(String str) =>
    List<Organizer>.from(json.decode(str).map((x) => Organizer.fromJson(x)));

String sponsorToJson(List<Organizer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Organizer {
  String name;
  int type;
  String photoUrl;
  String link;

  Organizer({
    required this.type,
    required this.name,
    required this.photoUrl,
    required this.link,
  });

  Organizer copyWith({
    int? type,
    String? name,
    String? photoUrl,
    String? link,
  }) =>
      Organizer(
        type: type ?? this.type,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        link: link ?? this.link,
      );

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
        type: json["type"],
        name: json["name"],
        photoUrl: json["photoUrl"],
        link: json["link"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "name": name,
        "photoUrl": photoUrl,
        "link": link,
      };
}
