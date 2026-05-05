import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:app_events/domain/repositories/speed_run_repository.dart';
import 'package:flutter/foundation.dart';

class SpeedRunProvider with ChangeNotifier {
  final SpeedRunRepository _repository;
  SpeedRunProvider(this._repository);

  List<SpeedRunChallenge> _challenges = [];
  bool _loading = false;

  List<SpeedRunChallenge> get challenges => _challenges;
  bool get loading => _loading;

  Future<void> loadChallenges() async {
    _loading = true;
    notifyListeners();
    try {
      _challenges = await _repository.getChallenges();
    } catch (_) {
      _challenges = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addChallenge(
    SpeedRunChallenge challenge, {
    String? imagePath,
  }) async {
    await _repository.addChallenge(challenge, imagePath: imagePath);
    await loadChallenges();
  }
}
