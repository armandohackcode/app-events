// To parse this JSON data, do
//
//     final sponsor = sponsorFromJson(jsonString);

import 'dart:convert';

List<Sponsor> sponsorFromJson(String str) =>
    List<Sponsor>.from(json.decode(str).map((x) => Sponsor.fromJson(x)));

String sponsorToJson(List<Sponsor> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Sponsor {
  String name;
  String photoUrl;
  String link;

  Sponsor({
    required this.name,
    required this.photoUrl,
    required this.link,
  });

  Sponsor copyWith({
    String? name,
    String? photoUrl,
    String? link,
  }) =>
      Sponsor(
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        link: link ?? this.link,
      );

  factory Sponsor.fromJson(Map<String, dynamic> json) => Sponsor(
        name: json["name"],
        photoUrl: json["photoUrl"],
        link: json["link"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "photoUrl": photoUrl,
        "link": link,
      };
}
