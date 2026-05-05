import 'package:app_events/domain/datasources/speed_run_datasource.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:app_events/domain/repositories/speed_run_repository.dart';

class SpeedRunRepositoryImpl implements SpeedRunRepository {
  final SpeedRunDatasource _db;
  SpeedRunRepositoryImpl(this._db);

  @override
  Future<List<SpeedRunChallenge>> getChallenges() => _db.getChallenges();

  @override
  Future<void> addChallenge(SpeedRunChallenge challenge, {String? imagePath}) =>
      _db.addChallenge(challenge, imagePath: imagePath);
}
