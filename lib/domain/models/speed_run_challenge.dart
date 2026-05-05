class SpeedRunChallenge {
  final String id;
  final String imageUrl;
  final String title;
  final String challenge;
  final ChallengeState state;
  final int position;

  const SpeedRunChallenge({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.challenge,
    required this.state,
    required this.position,
  });

  SpeedRunChallenge copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? challenge,
    ChallengeState? state,
    int? position,
  }) => SpeedRunChallenge(
    id: id ?? this.id,
    imageUrl: imageUrl ?? this.imageUrl,
    title: title ?? this.title,
    challenge: challenge ?? this.challenge,
    state: state ?? this.state,
    position: position ?? this.position,
  );

  factory SpeedRunChallenge.fromJson(Map<String, dynamic> json) =>
      SpeedRunChallenge(
        id: json['id'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        title: json['title'] ?? '',
        challenge: json['challenge'] ?? '',
        state: ChallengeState.fromValue(json['state']),
        position: json['position'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'title': title,
    'challenge': challenge,
    'state': state.value,
    'position': position,
  };
}

enum ChallengeState {
  active,
  inactive;

  static const Map<ChallengeState, String> _values = {
    ChallengeState.active: 'active',
    ChallengeState.inactive: 'inactive',
  };

  static final Map<String, ChallengeState> _fromString = {
    for (final e in _values.entries) e.value: e.key,
  };

  String get value => _values[this] ?? 'inactive';

  static ChallengeState fromValue(String? text) =>
      _fromString[text ?? ''] ?? ChallengeState.inactive;
}
