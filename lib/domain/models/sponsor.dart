import 'dart:convert';

List<Sponsor> sponsorFromJson(String str) =>
    List<Sponsor>.from(json.decode(str).map((x) => Sponsor.fromJson(x)));

String sponsorToJson(List<Sponsor> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Sponsor {
  String? id;
  String name;
  String photoUrl;
  String link;

  Sponsor({
    this.id,
    required this.name,
    required this.photoUrl,
    required this.link,
  });

  Sponsor copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? link,
  }) =>
      Sponsor(
        id: id ?? this.id,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        link: link ?? this.link,
      );

  factory Sponsor.fromJson(Map<String, dynamic> json) => Sponsor(
        id: json["id"],
        name: json["name"],
        photoUrl: json["photoUrl"],
        link: json["link"],
      );

  Map<String, dynamic> toJson() => {
        "id" : id,
        "name": name,
        "photoUrl": photoUrl,
        "link": link,
      };
}
