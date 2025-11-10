import 'dart:convert';

List<TreasureHuntModel> treasureHuntModelFromJson(String str) =>
    List<TreasureHuntModel>.from(
      json.decode(str).map((x) => TreasureHuntModel.fromJson(x)),
    );

String treasureHuntModelToJson(List<TreasureHuntModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TreasureHuntModel {
  String uuid;
  String title;
  String imgPath;
  String question;
  String answer;
  String description;

  TreasureHuntModel({
    required this.uuid,
    required this.title,
    required this.imgPath,
    required this.question,
    required this.answer,
    required this.description,
  });

  TreasureHuntModel copyWith({
    String? uuid,
    String? title,
    String? imgPath,
    String? question,
    String? answer,
    String? description,
  }) => TreasureHuntModel(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    imgPath: imgPath ?? this.imgPath,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    description: description ?? this.description,
  );

  factory TreasureHuntModel.fromJson(Map<String, dynamic> json) =>
      TreasureHuntModel(
        uuid: json["uuid"],
        title: json["title"],
        imgPath: json["imgPath"],
        question: json["question"],
        answer: json["answer"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
    "uuid": uuid,
    "title": title,
    "imgPath": imgPath,
    "question": question,
    "answer": answer,
    "description": description,
  };
}
