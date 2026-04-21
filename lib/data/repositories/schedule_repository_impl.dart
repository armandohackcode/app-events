import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleDatasource _db;
  ScheduleRepositoryImpl(this._db);

  @override
  Future<void> addNewSchedule(String eventId, Speaker speaker, {String? imagePath}) =>
      _db.addNewSchedule(eventId, speaker, imagePath: imagePath);

  @override
  Future<List<Speaker>> getListSchedule(String eventId) =>
      _db.getListSchedule(eventId);

  @override
  Stream<List<Speaker>> getListScheduleStream(String eventId) =>
      _db.getListScheduleStream(eventId);

  @override
  Stream<Speaker?> speakerStream(String eventId, String speakerUuid) =>
      _db.speakerStream(eventId, speakerUuid);
}
