// To parse this JSON data, do
//
//     final sponsor = sponsorFromJson(jsonString);

import 'dart:convert';

List<Organizer> sponsorFromJson(String str) =>
    List<Organizer>.from(json.decode(str).map((x) => Organizer.fromJson(x)));

String sponsorToJson(List<Organizer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Organizer {
  String name;
  String photoUrl;
  String link;

  Organizer({
    required this.name,
    required this.photoUrl,
    required this.link,
  });

  Organizer copyWith({
    String? name,
    String? photoUrl,
    String? link,
  }) =>
      Organizer(
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        link: link ?? this.link,
      );

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
        name: json["name"],
        photoUrl: json["photoUrl"],
        link: json["link"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "photoUrl": photoUrl,
        "link": link,
      };
}
