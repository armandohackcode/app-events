import 'dart:convert';

ResourceLibrary resourceLibraryFromJson(String str) =>
    ResourceLibrary.fromJson(json.decode(str));

String resourceLibraryToJson(ResourceLibrary data) =>
    json.encode(data.toJson());

class ResourceLibrary {
  String title;
  String link;
  List<String> keywords;
  String type;

  ResourceLibrary({
    required this.title,
    required this.link,
    required this.type,
    this.keywords = const [],
  });

  ResourceLibrary copyWith({String? title, String? link, String? type}) =>
      ResourceLibrary(
        title: title ?? this.title,
        link: link ?? this.link,
        type: type ?? this.type,
        keywords: keywords,
      );

  factory ResourceLibrary.fromJson(Map<String, dynamic> json) =>
      ResourceLibrary(
        title: json["title"],
        link: json["link"],
        type: json["type"],
        keywords: json["keywords"] == null
            ? []
            : List<String>.from(json["keywords"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
    "title": title,
    "link": link,
    "type": type,
    "keywords": List<dynamic>.from(keywords.map((x) => x)),
  };
}
