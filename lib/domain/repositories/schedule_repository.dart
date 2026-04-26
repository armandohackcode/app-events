import 'package:app_events/domain/models/speaker.dart';

abstract class ScheduleRepository {
  /// Adds a new item to the schedule of the given event.
  /// If [imagePath] is provided, uploads to Firebase Storage first.
  Future<void> addNewSchedule(String eventId, Speaker speaker, {String? imagePath});

  /// Listens for real-time changes in the schedule of the given event
  Stream<List<Speaker>> getListScheduleStream(String eventId);

  /// Retrieves all schedule entries for the given event
  Future<List<Speaker>> getListSchedule(String eventId);

  /// Listens for changes in a specific speaker within the given event
  Stream<Speaker?> speakerStream(String eventId, String speakerUuid);
}
