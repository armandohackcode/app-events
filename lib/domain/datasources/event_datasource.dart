import 'package:app_events/domain/models/event.dart';

abstract class EventDatasource {
  /// Retrieves all events
  Future<List<Event>> getEvents();

  /// Listens for real-time changes in the events list
  Stream<List<Event>> getEventsStream();

  /// Creates a new event. If [imagePath] is provided, uploads to Firebase Storage first.
  Future<void> addEvent(Event event, {String? imagePath});

  /// Updates an existing event's data. If [imagePath] is provided, replaces the image in Firebase Storage.
  Future<void> updateEvent(Event event, {String? imagePath});

  /// Updates the status of an existing event
  Future<void> updateEventStatus(String eventId, EventStatus status);
}
