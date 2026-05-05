import 'package:app_events/domain/models/speed_run_challenge.dart';

abstract class SpeedRunRepository {
  Future<List<SpeedRunChallenge>> getChallenges();
  Future<void> addChallenge(SpeedRunChallenge challenge, {String? imagePath});
}
