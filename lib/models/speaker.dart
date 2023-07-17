// To parse this JSON data, do
//
//     final speaker = speakerFromJson(jsonString);

import 'dart:convert';

Speaker speakerFromJson(String str) => Speaker.fromJson(json.decode(str));

String speakerToJson(Speaker data) => json.encode(data.toJson());

class Speaker {
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
  List<SocialNetwork> socialNetwork;

  Speaker({
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
  });

  Speaker copyWith({
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
    int? position,
    List<SocialNetwork>? socialNetwork,
  }) =>
      Speaker(
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
        socialNetwork: socialNetwork ?? this.socialNetwork,
      );

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
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
        socialNetwork: List<SocialNetwork>.from(
            json["SocialNetwork"].map((x) => SocialNetwork.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
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
        "SocialNetwork":
            List<dynamic>.from(socialNetwork.map((x) => x.toJson())),
      };
}

class SocialNetwork {
  String type;
  String link;

  SocialNetwork({
    required this.type,
    required this.link,
  });

  SocialNetwork copyWith({
    String? type,
    String? link,
  }) =>
      SocialNetwork(
        type: type ?? this.type,
        link: link ?? this.link,
      );

  factory SocialNetwork.fromJson(Map<String, dynamic> json) => SocialNetwork(
        type: json["type"] ?? "",
        link: json["link"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "link": link,
      };
}
