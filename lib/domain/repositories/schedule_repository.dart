import 'package:app_events/domain/models/speaker.dart';

abstract class ScheduleRepository {
  /// Adds a new item to the schedule
  Future<void> addNewSchedule(Speaker speaker);

  /// Listens for changes in the schedule
  Stream<List<Speaker>> getListScheduleStream();

  /// Retrieves all schedule data
  Future<List<Speaker>> getListSchedule();

  /// Listens for changes within a specific speaker
  Stream<Speaker?> speakerStream(String uuid);
}
