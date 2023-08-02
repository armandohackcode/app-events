// To parse this JSON data, do
//
//     final resourceLibrary = resourceLibraryFromJson(jsonString);

import 'dart:convert';

ResourceLibrary resourceLibraryFromJson(String str) =>
    ResourceLibrary.fromJson(json.decode(str));

String resourceLibraryToJson(ResourceLibrary data) =>
    json.encode(data.toJson());

class ResourceLibrary {
  String title;
  String link;
  String type;

  ResourceLibrary({
    required this.title,
    required this.link,
    required this.type,
  });

  ResourceLibrary copyWith({
    String? title,
    String? link,
    String? type,
  }) =>
      ResourceLibrary(
        title: title ?? this.title,
        link: link ?? this.link,
        type: type ?? this.type,
      );

  factory ResourceLibrary.fromJson(Map<String, dynamic> json) =>
      ResourceLibrary(
        title: json["title"],
        link: json["link"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "link": link,
        "type": type,
      };
}
