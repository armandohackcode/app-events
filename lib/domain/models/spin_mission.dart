/// Mission that grants spin tickets when completed.
class SpinMission {
  final String id;
  final String title;
  final int reward;
  final bool done;
  final String? actionLabel;
  final bool isTrivia;

  const SpinMission({
    required this.id,
    required this.title,
    required this.reward,
    required this.done,
    this.actionLabel,
    this.isTrivia = false,
  });

  SpinMission copyWith({
    String? id,
    String? title,
    int? reward,
    bool? done,
    String? actionLabel,
    bool? isTrivia,
  }) => SpinMission(
    id: id ?? this.id,
    title: title ?? this.title,
    reward: reward ?? this.reward,
    done: done ?? this.done,
    actionLabel: actionLabel ?? this.actionLabel,
    isTrivia: isTrivia ?? this.isTrivia,
  );

  factory SpinMission.fromJson(Map<String, dynamic> json) => SpinMission(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    reward: (json['reward'] as num?)?.toInt() ?? 0,
    done: json['done'] as bool? ?? false,
    actionLabel: json['actionLabel'] as String?,
    isTrivia: json['isTrivia'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'reward': reward,
    'done': done,
    'actionLabel': actionLabel,
    'isTrivia': isTrivia,
  };
}
