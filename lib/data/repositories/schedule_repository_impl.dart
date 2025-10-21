import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleDatasource _db;

  ScheduleRepositoryImpl(this._db);
  @override
  Future<void> addNewSchedule(Speaker speaker) {
    return _db.addNewSchedule(speaker);
  }

  @override
  Future<List<Speaker>> getListSchedule() {
    return _db.getListSchedule();
  }

  @override
  Stream<List<Speaker>> getListScheduleStream() async* {
    yield* _db.getListScheduleStream();
  }

  @override
  Stream<Speaker?> speakerStream(String uuid) async* {
    yield* _db.speakerStream(uuid);
  }
}
