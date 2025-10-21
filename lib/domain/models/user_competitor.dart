import 'dart:convert';

import 'package:app_events/domain/models/speaker.dart';

UserCompetitor userCompetitorFromJson(String str) =>
    UserCompetitor.fromJson(json.decode(str));

String userCompetitorToJson(UserCompetitor data) => json.encode(data.toJson());

class UserCompetitor {
  String uuid;
  String photoUrl;
  String name;
  String profession;
  String aboutMe;
  String tokenAuthorization;
  int score;
  bool scoreProfile;
  List<SocialNetwork> socialNetwork;
  List<Friend> friends;

  UserCompetitor({
    required this.uuid,
    required this.name,
    required this.photoUrl,
    required this.profession,
    required this.aboutMe,
    required this.tokenAuthorization,
    required this.score,
    this.scoreProfile = false,
    required this.socialNetwork,
    required this.friends,
  });

  UserCompetitor copyWith({
    String? uuid,
    String? name,
    String? photoUrl,
    String? profession,
    String? aboutMe,
    String? tokenAuthorization,
    int? score,
    bool? scoreProfile,
    List<SocialNetwork>? socialNetwork,
    List<Friend>? friends,
  }) =>
      UserCompetitor(
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        profession: profession ?? this.profession,
        aboutMe: aboutMe ?? this.aboutMe,
        tokenAuthorization: tokenAuthorization ?? this.tokenAuthorization,
        score: score ?? this.score,
        scoreProfile: scoreProfile ?? this.scoreProfile,
        socialNetwork: socialNetwork ?? this.socialNetwork,
        friends: friends ?? this.friends,
      );

  factory UserCompetitor.fromJson(Map<String, dynamic> json) => UserCompetitor(
        uuid: json["uuid"],
        name: json["name"],
        photoUrl: json["photoUrl"] ?? "",
        profession: json["profession"] ?? "",
        aboutMe: json["aboutMe"] ?? "",
        tokenAuthorization: json["tokenAuthorization"] ?? "",
        score: json["score"] ?? 0,
        scoreProfile: json["scoreProfile"] ?? false,
        socialNetwork: (json["socialNetwork"] == null)
            ? []
            : List<SocialNetwork>.from(
                json["socialNetwork"].map((x) => SocialNetwork.fromJson(x))),
        friends: (json["friends"] == null)
            ? []
            : List<Friend>.from(json["friends"].map((x) => Friend.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "name": name,
        "photoUrl": photoUrl,
        "profession": profession,
        "aboutMe": aboutMe,
        "tokenAuthorization": tokenAuthorization,
        "score": score,
        "scoreProfile": scoreProfile,
        "socialNetwork":
            List<dynamic>.from(socialNetwork.map((x) => x.toJson())),
        "friends": List<dynamic>.from(friends.map((x) => x.toJson())),
      };
}

class Friend {
  String uuid;
  String name;
  String token;
  String photoUrl;

  Friend({
    required this.uuid,
    required this.name,
    required this.token,
    required this.photoUrl,
  });

  Friend copyWith({
    String? uuid,
    String? name,
    String? token,
    String? photoUrl,
  }) =>
      Friend(
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        token: token ?? this.token,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        uuid: json["uuid"],
        name: json["name"],
        token: json["token"] ?? "",
        photoUrl: json["photoUrl"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "name": name,
        "token": token,
        "photoUrl": photoUrl,
      };
}
